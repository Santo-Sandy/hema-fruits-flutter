import 'dart:io';
import 'package:cashew_marketplace/core/plugins/device_plugins.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  /// Get device details
  Future<DeviceInfo> deviceDetails() async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfoPlugin.androidInfo;
      return DeviceInfo(
        id: androidDeviceInfo.id,
        model: androidDeviceInfo.model,
        brand: androidDeviceInfo.brand,
        device: androidDeviceInfo.device,
        sdk: androidDeviceInfo.version.sdkInt.toString(),
      );
    } else if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfoPlugin.iosInfo;
      return DeviceInfo(
        id: iosDeviceInfo.identifierForVendor,
        model: iosDeviceInfo.model,
        brand: 'iphone',
        device: iosDeviceInfo.utsname.machine,
        sdk: iosDeviceInfo.utsname.sysname,
      );
    }
    return DeviceInfo();
  }

  /// Check online connectivity
  // Future<void> checkOnline(BuildContext context) async {
  //   final connectivityResult = await Connectivity().checkConnectivity();
  //   if (connectivityResult != ConnectivityResult.none) {
  //     debugPrint('Device is online');
  //   } else {
  //     debugPrint('Device is offline');
  //   }
  // }
}
