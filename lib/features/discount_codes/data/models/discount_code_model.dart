import '../../domain/entities/discount_code.dart';

class DiscountCodeModel extends DiscountCode {
  const DiscountCodeModel({
    super.id,
    required super.name,
    required super.type,
    required super.value,
    required super.createdAt,
  });

  factory DiscountCodeModel.fromJson(Map<String, dynamic> json) {
    return DiscountCodeModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      value: json['value'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'value': value,
      'createdAt': createdAt,
    };
  }

  factory DiscountCodeModel.fromEntity(DiscountCode entity) {
    return DiscountCodeModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      value: entity.value,
      createdAt: entity.createdAt,
    );
  }
}
