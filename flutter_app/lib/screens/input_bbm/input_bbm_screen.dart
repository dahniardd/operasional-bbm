import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/pemakaian_bbm.dart';
import '../../providers/harga_bbm_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/pemakaian_bbm_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/rupiah_input_formatter.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/input_section_card.dart';
import '../../widgets/input_stepper_header.dart';

class InputBbmScreen extends StatefulWidget {
  const InputBbmScreen({super.key});

  @override
  State<InputBbmScreen> createState() => _InputBbmScreenState();
}

class _InputBbmScreenState extends State<InputBbmScreen> {
  late final TextEditingController _tanggalController;
  late final TextEditingController _literController;
  late final TextEditingController _totalController;

  late DateTime _tanggal;
  int? _kendaraanId;
  String _jenisBbm = 'pertamax';
  String _lokasiPembelian = 'paiton';

  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _fotoBytes;
  String? _fotoName;
  bool _pickingFoto = false;

  @override
  void initState() {
    super.initState();
    _tanggal = DateTime.now();
    _tanggalController = TextEditingController(text: formatTanggal(_tanggal));
    _literController = TextEditingController();
    _totalController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMasters());
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _literController.dispose();
    _totalController.dispose();
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

      if (mounted) {
        setState(_resyncTotal);
      }
    }
  }

  double? _hargaUntuk(HargaBbmProvider provider) {
    return provider.hargaUntukTanggal(_tanggal, _jenisBbm);
  }

  double get _hargaPerLiter =>
      _hargaUntuk(context.read<HargaBbmProvider>()) ?? 0;

  double get _liter => parseAngka(_literController.text) ?? 0;

  double get _total {
    final parsed = parseAngka(_totalController.text);

    if (parsed != null && parsed > 0) {
      return parsed;
    }

    return _liter * _hargaPerLiter;
  }

  static const double _totalMaks = 50000000;

  String? get _totalError {
    final total = parseAngka(_totalController.text);

    if (total == null || total <= 0) {
      return null;
    }

    if (_hargaPerLiter > 0 && total < _hargaPerLiter) {
      return 'Minimal pembelian 1 liter (${formatRupiah(_hargaPerLiter)}).';
    }

    if (total > _totalMaks) {
      return 'Total harga terlalu besar. Maksimal ${formatRupiah(_totalMaks)}.';
    }

    return null;
  }

  bool get _canSubmit =>
      _kendaraanId != null &&
      _hargaPerLiter > 0 &&
      _liter > 0 &&
      _total > 0 &&
      _totalError == null;

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

    if (!mounted) {
      return;
    }

    setState(() {
      _tanggal = picked;
      _tanggalController.text = formatTanggal(picked);
      _resyncTotal();
    });
  }

  void _resyncTotal() {
    _totalToLiter(_hargaPerLiter);
  }

  void _totalToLiter(double harga) {
    final total = parseAngka(_totalController.text);

    if (total == null || total <= 0 || harga <= 0) {
      _literController.text = '';
      return;
    }

    var text = (total / harga).toStringAsFixed(3);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');

    _literController.text = text.replaceAll('.', ',');
  }

  Future<void> _pilihSumberFoto() async {
    if (_pickingFoto) {
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                'Ambil dari Kamera',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                'Pilih dari Galeri',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    await _ambilFoto(source);
  }

  Future<void> _ambilFoto(ImageSource source) async {
    setState(() {
      _pickingFoto = true;
    });

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );

      if (picked == null) {
        return;
      }

      final bytes = await picked.readAsBytes();

      if (!mounted) {
        return;
      }

      setState(() {
        _fotoBytes = bytes;
        _fotoName = picked.name.isEmpty ? 'bukti_bbm.jpg' : picked.name;
      });
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Gagal mengambil foto. Coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _pickingFoto = false;
        });
      }
    }
  }

  void _hapusFoto() {
    setState(() {
      _fotoBytes = null;
      _fotoName = null;
    });
  }

  Future<void> _submit() async {
    final provider = context.read<PemakaianBbmProvider>();

    if (provider.isSubmitting || !_canSubmit) {
      return;
    }

    final payload = {
      'tanggal': formatTanggalIso(_tanggal),
      'kendaraan_id': _kendaraanId,
      'jenis_bbm': _jenisBbm,
      'lokasi_pembelian': _lokasiPembelian,
      'liter': _liter,
      'total_harga': _total,
      'service_oli': 0,
      'jasa': 0,
    };

    MultipartFile? buktiBbm;
    final foto = _fotoBytes;
    if (foto != null) {
      buktiBbm = MultipartFile.fromBytes(
        foto,
        filename: _fotoName ?? 'bukti_bbm.jpg',
      );
    }

    final success = await provider.savePemakaian(payload, buktiBbm: buktiBbm);

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
    final hijauGelap = Color.lerp(AppColors.success, Colors.black, 0.28)!;

    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Berhasil',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            constraints: const BoxConstraints(maxWidth: 340),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Satu ikon centang bergradien hijau
                Container(
                  width: 66,
                  height: 66,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.success, hijauGelap],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.32),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 38,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Berhasil!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pemakaian BBM berhasil disimpan.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 26),
                // Tombol bergradien biru (sama dengan tab aktif di Riwayat)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).pop(true);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.primary, AppColors.darkNavy],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Kembali ke Dashboard',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final master = context.watch<MasterDataProvider>();
    final hargaProvider = context.watch<HargaBbmProvider>();
    final provider = context.watch<PemakaianBbmProvider>();
    final harga = _hargaUntuk(hargaProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const InputStepperHeader(
            title: 'INPUT BBM',
            steps: <String>[],
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
                            _resyncTotal();
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
                      _LokasiPembelianSelector(
                        value: _lokasiPembelian,
                        onChanged: (value) {
                          setState(() {
                            _lokasiPembelian = value;
                          });
                        },
                      ),
                    ],
                  ),
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
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Liter (otomatis)',
                                hintText: '0,000',
                                suffixIcon: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _totalController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [RupiahInputFormatter()],
                              decoration: const InputDecoration(
                                labelText: 'Total Harga (Rp)',
                                hintText: '0',
                              ),
                              onChanged: (_) {
                                _resyncTotal();
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_totalError != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 14,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                _totalError!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.price_check_outlined,
                            size: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Harga per liter: '
                            '${formatRupiah(_hargaPerLiter)}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Liter dihitung otomatis dari Total Harga '
                              'dibagi Harga per Liter.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildBuktiCard(),
                  const SizedBox(height: 16),
                  _buildEstimateCard(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: provider.isSubmitting || !_canSubmit
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.textSecondary
                            .withValues(alpha: 0.3),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
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
                                  style: GoogleFonts.poppins(
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
                  if (_kendaraanId != null &&
                      (harga == null || harga <= 0)) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Harga BBM untuk tanggal dan jenis ini belum tersedia.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
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

  Widget _buildBuktiCard() {
    final hasFoto = _fotoBytes != null;

    return InputSectionCard(
      icon: Icons.photo_camera_rounded,
      title: 'Bukti BBM',
      children: [
        Text(
          'Opsional. Lampirkan foto struk atau bukti pengisian BBM.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (!hasFoto)
          InkWell(
            onTap: _pickingFoto ? null : _pilihSumberFoto,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  if (_pickingFoto)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  else
                    const Icon(
                      Icons.add_a_photo_outlined,
                      size: 30,
                      color: AppColors.primary,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _pickingFoto ? 'Memproses foto...' : 'Tambah Foto Bukti',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ambil dari kamera atau pilih dari galeri',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: Image.memory(
              _fotoBytes!,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickingFoto ? null : _pilihSumberFoto,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Ganti Foto'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickingFoto ? null : _hapusFoto,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Hapus'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: BorderSide(
                      color: AppColors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildEstimateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL SEMENTARA',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 12),
          _estimateRow('Pembelian BBM', formatRupiah(_total)),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              Text(
                formatRupiah(_total),
                style: GoogleFonts.poppins(
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
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _LokasiPembelianSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LokasiPembelianSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LokasiPembelianOption(
            label: 'Paiton',
            icon: Icons.location_on_outlined,
            selected: value == 'paiton',
            onTap: () => onChanged('paiton'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _LokasiPembelianOption(
            label: 'Luar Paiton',
            icon: Icons.place_outlined,
            selected: value == 'luar_paiton',
            onTap: () => onChanged('luar_paiton'),
          ),
        ),
      ],
    );
  }
}

class _LokasiPembelianOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _LokasiPembelianOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
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
                        ? AppColors.textSecondary
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
                    color: available ? AppColors.darkNavy : AppColors.danger,
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
