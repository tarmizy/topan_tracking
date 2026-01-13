import 'package:flutter/services.dart';

/// TextInputFormatter untuk format angka dengan separator titik
/// Contoh: 10000 -> 10.000, 1000000 -> 1.000.000
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus semua karakter non-digit
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Format dengan separator titik
    String formatted = _formatWithSeparator(newText);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithSeparator(String value) {
    final buffer = StringBuffer();
    int count = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(value[i]);
      count++;
    }

    return buffer.toString().split('').reversed.join();
  }
}

/// Parse string dengan separator ke double
double parseFormattedNumber(String text) {
  if (text.isEmpty) return 0;
  return double.tryParse(text.replaceAll('.', '')) ?? 0;
}

/// Format double ke string dengan separator
String formatNumber(double number) {
  return number
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
}
