import 'package:internet_connection_checker/internet_connection_checker.dart';

/// كلاس مساعد للتحقق مما إذا كان الجهاز متصلاً بالإنترنت أم لا قبل إجراء طلبات الشبكة.
abstract class ConnectionChecker {
  Future<bool> get isConnected;
}

class ConnectionCheckerImpl implements ConnectionChecker {
  final InternetConnectionChecker connectionChecker;

  ConnectionCheckerImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}
