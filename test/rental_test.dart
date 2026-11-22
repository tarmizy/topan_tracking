import 'package:flutter_test/flutter_test.dart';
import 'package:topan_tracking/app/core/utils/rental.dart';

void main() {
  final start = DateTime(2026, 11, 20, 9);

  test('sewa tepat waktu ditagih sesuai kesepakatan', () {
    final r = RentalCalc(
      start: start,
      end: start.add(const Duration(days: 3)),
      dailyRate: 350000,
      now: start.add(const Duration(days: 1)),
    );
    expect(r.billedDays, 3);
    expect(r.total, 1050000);
    expect(r.isOverdue, isFalse);
    expect(r.remaining, const Duration(days: 2));
  });

  test('sewa terlambat menambah hari dan terdeteksi terlambat', () {
    final r = RentalCalc(
      start: start,
      end: start.add(const Duration(days: 3)),
      dailyRate: 350000,
      now: start.add(const Duration(days: 3, hours: 5)),
    );
    expect(r.isOverdue, isTrue);
    expect(r.overdueBy, const Duration(hours: 5));
    expect(r.billedDays, 4);
    expect(r.total, 1400000);
  });

  test('sewa tanpa batas ditagih minimal 1 hari', () {
    final r = RentalCalc(
      start: start,
      dailyRate: 300000,
      now: start.add(const Duration(hours: 2)),
    );
    expect(r.billedDays, 1);
    expect(r.isOverdue, isFalse);
  });

  test('format nomor WhatsApp & rupiah', () {
    expect(toWhatsAppNumber('0812-3456-7890'), '6281234567890');
    expect(toWhatsAppNumber('+62 812 3456 7890'), '6281234567890');
    expect(toWhatsAppNumber(''), isNull);
    expect(formatRupiah(1050000), 'Rp1.050.000');
    expect(formatDurationId(const Duration(days: 2, hours: 3)), '2 hari 3 jam');
  });
}
