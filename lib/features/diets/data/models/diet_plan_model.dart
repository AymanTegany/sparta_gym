import '../../domain/entities/diet_plan.dart';

class DietPlanModel extends DietPlan {
  const DietPlanModel({
    super.id,
    required super.name,
    super.description,
    required super.meals,
    super.notes,
    required super.createdAt,
  });

  factory DietPlanModel.fromJson(Map<String, dynamic> json) {
    return DietPlanModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      meals: json['meals'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'meals': meals,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DietPlanModel.fromEntity(DietPlan entity) {
    return DietPlanModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      meals: entity.meals,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }
}
