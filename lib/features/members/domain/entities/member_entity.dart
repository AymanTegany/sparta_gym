import 'package:equatable/equatable.dart';

/// كيان العميل (Member Entity).
/// يمثل البيانات الأساسية للعميل في طبقة الـ Domain.
/// لا يعتمد على أي تفاصيل خارجية (مثل قاعدة البيانات أو API).
class Member extends Equatable {
  final int? id;
  final String memberId;
  final String fullName;
  final String? phoneNumber;
  final String? email;
  final String? gender;
  final String? birthDate;
  final String? address;
  final String? nationalId;
  final String? emergencyContact;
  final String membershipType;
  final double membershipPrice;
  final double discount;
  final double paidAmount;
  final double remainingAmount;
  final String startDate;
  final String endDate;
  final String? trainerName;
  final String? notes;
  final String? memberPhotoPath;
  final int? dietPlanId;
  final String? additionalServicesIds;
  final String createdAt;

  const Member({
    this.id,
    required this.memberId,
    required this.fullName,
    this.phoneNumber,
    this.email,
    this.gender,
    this.birthDate,
    this.address,
    this.nationalId,
    this.emergencyContact,
    required this.membershipType,
    required this.membershipPrice,
    this.discount = 0,
    this.paidAmount = 0,
    this.remainingAmount = 0,
    required this.startDate,
    required this.endDate,
    this.trainerName,
    this.notes,
    this.memberPhotoPath,
    this.dietPlanId,
    this.additionalServicesIds,
    required this.createdAt,
  });

  // ──────────────── Computed Properties ────────────────

  /// هل الاشتراك نشط (لم ينتهِ بعد)
  bool get isActive {
    final end = DateTime.tryParse(endDate);
    if (end == null) return false;
    return end.isAfter(DateTime.now()) || end.isAtSameMomentAs(DateTime.now());
  }

  /// عدد الأيام المتبقية للاشتراك
  int get remainingDays {
    final end = DateTime.tryParse(endDate);
    if (end == null) return 0;
    final diff = end.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// هل الاشتراك ينتهي قريباً (خلال 7 أيام)
  bool get isExpiringSoon {
    return isActive && remainingDays <= 7 && remainingDays > 0;
  }

  /// هل لديه مديونية (مبلغ متبقي أكبر من صفر)
  bool get hasDebt {
    return remainingAmount > 0;
  }

  /// الحالة النصية للاشتراك
  String get statusText {
    if (!isActive) return 'منتهي';
    if (isExpiringSoon) return 'ينتهي قريباً';
    return 'نشط';
  }

  /// المبلغ الصافي بعد الخصم
  double get netPrice => membershipPrice - discount;

  Member copyWith({
    int? id,
    String? memberId,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? gender,
    String? birthDate,
    String? address,
    String? nationalId,
    String? emergencyContact,
    String? membershipType,
    double? membershipPrice,
    double? discount,
    double? paidAmount,
    double? remainingAmount,
    String? startDate,
    String? endDate,
    String? trainerName,
    String? notes,
    String? memberPhotoPath,
    int? dietPlanId,
    String? additionalServicesIds,
    String? createdAt,
  }) {
    return Member(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      nationalId: nationalId ?? this.nationalId,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      membershipType: membershipType ?? this.membershipType,
      membershipPrice: membershipPrice ?? this.membershipPrice,
      discount: discount ?? this.discount,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      trainerName: trainerName ?? this.trainerName,
      notes: notes ?? this.notes,
      memberPhotoPath: memberPhotoPath ?? this.memberPhotoPath,
      dietPlanId: dietPlanId ?? this.dietPlanId,
      additionalServicesIds: additionalServicesIds ?? this.additionalServicesIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        memberId,
        fullName,
        phoneNumber,
        email,
        gender,
        birthDate,
        address,
        nationalId,
        emergencyContact,
        membershipType,
        membershipPrice,
        discount,
        paidAmount,
        remainingAmount,
        startDate,
        endDate,
        trainerName,
        notes,
        memberPhotoPath,
        dietPlanId,
        additionalServicesIds,
        createdAt,
      ];
}
