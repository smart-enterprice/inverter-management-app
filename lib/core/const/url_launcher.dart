import 'package:url_launcher/url_launcher.dart';

Future<void> _makeCall(String phone) async {
  final uri = Uri.parse('tel:$phone');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> _sendWhatsApp(String phone, {String message = ''}) async {
  final uri = Uri.parse(
    'https://wa.me/$phone?text=${Uri.encodeComponent(message)}',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> _sendEmail(String email) async {
  final uri = Uri(
    scheme: 'mailto',
    path: email,
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}
