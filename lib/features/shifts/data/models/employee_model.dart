import '../../domain/entities/employee_entity.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    super.id,
    required super.name,
    super.role = 'employee',
    super.isActive = true,
    super.createdAt,
  });

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      role: map['role'] as String? ?? 'employee',
      isActive: (map['isActive'] as int?) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'role': role,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory EmployeeModel.fromEntity(Employee entity) {
    return EmployeeModel(
      id: entity.id,
      name: entity.name,
      role: entity.role,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}
