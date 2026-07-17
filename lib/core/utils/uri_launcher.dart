import 'package:url_launcher/url_launcher.dart';

class ExternalLauncher {
  static Future<void> call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);

    if (await canLaunchUrl(uri)) {
      final success = await launchUrl(uri);
      if (!success) {
        throw Exception('Dialer opened but failed to launch');
      }
    } else {
      throw Exception('Device cannot handle phone calls');
    }
  }

  static Future<void> email(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);

    if (await canLaunchUrl(uri)) {
      final success = await launchUrl(uri);
      if (!success) {
        throw Exception('Email client failed to open');
      }
    } else {
      throw Exception('No email client available');
    }
  }

  static Future<void> _launch(Uri uri) async {
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!success) {
      throw Exception('Could not launch $uri');
    }
  }

  static Future<void> openMapWithPincode(String pincode) async {
    final encoded = Uri.encodeComponent(pincode);

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );

    await _launch(uri);
  }

  /// Open map using full address
  static Future<void> openMapWithAddress(String address) async {
    final encoded = Uri.encodeComponent(address);

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encoded',
    );

    await _launch(uri);
  }
}
