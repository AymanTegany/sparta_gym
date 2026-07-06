import 'package:equatable/equatable.dart';

/// كيان الموظف
class Employee extends Equatable {
  final int? id;
  final String name;
  final String role; // 'admin' أو 'employee'
  final bool isActive;
  final DateTime? createdAt;

  const Employee({
    this.id,
    required this.name,
    this.role = 'employee',
    this.isActive = true,
    this.createdAt,
  });

  /// هل هذا الموظف مدير؟
  bool get isAdmin => role == 'admin';

  /// وصف الدور بالعربي
  String get roleLabel => isAdmin ? 'مدير' : 'موظف';

  Employee copyWith({
    int? id,
    String? name,
    String? role,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, role, isActive, createdAt];
}
