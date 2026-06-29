import 'package:equatable/equatable.dart';

class DiscountCode extends Equatable {
  final int? id;
  final String name;
  final String type; // 'fixed' or 'percentage'
  final double value;
  final String createdAt;

  const DiscountCode({
    this.id,
    required this.name,
    required this.type,
    required this.value,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, type, value, createdAt];
}
