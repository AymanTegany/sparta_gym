import '../../domain/entities/trainer_entity.dart';

/// نموذج المدرب (Trainer Model)
class TrainerModel extends Trainer {
  const TrainerModel({
    super.id,
    required super.fullName,
    required super.phoneNumber,
    super.specialization,
    super.price,
    super.workingHours,
    super.notes,
    required super.isActive,
    required super.createdAt,
  });

  /// التحويل من SQLite Map
  factory TrainerModel.fromMap(Map<String, dynamic> map) {
    return TrainerModel(
      id: map['id'] as int?,
      fullName: map['fullName'] as String,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      specialization: map['specialization'] as String?,
      price: map['price'] != null ? (map['price'] as num).toDouble() : null,
      workingHours: map['workingHours'] as String?,
      notes: map['notes'] as String?,
      isActive: (map['isActive'] as int?) == 1,
      createdAt: map['createdAt'] as String,
    );
  }

  /// التحويل إلى SQLite Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'specialization': specialization,
      'price': price,
      'workingHours': workingHours,
      'notes': notes,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  /// التحويل من Entity
  factory TrainerModel.fromEntity(Trainer entity) {
    return TrainerModel(
      id: entity.id,
      fullName: entity.fullName,
      phoneNumber: entity.phoneNumber,
      specialization: entity.specialization,
      price: entity.price,
      workingHours: entity.workingHours,
      notes: entity.notes,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
