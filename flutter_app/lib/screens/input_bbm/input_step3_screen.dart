import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/pemakaian_bbm.dart';
import '../../models/pemakaian_draft.dart';
import '../../providers/pemakaian_bbm_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/input_section_card.dart';
import '../../widgets/input_stepper_header.dart';
import '../main_shell.dart';

class InputStep3Screen extends StatefulWidget {
  final PemakaianDraft draft;

  const InputStep3Screen({super.key, required this.draft});

  @override
  State<InputStep3Screen> createState() => _InputStep3ScreenState();
}

class _InputStep3ScreenState extends State<InputStep3Screen> {
  Future<void> _submit() async {
    final provider = context.read<PemakaianBbmProvider>();
    final draft = widget.draft;

    final payload = {
      'tanggal': formatTanggalIso(draft.tanggal),
      'kendaraan_id': draft.kendaraanId,
      'jenis_bbm': draft.jenisBbm,
      'lokasi_pembelian': draft.lokasiPembelian,
      'liter': draft.liter,
      'total_harga': draft.totalPembelian,
      'service_oli': draft.serviceOli,
      'jasa': draft.jasa,
    };

    final success = await provider.savePemakaian(payload);

    if (!mounted) {
      return;
    }

    if (success) {
      _showSuccessDialog();
    } else {
      AppSnackbar.error(
        context,
        provider.error ?? 'Gagal menyimpan data pemakaian BBM.',
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.success,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Berhasil!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pemakaian BBM berhasil disimpan.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
                child: Text(
                  'Kembali ke Dashboard',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PemakaianBbmProvider>();
    final draft = widget.draft;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          const InputStepperHeader(
            title: 'INPUT BBM',
            steps: ['Kendaraan', 'Data', 'Review'],
            currentStep: 2,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InputSectionCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'Ringkasan Pemakaian',
                    children: [
                      _summaryRow(
                        'Tanggal',
                        formatTanggal(draft.tanggal),
                      ),
                      _summaryRow('Kendaraan', draft.kendaraanLabel),
                      _summaryRow(
                        'Jenis BBM',
                        PemakaianBbm.jenisBbmLabels[draft.jenisBbm] ?? '-',
                      ),
                      _summaryRow(
                        'Lokasi',
                        PemakaianBbm.lokasiLabels[draft.lokasiPembelian] ??
                            '-',
                      ),
                      _summaryRow(
                        'Harga per Liter',
                        formatRupiah(draft.hargaPerLiter),
                      ),
                      _summaryRow('Liter', formatLiter(draft.liter)),
                      _summaryRow(
                        'Harga BBM',
                        formatRupiah(draft.totalPembelian),
                      ),
                      _summaryRow(
                        'Sparepart Consumable',
                        formatRupiah(draft.serviceOli),
                      ),
                      _summaryRow('Jasa', formatRupiah(draft.jasa)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Jumlah',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          formatRupiah(draft.jumlah),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: provider.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'KONFIRMASI & SIMPAN',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.save_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: TextButton.styleFrom(
                        backgroundColor: AppTheme.primary.withValues(
                          alpha: 0.06,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kembali untuk Edit',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
