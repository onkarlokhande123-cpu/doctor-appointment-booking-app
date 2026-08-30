import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:appointment_booking_app/core/constants/enums.dart';
import 'package:appointment_booking_app/data/models/user_model.dart';
import 'package:appointment_booking_app/data/repositories/auth_repository.dart';

/// Firebase-backed authentication and user-profile repository.
///
/// Firebase Authentication owns credentials and session state. Firestore owns
/// the app-specific profile at `users/{uid}`.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _usersCollection = 'users';
  static const String _defaultRole = 'patient';

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_usersCollection);

  @override
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream<UserModel?>.value(null);

      return _users.doc(firebaseUser.uid).snapshots().transform(
            StreamTransformer<DocumentSnapshot<Map<String, dynamic>>,
                UserModel?>.fromHandlers(
              handleData: (snapshot, sink) {
                sink.add(_profileFromSnapshot(snapshot, firebaseUser));
              },
              handleError: (_, __, sink) {
                // Keep an authenticated Firebase user signed in if a profile read
                // fails; public operations still expose friendly Firestore errors.
                sink.add(_fallbackProfile(firebaseUser));
              },
            ),
          );
    });
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      return await _loadProfile(firebaseUser, createIfMissing: true);
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthRepositoryException('Unable to create the account.');
      }

      await firebaseUser.updateDisplayName(name.trim());
      final profile = UserModel(
        id: firebaseUser.uid,
        name: name.trim(),
        email: firebaseUser.email ?? email.trim(),
        phone: phone.trim(),
        profileImageUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        role: UserRole.patient,
      );
      await _users.doc(firebaseUser.uid).set(_profileData(profile));
      return profile;
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapFirebaseAuthError(error));
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(
        'Your account was created, but we could not save the profile. '
        '${_mapFirestoreError(error)}',
      );
    }
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const AuthRepositoryException('Unable to sign in.');
      }
      return await _loadProfile(firebaseUser, createIfMissing: true);
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapFirebaseAuthError(error));
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(_mapFirestoreError(error));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapFirebaseAuthError(error));
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapFirebaseAuthError(error));
    }
  }

  @override
  Future<UserModel> updateProfile(UserModel updatedUser) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      throw const AuthRepositoryException(
        'You must be signed in to edit your profile.',
      );
    }
    if (firebaseUser.uid != updatedUser.id) {
      throw const AuthRepositoryException(
          'You cannot edit another user profile.');
    }

    try {
      await firebaseUser.updateDisplayName(updatedUser.name.trim());
      await firebaseUser.updatePhotoURL(updatedUser.profileImageUrl);

      final existingProfile = await _loadProfile(
        firebaseUser,
        createIfMissing: true,
      );
      final synchronizedProfile = UserModel(
        id: firebaseUser.uid,
        name: updatedUser.name.trim(),
        email: firebaseUser.email ?? updatedUser.email.trim(),
        phone: updatedUser.phone.trim(),
        profileImageUrl: updatedUser.profileImageUrl,
        createdAt: existingProfile.createdAt,
        role: existingProfile.role,
        doctorId: existingProfile.doctorId,
      );
      await _users.doc(firebaseUser.uid).set(
            _profileUpdateData(synchronizedProfile),
            SetOptions(merge: true),
          );
      return synchronizedProfile;
    } on FirebaseAuthException catch (error) {
      throw AuthRepositoryException(_mapFirebaseAuthError(error));
    } on FirebaseException catch (error) {
      throw AuthRepositoryException(_mapFirestoreError(error));
    }
  }

  Future<UserModel> _loadProfile(
    User firebaseUser, {
    required bool createIfMissing,
  }) async {
    final reference = _users.doc(firebaseUser.uid);
    final snapshot = await reference.get();
    if (snapshot.exists) return _profileFromSnapshot(snapshot, firebaseUser);

    final fallback = _fallbackProfile(firebaseUser);
    if (createIfMissing) await reference.set(_profileData(fallback));
    return fallback;
  }

  UserModel _profileFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    User firebaseUser,
  ) {
    final data = snapshot.data();
    if (data == null) return _fallbackProfile(firebaseUser);

    final storedName = data['name'] as String?;
    final storedEmail = data['email'] as String?;
    return UserModel(
      id: firebaseUser.uid,
      name: storedName?.trim().isNotEmpty == true
          ? storedName!
          : firebaseUser.displayName ?? '',
      email: storedEmail?.trim().isNotEmpty == true
          ? storedEmail!
          : firebaseUser.email ?? '',
      phone: data['phone'] as String? ?? firebaseUser.phoneNumber ?? '',
      profileImageUrl:
          data['profileImageUrl'] as String? ?? firebaseUser.photoURL,
      createdAt: _dateFromFirestore(data['createdAt']) ??
          firebaseUser.metadata.creationTime ??
          DateTime.now(),
      role: UserRole.fromString(data['role'] as String?),
      doctorId: data['doctorId'] as String?,
    );
  }

  UserModel _fallbackProfile(User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber ?? '',
      profileImageUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      role: UserRole.patient,
    );
  }

  Map<String, dynamic> _profileData(UserModel profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'email': profile.email,
      'phone': profile.phone,
      'role': _defaultRole,
      'doctorId': profile.doctorId,
      'profileImageUrl': profile.profileImageUrl,
      'createdAt': Timestamp.fromDate(profile.createdAt),
    };
  }

  /// Preserves ownership fields such as the profile role and creation time.
  Map<String, dynamic> _profileUpdateData(UserModel profile) {
    return {
      'id': profile.id,
      'name': profile.name,
      'email': profile.email,
      'phone': profile.phone,
      'profileImageUrl': profile.profileImageUrl,
    };
  }

  DateTime? _dateFromFirestore(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account was found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'requires-recent-login':
        return 'Please sign in again before updating your profile.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  String _mapFirestoreError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to access this profile.';
      case 'unavailable':
        return 'Service is temporarily unavailable. Please try again.';
      case 'unauthenticated':
        return 'Please sign in again and retry.';
      case 'not-found':
        return 'Your profile could not be found.';
      default:
        return error.message ??
            'Unable to access your profile. Please try again.';
    }
  }
}
