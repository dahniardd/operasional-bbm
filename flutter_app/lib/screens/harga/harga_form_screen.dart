import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/harga_bbm.dart';
import '../../providers/harga_bbm_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';

class HargaBbmFormScreen extends StatefulWidget {
  final HargaBbm? item;

  const HargaBbmFormScreen({super.key, this.item});

  @override
  State<HargaBbmFormScreen> createState() => _HargaBbmFormScreenState();
}

class _HargaBbmFormScreenState extends State<HargaBbmFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tanggalController;
  late final TextEditingController _pertamaxController;
  late final TextEditingController _pertadexController;
  late final TextEditingController _dexliteController;
  late final TextEditingController _turboController;
  late final TextEditingController _solarController;

  late DateTime _tanggal;
  late DateTime _firstDate;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    final latest = context.read<HargaBbmProvider>().terakhir;

    if (item != null) {
      _tanggal = item.tanggalBerlaku;
      _firstDate = DateTime(2020);
    } else if (latest != null) {
      _tanggal = latest.tanggalBerlaku.add(const Duration(days: 1));
      _firstDate = _tanggal;
    } else {
      _tanggal = DateTime.now();
      _firstDate = DateTime(2020);
    }

    _tanggalController = TextEditingController(text: formatTanggal(_tanggal));
    _pertamaxController = TextEditingController(
      text: item == null ? '' : item.hargaPertamax.round().toString(),
    );
    _pertadexController = TextEditingController(
      text: item == null ? '' : item.hargaPertadex.round().toString(),
    );
    _dexliteController = TextEditingController(
      text: item == null ? '' : item.hargaDexlite.round().toString(),
    );
    _turboController = TextEditingController(
      text: item == null ? '' : item.hargaPertamaxTurbo.round().toString(),
    );
    _solarController = TextEditingController(
      text: item == null ? '' : item.hargaSolar.round().toString(),
    );
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _pertamaxController.dispose();
    _pertadexController.dispose();
    _dexliteController.dispose();
    _turboController.dispose();
    _solarController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal.isBefore(_firstDate) ? _firstDate : _tanggal,
      firstDate: _firstDate,
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

  String? _validateHarga(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label wajib diisi.';
    }

    final parsed = double.tryParse(value.replaceAll('.', '').replaceAll(',', '.'));

    if (parsed == null) {
      return '$label harus berupa angka.';
    }

    if (parsed < 1) {
      return '$label tidak boleh 0.';
    }

    return null;
  }

  double _toDouble(String value) {
    return double.parse(value.replaceAll('.', '').replaceAll(',', '.'));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final provider = context.read<HargaBbmProvider>();

    final payload = {
      'tanggal_berlaku': formatTanggalIso(_tanggal),
      'harga_pertamax': _toDouble(_pertamaxController.text),
      'harga_pertadex': _toDouble(_pertadexController.text),
      'harga_dexlite': _toDouble(_dexliteController.text),
      'harga_pertamax_turbo': _toDouble(_turboController.text),
      'harga_solar': _toDouble(_solarController.text),
    };

    final success = await provider.saveHargaBbm(
      payload,
      id: widget.item?.id,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      AppSnackbar.error(
        context,
        provider.error ?? 'Gagal menyimpan harga BBM.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HargaBbmProvider>();
    final isEdit = widget.item != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Harga BBM' : 'Tambah Harga BBM'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isEdit && provider.terakhir != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.history,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Data terakhir: ${formatTanggalPanjang(provider.terakhir!.tanggalBerlaku)}. Tanggal baru harus setelah tanggal tersebut.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: const Color(0xFFE8EDF3)),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _tanggalController,
                      readOnly: true,
                      onTap: _pickTanggal,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal Berlaku',
                        prefixIcon: Icon(Icons.event_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HargaField(
                      controller: _pertamaxController,
                      label: 'Harga Pertamax',
                      validator: (value) =>
                          _validateHarga(value, 'Harga Pertamax'),
                    ),
                    const SizedBox(height: 12),
                    _HargaField(
                      controller: _turboController,
                      label: 'Harga Pertamax Turbo',
                      validator: (value) =>
                          _validateHarga(value, 'Harga Pertamax Turbo'),
                    ),
                    const SizedBox(height: 12),
                    _HargaField(
                      controller: _dexliteController,
                      label: 'Harga Dexlite',
                      validator: (value) =>
                          _validateHarga(value, 'Harga Dexlite'),
                    ),
                    const SizedBox(height: 12),
                    _HargaField(
                      controller: _pertadexController,
                      label: 'Harga Pertadex',
                      validator: (value) =>
                          _validateHarga(value, 'Harga Pertadex'),
                    ),
                    const SizedBox(height: 12),
                    _HargaField(
                      controller: _solarController,
                      label: 'Harga Solar',
                      validator: (value) =>
                          _validateHarga(value, 'Harga Solar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: provider.isSubmitting ? null : _submit,
                  icon: provider.isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    provider.isSubmitting ? 'Menyimpan...' : 'Simpan',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HargaField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;

  const _HargaField({
    required this.controller,
    required this.label,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        hintText: '0',
      ),
      validator: validator,
    );
  }
}
