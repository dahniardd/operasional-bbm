import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../models/pemakaian_bbm.dart';
import '../../models/pemakaian_draft.dart';
import '../../providers/harga_bbm_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/input_section_card.dart';
import '../../widgets/input_stepper_header.dart';
import 'input_step2_screen.dart';

class InputStep1Screen extends StatefulWidget {
  const InputStep1Screen({super.key});

  @override
  State<InputStep1Screen> createState() => _InputStep1ScreenState();
}

class _InputStep1ScreenState extends State<InputStep1Screen> {
  late final TextEditingController _tanggalController;

  late DateTime _tanggal;
  int? _kendaraanId;
  String _jenisBbm = 'pertamax';
  String _lokasiPembelian = 'paiton';

  @override
  void initState() {
    super.initState();
    _tanggal = DateTime.now();
    _tanggalController = TextEditingController(text: formatTanggal(_tanggal));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMasters());
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    super.dispose();
  }

  Future<void> _loadMasters() async {
    final master = context.read<MasterDataProvider>();
    final harga = context.read<HargaBbmProvider>();
    final futures = <Future<void>>[];

    if (master.kendaraanList.isEmpty) {
      futures.add(master.loadKendaraan());
    }

    if (harga.hargaList.isEmpty) {
      futures.add(harga.loadHargaBbm());
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  double? _hargaUntuk(HargaBbmProvider provider) {
    return provider.hargaUntukTanggal(_tanggal, _jenisBbm);
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _tanggal = picked;
      _tanggalController.text = formatTanggal(picked);
    });
  }

  void _next(MasterDataProvider master, double? harga) {
    final kendaraan = master.byId(_kendaraanId);

    if (kendaraan == null || harga == null || harga <= 0) {
      return;
    }

    final draft = PemakaianDraft(
      tanggal: _tanggal,
      kendaraanId: kendaraan.id,
      kendaraanLabel: kendaraan.label,
      jenisBbm: _jenisBbm,
      lokasiPembelian: _lokasiPembelian,
      hargaPerLiter: harga,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InputStep2Screen(draft: draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final master = context.watch<MasterDataProvider>();
    final hargaProvider = context.watch<HargaBbmProvider>();
    final harga = _hargaUntuk(hargaProvider);
    final canNext = _kendaraanId != null && harga != null && harga > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const InputStepperHeader(
            title: 'INPUT BBM',
            steps: ['Kendaraan', 'Data', 'Review'],
            currentStep: 0,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputSectionCard(
                    icon: Icons.directions_car_rounded,
                    title: 'Informasi Kendaraan',
                    children: [
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        onTap: _pickTanggal,
                        decoration: const InputDecoration(
                          labelText: 'Tanggal Pengisian',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        key: ValueKey('kendaraan-${_kendaraanId ?? 'none'}'),
                        initialValue: _kendaraanId,
                        isExpanded: true,
                        menuMaxHeight: 320,
                        decoration: const InputDecoration(
                          labelText: 'Kendaraan',
                          prefixIcon: Icon(Icons.directions_car_outlined),
                        ),
                        hint: Text(
                          master.isLoading
                              ? 'Memuat kendaraan...'
                              : 'Pilih kendaraan',
                        ),
                        items: master.kendaraanList
                            .map(
                              (kendaraan) => DropdownMenuItem(
                                value: kendaraan.id,
                                child: Text(
                                  kendaraan.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _kendaraanId = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InputSectionCard(
                    icon: Icons.local_gas_station_rounded,
                    title: 'Detail BBM',
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey('jenis-bbm-$_jenisBbm'),
                        initialValue: _jenisBbm,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Jenis BBM',
                          prefixIcon: Icon(Icons.local_gas_station_outlined),
                        ),
                        items: PemakaianBbm.jenisBbmLabels.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _jenisBbm = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      _HargaPerLiterBox(harga: harga),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Lokasi Pembelian',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'paiton',
                            label: Text('Paiton'),
                            icon: Icon(Icons.location_on_outlined, size: 16),
                          ),
                          ButtonSegment(
                            value: 'luar_paiton',
                            label: Text('Luar Paiton'),
                            icon: Icon(Icons.place_outlined, size: 16),
                          ),
                        ],
                        selected: {_lokasiPembelian},
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.14),
                          selectedForegroundColor: AppColors.darkTeal,
                          foregroundColor: AppColors.slateBlue,
                          side: BorderSide(
                            color:
                                AppColors.slateBlue.withValues(alpha: 0.3),
                          ),
                        ),
                        onSelectionChanged: (selection) {
                          setState(() {
                            _lokasiPembelian = selection.first;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          canNext ? () => _next(master, harga) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canNext
                            ? AppColors.darkTeal
                            : AppColors.slateBlue.withValues(alpha: 0.3),
                        disabledBackgroundColor:
                            AppColors.slateBlue.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Lanjut Pengisian Data',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                  if (!canNext && _kendaraanId != null) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Harga BBM untuk tanggal dan jenis ini belum tersedia.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HargaPerLiterBox extends StatelessWidget {
  final double? harga;

  const _HargaPerLiterBox({required this.harga});

  @override
  Widget build(BuildContext context) {
    final available = harga != null && harga! > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: available
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.danger.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: available
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.price_check_outlined : Icons.info_outline,
            color: available ? AppColors.primary : AppColors.danger,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Harga per Liter',
                  style: TextStyle(
                    fontSize: 11,
                    color: available
                        ? AppColors.slateBlue
                        : AppColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  available
                      ? '${formatRupiah(harga!)} / liter'
                      : 'Belum ada harga untuk tanggal ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: available ? AppColors.darkTeal : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
