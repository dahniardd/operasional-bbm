import 'package:intl/intl.dart';

final NumberFormat _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final DateFormat _tanggalFormat = DateFormat('dd/MM/yyyy');
final DateFormat _tanggalPanjangFormat = DateFormat('d MMMM yyyy', 'id_ID');

String formatRupiah(num value) => _rupiahFormat.format(value);

String formatAngka(num value) {
  final isRound = value == value.roundToDouble();

  return NumberFormat.decimalPattern('id_ID').format(
    isRound ? value.round() : value,
  );
}

String formatLiter(num value) {
  final text = NumberFormat('#,##0.###', 'id_ID').format(value);

  return text;
}

String formatTanggal(DateTime date) => _tanggalFormat.format(date);

String formatTanggalPanjang(DateTime date) => _tanggalPanjangFormat.format(date);

String formatTanggalIso(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}

double? parseAngka(String value) {
  final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');

  if (normalized.isEmpty) {
    return null;
  }

  return double.tryParse(normalized);
}
