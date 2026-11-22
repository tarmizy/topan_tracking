import 'package:flutter_test/flutter_test.dart';
import 'package:topan_tracking/app/core/utils/currency_formatter.dart';
import 'package:topan_tracking/app/core/utils/support.dart';

void main() {
  test('nomor WhatsApp dukungan sama dengan landing page', () {
    expect(TopanSupport.whatsappNumber, '6282312255030');
  });

  test('parseFormattedNumber membaca format rupiah', () {
    expect(parseFormattedNumber('350.000'), 350000);
  });
}
