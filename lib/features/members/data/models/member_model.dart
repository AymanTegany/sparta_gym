import '../../domain/entities/member_entity.dart';

/// نموذج البيانات (Data Model) لجدول members في SQLite.
/// يمتد من Member Entity ويضيف methods للتحويل من/إلى Map.
class MemberModel extends Member {
  const MemberModel({
    super.id,
    required super.memberId,
    required super.fullName,
    super.phoneNumber,
    super.email,
    super.gender,
    super.birthDate,
    super.address,
    super.nationalId,
    super.emergencyContact,
    required super.membershipType,
    required super.membershipPrice,
    super.discount,
    super.paidAmount,
    super.remainingAmount,
    required super.startDate,
    required super.endDate,
    super.trainerName,
    super.notes,
    super.memberPhotoPath,
    super.dietPlanId,
    super.additionalServicesIds,
    required super.createdAt,
  });

  /// تحويل من Map (صف في قاعدة البيانات) إلى MemberModel
  factory MemberModel.fromMap(Map<String, dynamic> map) {
    return MemberModel(
      id: map['id'] as int?,
      memberId: map['memberId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      gender: map['gender'] as String?,
      birthDate: map['birthDate'] as String?,
      address: map['address'] as String?,
      nationalId: map['nationalId'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      membershipType: map['membershipType'] as String? ?? '',
      membershipPrice: (map['membershipPrice'] as num?)?.toDouble() ?? 0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0,
      startDate: map['startDate'] as String? ?? '',
      endDate: map['endDate'] as String? ?? '',
      trainerName: map['trainerName'] as String?,
      notes: map['notes'] != null ? map['notes'] as String : null,
      memberPhotoPath: map['memberPhotoPath'] != null ? map['memberPhotoPath'] as String : null,
      dietPlanId: map['dietPlanId'] != null ? map['dietPlanId'] as int : null,
      additionalServicesIds: map['additionalServicesIds'] != null ? map['additionalServicesIds'] as String : null,
      createdAt: map['createdAt'] as String? ?? '',
    );
  }

  /// تحويل من MemberModel إلى Map (لإدراجه في قاعدة البيانات)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'memberId': memberId,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'gender': gender,
      'birthDate': birthDate,
      'address': address,
      'nationalId': nationalId,
      'emergencyContact': emergencyContact,
      'membershipType': membershipType,
      'membershipPrice': membershipPrice,
      'discount': discount,
      'paidAmount': paidAmount,
      'remainingAmount': remainingAmount,
      'startDate': startDate,
      'endDate': endDate,
      'trainerName': trainerName,
      'notes': notes,
      'memberPhotoPath': memberPhotoPath,
      'dietPlanId': dietPlanId,
      'additionalServicesIds': additionalServicesIds,
      'createdAt': createdAt,
    };
  }

  /// تحويل من Member Entity إلى MemberModel
  factory MemberModel.fromEntity(Member entity) {
    return MemberModel(
      id: entity.id,
      memberId: entity.memberId,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      email: entity.email,
      gender: entity.gender,
      birthDate: entity.birthDate,
      address: entity.address,
      nationalId: entity.nationalId,
      emergencyContact: entity.emergencyContact,
      membershipType: entity.membershipType,
      membershipPrice: entity.membershipPrice,
      discount: entity.discount,
      paidAmount: entity.paidAmount,
      remainingAmount: entity.remainingAmount,
      startDate: entity.startDate,
      endDate: entity.endDate,
      trainerName: entity.trainerName,
      notes: entity.notes,
      memberPhotoPath: entity.memberPhotoPath,
      dietPlanId: entity.dietPlanId,
      additionalServicesIds: entity.additionalServicesIds,
      createdAt: entity.createdAt,
    );
  }

  /// إنشاء نسخة مع تعديلات
  @override
  MemberModel copyWith({
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
    return MemberModel(
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
}
