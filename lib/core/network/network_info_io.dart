import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'network_info.dart';

class NetworkInfoIo implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  NetworkInfoIo(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}
