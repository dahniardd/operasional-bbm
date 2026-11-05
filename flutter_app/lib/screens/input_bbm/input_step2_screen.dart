import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_colors.dart';
import '../../config/theme.dart';
import '../../models/pemakaian_bbm.dart';
import '../../models/pemakaian_draft.dart';
import '../../utils/formatters.dart';
import '../../utils/rupiah_input_formatter.dart';
import '../../widgets/input_section_card.dart';
import '../../widgets/input_stepper_header.dart';
import 'input_step3_screen.dart';

class InputStep2Screen extends StatefulWidget {
  final PemakaianDraft draft;

  const InputStep2Screen({super.key, required this.draft});

  @override
  State<InputStep2Screen> createState() => _InputStep2ScreenState();
}

class _InputStep2ScreenState extends State<InputStep2Screen> {
  late final TextEditingController _literController;
  late final TextEditingController _totalController;
  late final TextEditingController _serviceController;
  late final TextEditingController _jasaController;

  bool _syncing = false;
  String _lastEdited = 'liter';

  @override
  void initState() {
    super.initState();
    _literController = TextEditingController();
    _totalController = TextEditingController();
    _serviceController = TextEditingController(text: '0');
    _jasaController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _literController.dispose();
    _totalController.dispose();
    _serviceController.dispose();
    _jasaController.dispose();
    super.dispose();
  }

  double get _liter => parseAngka(_literController.text) ?? 0;
  double get _service => parseAngka(_serviceController.text) ?? 0;
  double get _jasa => parseAngka(_jasaController.text) ?? 0;

  double get _total {
    final parsed = parseAngka(_totalController.text);

    if (parsed != null && parsed > 0) {
      return parsed;
    }

    return _liter * widget.draft.hargaPerLiter;
  }

  bool get _canNext => _liter > 0 && _total > 0 && _service >= 0 && _jasa >= 0;

  void _syncFromLastEdited() {
    if (_syncing) {
      return;
    }

    final harga = widget.draft.hargaPerLiter;

    if (harga <= 0) {
      return;
    }

    if (_lastEdited == 'total') {
      _totalToLiter(harga);
    } else {
      _literToTotal(harga);
    }
  }

  void _literToTotal(double harga) {
    _syncing = true;
    _totalController.text =
        formatRibuan((_liter * harga).round().toString());
    _syncing = false;
  }

  void _totalToLiter(double harga) {
    final total = parseAngka(_totalController.text);

    if (total == null || total <= 0 || harga <= 0) {
      return;
    }

    var text = (total / harga).toStringAsFixed(3);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');

    _syncing = true;
    _literController.text = text.replaceAll('.', ',');
    _syncing = false;
  }

  void _next() {
    if (!_canNext) {
      return;
    }

    final draft = widget.draft.copyWith(
      liter: _liter,
      totalHarga: _total,
      serviceOli: _service,
      jasa: _jasa,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InputStep3Screen(draft: draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          InputStepperHeader(
            title: 'INPUT BBM',
            steps: const ['Kendaraan', 'Data', 'Review'],
            currentStep: 1,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(draft),
                  const SizedBox(height: 16),
                  InputSectionCard(
                    icon: Icons.local_gas_station_rounded,
                    title: 'Pengisian BBM',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _literController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.,]'),
                                ),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Liter',
                                hintText: '0,000',
                              ),
                              onChanged: (_) {
                                if (_syncing) {
                                  return;
                                }
                                _lastEdited = 'liter';
                                _syncFromLastEdited();
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _totalController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                RupiahInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Total Harga (Rp)',
                                hintText: '0',
                              ),
                              onChanged: (_) {
                                if (_syncing) {
                                  return;
                                }
                                _lastEdited = 'total';
                                _syncFromLastEdited();
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.price_check_outlined,
                            size: 14,
                            color: AppColors.slateBlue.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Harga per liter: '
                            '${formatRupiah(draft.hargaPerLiter)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.slateBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InputSectionCard(
                    icon: Icons.build_circle_rounded,
                    title: 'Consumable Kendaraan',
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _serviceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                RupiahInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Sparepart Consumable',
                                hintText: '0',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _jasaController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                RupiahInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Jasa',
                                hintText: '0',
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildEstimateCard(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _canNext ? _next : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _canNext
                            ? AppColors.darkTeal
                            : AppColors.slateBlue.withValues(alpha: 0.3),
                        disabledBackgroundColor:
                            AppColors.slateBlue.withValues(alpha: 0.3),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Simpan & Lanjutkan',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slateBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(PemakaianDraft draft) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_car_rounded,
                size: 16,
                color: AppColors.darkTeal,
              ),
              const SizedBox(width: 6),
              Text(
                'KENDARAAN TERPILIH',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            draft.kendaraanLabel,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          _infoRow(
            Icons.calendar_today_rounded,
            'Tanggal: ${formatTanggal(draft.tanggal)}',
          ),
          const SizedBox(height: 3),
          _infoRow(
            Icons.local_gas_station_rounded,
            '${PemakaianBbm.jenisBbmLabels[draft.jenisBbm] ?? '-'} · '
            '${PemakaianBbm.lokasiLabels[draft.lokasiPembelian] ?? '-'}',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.textMuted),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SEMENTARA',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          _estimateRow('Pembelian BBM', formatRupiah(_total)),
          const SizedBox(height: 8),
          _estimateRow('Sparepart', formatRupiah(_service)),
          const SizedBox(height: 8),
          _estimateRow('Jasa', formatRupiah(_jasa)),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              Text(
                formatRupiah(_total + _service + _jasa),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _estimateRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}