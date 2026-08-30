import 'package:appointment_booking_app/data/models/doctor_model.dart';
import 'package:appointment_booking_app/data/models/specialty_model.dart';

const mockSpecialties = <SpecialtyModel>[
  SpecialtyModel(id: 'cardiology', name: 'Cardiology', iconName: 'heart'),
  SpecialtyModel(id: 'dermatology', name: 'Dermatology', iconName: 'skin'),
  SpecialtyModel(id: 'dentistry', name: 'Dentistry', iconName: 'tooth'),
  SpecialtyModel(id: 'neurology', name: 'Neurology', iconName: 'brain'),
  SpecialtyModel(id: 'pediatrics', name: 'Pediatrics', iconName: 'child'),
];

const mockDoctors = <DoctorModel>[
  DoctorModel(
    id: 'dr-meera-shah',
    name: 'Dr. Meera Shah',
    specialtyId: 'cardiology',
    specialtyName: 'Cardiologist',
    imageUrl: 'https://i.pravatar.cc/300?img=47',
    rating: 4.9,
    experienceYears: 14,
    bio:
        'Dr. Shah provides compassionate preventive and clinical cardiac care, with a focus on helping patients understand each step of their treatment.',
    consultationFee: 800,
    clinicAddress: 'Care Heart Clinic, MG Road',
    availableDays: ['Monday', 'Wednesday', 'Friday'],
  ),
  DoctorModel(
    id: 'dr-arjun-verma',
    name: 'Dr. Arjun Verma',
    specialtyId: 'dermatology',
    specialtyName: 'Dermatologist',
    imageUrl: 'https://i.pravatar.cc/300?img=12',
    rating: 4.8,
    experienceYears: 11,
    bio:
        'Dr. Verma treats common and complex skin conditions and helps patients create practical, sustainable skincare routines.',
    consultationFee: 700,
    clinicAddress: 'Skinwell Centre, Park Street',
    availableDays: ['Tuesday', 'Thursday', 'Saturday'],
  ),
  DoctorModel(
    id: 'dr-kavya-nair',
    name: 'Dr. Kavya Nair',
    specialtyId: 'pediatrics',
    specialtyName: 'Pediatrician',
    imageUrl: 'https://i.pravatar.cc/300?img=45',
    rating: 4.9,
    experienceYears: 9,
    bio:
        'Dr. Nair partners with families to support children from newborn care through adolescence in a calm, reassuring setting.',
    consultationFee: 650,
    clinicAddress: 'Little Steps Clinic, Lake View Road',
    availableDays: ['Monday', 'Tuesday', 'Thursday', 'Saturday'],
  ),
  DoctorModel(
    id: 'dr-rohan-kapoor',
    name: 'Dr. Rohan Kapoor',
    specialtyId: 'dentistry',
    specialtyName: 'Dentist',
    imageUrl: 'https://i.pravatar.cc/300?img=68',
    rating: 4.7,
    experienceYears: 12,
    bio:
        'Dr. Kapoor offers patient-friendly general and restorative dentistry with clear treatment plans and gentle care.',
    consultationFee: 550,
    clinicAddress: 'Bright Smile Dental, Residency Road',
    availableDays: ['Wednesday', 'Friday', 'Saturday'],
  ),
  DoctorModel(
    id: 'dr-isha-sen',
    name: 'Dr. Isha Sen',
    specialtyId: 'neurology',
    specialtyName: 'Neurologist',
    imageUrl: 'https://i.pravatar.cc/300?img=32',
    rating: 4.8,
    experienceYears: 16,
    bio:
        'Dr. Sen evaluates neurological symptoms with a careful, evidence-based approach and explains options in plain language.',
    consultationFee: 950,
    clinicAddress: 'Neurocare Institute, Civil Lines',
    availableDays: ['Tuesday', 'Friday'],
  ),
  DoctorModel(
    id: 'dr-nikhil-rao',
    name: 'Dr. Nikhil Rao',
    specialtyId: 'cardiology',
    specialtyName: 'Cardiologist',
    imageUrl: 'https://i.pravatar.cc/300?img=53',
    rating: 4.5,
    experienceYears: 7,
    bio:
        'Dr. Rao specialises in cardiac risk assessment and lifestyle-focused heart health consultations.',
    consultationFee: 600,
    clinicAddress: 'Wellbeing Medical Centre, East Avenue',
    availableDays: [],
  ),
];
