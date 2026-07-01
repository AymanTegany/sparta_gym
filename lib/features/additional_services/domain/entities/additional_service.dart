import 'package:equatable/equatable.dart';

class AdditionalService extends Equatable {
  final int? id;
  final String name;
  final double monthlyPrice;
  final int visitsLimit;
  final bool isActive;
  final String createdAt;

  const AdditionalService({
    this.id,
    required this.name,
    required this.monthlyPrice,
    required this.visitsLimit,
    this.isActive = true,
    required this.createdAt,
  });

  AdditionalService copyWith({
    int? id,
    String? name,
    double? monthlyPrice,
    int? visitsLimit,
    bool? isActive,
    String? createdAt,
  }) {
    return AdditionalService(
      id: id ?? this.id,
      name: name ?? this.name,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      visitsLimit: visitsLimit ?? this.visitsLimit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        monthlyPrice,
        visitsLimit,
        isActive,
        createdAt,
      ];
}
