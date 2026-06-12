import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int? id;
  final String username;
  final String fullName;
  final String deviceId;
  final String subscriptionType; // 'open', 'limited', 'trial'
  final DateTime? expiryDate;
  final DateTime? createdAt;

  const User({
    this.id,
    required this.username,
    required this.fullName,
    required this.deviceId,
    required this.subscriptionType,
    this.expiryDate,
    this.createdAt,
  });

  /// حساب عدد الأيام المتبقية
  int get daysRemaining {
    if (subscriptionType == 'open' || expiryDate == null) return 9999;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// هل الاشتراك منتهي؟
  bool get isExpired {
    if (subscriptionType == 'open') return false;
    if (expiryDate == null) return true;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// وصف نوع الاشتراك بالعربي
  String get subscriptionLabel {
    switch (subscriptionType) {
      case 'open': return 'مفتوح';
      case 'limited': return 'محدد المدة';
      case 'trial': return 'فترة تجريبية';
      default: return 'غير معروف';
    }
  }

  @override
  List<Object?> get props => [id, username, fullName, deviceId, subscriptionType, expiryDate];
}
