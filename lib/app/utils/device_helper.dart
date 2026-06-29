import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

class DeviceHelper {
  static Future<String> getDeviceName() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return "${androidInfo.brand} ${androidInfo.model}";
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.utsname.machine ?? "iPhone";
    }

    return "Unknown Device";
  }

  static Future<String> getIpAddress() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP().timeout(const Duration(milliseconds: 300));
      if (ip != null) return ip;
    } catch (_) {}

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      ).timeout(const Duration(milliseconds: 300));
      
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}

    return "0.0.0.0";
  }
}