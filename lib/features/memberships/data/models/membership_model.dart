import '../../domain/entities/membership_entity.dart';

/// ──────────────────────────────────────────────────────────────────────────────
/// نموذج باقة الاشتراك (Membership Model)
/// ──────────────────────────────────────────────────────────────────────────────
class MembershipModel extends Membership {
  const MembershipModel({
    super.id,
    required super.name,
    required super.durationDays,
    required super.price,
    required super.freezeDays,
    super.visitsLimit,
    required super.isActive,
    required super.createdAt,
  });

  /// التحويل من SQLite Map
  factory MembershipModel.fromMap(Map<String, dynamic> map) {
    return MembershipModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      durationDays: map['durationDays'] as int,
      price: (map['price'] as num).toDouble(),
      freezeDays: map['freezeDays'] as int,
      visitsLimit: map['visitsLimit'] as int?,
      isActive: (map['isActive'] as int) == 1,
      createdAt: map['createdAt'] as String,
    );
  }

  /// التحويل إلى SQLite Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'durationDays': durationDays,
      'price': price,
      'freezeDays': freezeDays,
      'visitsLimit': visitsLimit,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  /// التحويل من Entity
  factory MembershipModel.fromEntity(Membership entity) {
    return MembershipModel(
      id: entity.id,
      name: entity.name,
      durationDays: entity.durationDays,
      price: entity.price,
      freezeDays: entity.freezeDays,
      visitsLimit: entity.visitsLimit,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
