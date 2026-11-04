import 'package:flutter_test/flutter_test.dart';
import 'package:operasional_bbm/models/pemakaian_bbm.dart';
import 'package:operasional_bbm/utils/formatters.dart';

void main() {
  test('parseAngka handles Indonesian separators', () {
    expect(parseAngka('1.500,50'), 1500.5);
    expect(parseAngka('2,5'), 2.5);
    expect(parseAngka('150000'), 150000);
    expect(parseAngka(''), isNull);
  });

  test('label jenis BBM tersedia lengkap', () {
    expect(PemakaianBbm.jenisBbmLabels['pertamax_turbo'], 'Pertamax Turbo');
    expect(PemakaianBbm.jenisBbmLabels['solar'], 'Solar');
    expect(PemakaianBbm.jenisBbmLabels.length, 5);
    expect(PemakaianBbm.lokasiLabels['luar_paiton'], 'Luar Paiton');
  });
}
