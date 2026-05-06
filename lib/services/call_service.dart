import 'package:url_launcher/url_launcher.dart';

class CallService {
  static Future<void> makeEmergencyCall() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '123',
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch dialer';
    }
  }
}