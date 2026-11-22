/// Perhitungan sewa kendaraan Topan (murni, mudah dites).
class RentalCalc {
  final DateTime start;
  final DateTime? end;
  final double dailyRate;
  final DateTime now;

  RentalCalc({
    required this.start,
    required this.dailyRate,
    this.end,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  static int _ceilDays(Duration d) {
    final hours = d.inMinutes / 60;
    final days = (hours / 24).ceil();
    return days < 1 ? 1 : days;
  }

  /// Jumlah hari yang disepakati (dari tanggal mulai s/d selesai).
  int? get plannedDays => end == null ? null : _ceilDays(end!.difference(start));

  /// Jumlah hari yang ditagih: sesuai kesepakatan, atau lebih bila terlambat.
  int get billedDays {
    final elapsed = _ceilDays(now.difference(start));
    final planned = plannedDays;
    if (planned == null) return elapsed;
    return elapsed > planned ? elapsed : planned;
  }

  double get total => billedDays * dailyRate;

  bool get isOverdue => end != null && now.isAfter(end!);

  /// Lama keterlambatan (nol bila belum lewat).
  Duration get overdueBy => isOverdue ? now.difference(end!) : Duration.zero;

  /// Sisa waktu sebelum masa sewa habis (nol bila sudah lewat / tanpa batas).
  Duration get remaining =>
      end == null || isOverdue ? Duration.zero : end!.difference(now);
}

/// "2 hari 3 jam", "5 jam", "40 menit".
String formatDurationId(Duration d) {
  if (d.inMinutes < 60) return '${d.inMinutes} menit';
  final days = d.inDays;
  final hours = d.inHours % 24;
  if (days == 0) return '${d.inHours} jam';
  return hours == 0 ? '$days hari' : '$days hari $hours jam';
}

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// "22 Nov 2026, 09.30"
String formatDateTimeId(DateTime d) {
  final l = d.toLocal();
  final hh = l.hour.toString().padLeft(2, '0');
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.day} ${_bulan[l.month - 1]} ${l.year}, $hh.$mm';
}

/// "Rp1.050.000"
String formatRupiah(num value) {
  final s = value.round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );
  return 'Rp$s';
}

/// Nomor HP Indonesia → format wa.me (62xxxxxxxx). Null bila tidak valid.
String? toWhatsAppNumber(String? phone) {
  if (phone == null) return null;
  var p = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (p.isEmpty) return null;
  if (p.startsWith('0')) p = '62${p.substring(1)}';
  if (p.startsWith('8')) p = '62$p';
  return p.length >= 10 ? p : null;
}
