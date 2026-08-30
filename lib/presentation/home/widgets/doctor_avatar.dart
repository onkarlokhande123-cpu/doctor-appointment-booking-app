import 'package:flutter/material.dart';

class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 30,
  });

  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      child: Icon(Icons.person_outline, size: radius),
    );
    if (imageUrl == null || imageUrl!.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
