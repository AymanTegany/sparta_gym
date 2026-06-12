import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    super.id,
    required super.username,
    required super.fullName,
    required super.deviceId,
    required super.subscriptionType,
    super.expiryDate,
    super.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id:               map['id'] as int?,
      username:         map['username'] as String,
      fullName:         map['full_name'] as String,
      deviceId:         map['device_id'] as String,
      subscriptionType: map['subscription_type'] as String? ?? 'trial',
      expiryDate:       map['expiry_date'] != null
          ? DateTime.tryParse(map['expiry_date'] as String)
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id':                id,
      'username':          username,
      'full_name':         fullName,
      'device_id':         deviceId,
      'subscription_type': subscriptionType,
      'expiry_date':       expiryDate?.toIso8601String(),
      'created_at':        createdAt?.toIso8601String(),
    };
  }
}
