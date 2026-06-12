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
        createdAt,
      ];
}
