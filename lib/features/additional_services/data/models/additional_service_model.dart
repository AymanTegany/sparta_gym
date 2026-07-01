import '../../domain/entities/additional_service.dart';

class AdditionalServiceModel extends AdditionalService {
  const AdditionalServiceModel({
    super.id,
    required super.name,
    required super.monthlyPrice,
    required super.visitsLimit,
    super.isActive = true,
    required super.createdAt,
  });

  factory AdditionalServiceModel.fromMap(Map<String, dynamic> map) {
    return AdditionalServiceModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      monthlyPrice: (map['monthlyPrice'] as num).toDouble(),
      visitsLimit: map['visitsLimit'] as int,
      isActive: map['isActive'] == 1,
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'monthlyPrice': monthlyPrice,
      'visitsLimit': visitsLimit,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
    };
  }

  factory AdditionalServiceModel.fromEntity(AdditionalService entity) {
    return AdditionalServiceModel(
      id: entity.id,
      name: entity.name,
      monthlyPrice: entity.monthlyPrice,
      visitsLimit: entity.visitsLimit,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
