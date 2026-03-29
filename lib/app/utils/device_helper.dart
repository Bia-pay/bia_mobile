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
    final info = NetworkInfo();
    final ip = await info.getWifiIP();
    return ip ?? "0.0.0.0";
  }
}