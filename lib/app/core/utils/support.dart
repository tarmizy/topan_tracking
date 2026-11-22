import 'package:url_launcher/url_launcher.dart';

/// Kontak dukungan Topan (sama dengan landing page).
class TopanSupport {
  static const String whatsappNumber = '6282312255030';
  static const String whatsappDisplay = '+62 823-1225-5030';

  /// Membuka WhatsApp dengan pesan yang sudah terisi.
  static Future<bool> openWhatsApp([String message = 'Halo Topan']) {
    final uri = Uri.parse(
      'https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
