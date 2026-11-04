import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/pemakaian_bbm.dart';
import '../../providers/harga_bbm_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/pemakaian_bbm_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';

class PemakaianFormScreen extends StatefulWidget {
  final PemakaianBbm? item;

  const PemakaianFormScreen({super.key, this.item});

  @override
  State<PemakaianFormScreen> createState() => _PemakaianFormScreenState();
}

class _PemakaianFormScreenState extends State<PemakaianFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tanggalController;
  late final TextEditingController _literController;
  late final TextEditingController _totalController;
  late final TextEditingController _serviceController;
  late final TextEditingController _jasaController;

  late DateTime _tanggal;
  int? _kendaraanId;
  int? _initialKendaraanId;
  String? _jenisBbm;
  String _lokasiPembelian = 'paiton';

  bool _syncing = false;
  String _lastEdited = 'liter';

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _tanggal = item?.tanggal ?? DateTime.now();
    _initialKendaraanId = item?.kendaraanId;
    _jenisBbm = item?.jenisBbm ?? 'pertamax';
    _lokasiPembelian = item?.lokasiPembelian ?? 'paiton';

    _tanggalController = TextEditingController(text: formatTanggal(_tanggal));
    _literController = TextEditingController(
      text: item == null ? '' : formatLiter(item.liter),
    );
    _totalController = TextEditingController(
      text: item == null || item.rp == 0 ? '' : item.rp.round().toString(),
    );
    _serviceController = TextEditingController(
      text: item == null ? '0' : formatAngka(item.serviceOli),
    );
    _jasaController = TextEditingController(
      text: item == null ? '0' : formatAngka(item.jasa),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMasters());
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _literController.dispose();
    _totalController.dispose();
    _serviceController.dispose();
    _jasaController.dispose();
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

    if (!mounted) {
      return;
    }

    if (_initialKendaraanId != null &&
        master.kendaraanList.any((k) => k.id == _initialKendaraanId)) {
      setState(() {
        _kendaraanId = _initialKendaraanId;
      });
    }

    if (widget.item == null) {
      _syncFromLastEdited();
    }
  }

  double? _hargaUntuk(String? jenis, HargaBbmProvider provider) {
    if (jenis == null || jenis.isEmpty) {
      return null;
    }

    return provider.hargaUntukTanggal(_tanggal, jenis);
  }

  void _syncFromLastEdited() {
    if (_syncing) {
      return;
    }

    final harga = _hargaUntuk(
      _jenisBbm,
      context.read<HargaBbmProvider>(),
    );

    if (harga == null || harga <= 0) {
      return;
    }

    if (_lastEdited == 'total') {
      _totalToLiter(harga);
    } else {
      _literToTotal(harga);
    }
  }

  void _literToTotal(double harga) {
    final liter = parseAngka(_literController.text);

    if (liter == null) {
      return;
    }

    _syncing = true;
    _totalController.text = (liter * harga).round().toString();
    _syncing = false;
  }

  void _totalToLiter(double harga) {
    final total = parseAngka(_totalController.text);

    if (total == null || harga <= 0) {
      return;
    }

    final liter = total / harga;
    var text = liter.toStringAsFixed(3);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');

    _syncing = true;
    _literController.text = text.replaceAll('.', ',');
    _syncing = false;
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

    _syncFromLastEdited();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final hargaProvider = context.read<HargaBbmProvider>();
    final harga = _hargaUntuk(_jenisBbm, hargaProvider);

    if (harga == null || harga <= 0) {
      AppSnackbar.error(
        context,
        'Belum ada harga BBM yang berlaku untuk tanggal dan jenis ini.',
      );
      return;
    }

    final provider = context.read<PemakaianBbmProvider>();
    final liter = parseAngka(_literController.text) ?? 0;
    final totalText = _totalController.text.trim();
    final total = totalText.isEmpty ? liter * harga : parseAngka(totalText) ?? 0;
    final service = parseAngka(_serviceController.text) ?? 0;
    final jasa = parseAngka(_jasaController.text) ?? 0;

    final payload = {
      'tanggal': formatTanggalIso(_tanggal),
      'kendaraan_id': _kendaraanId,
      'jenis_bbm': _jenisBbm,
      'lokasi_pembelian': _lokasiPembelian,
      'liter': liter,
      'total_harga': totalText.isEmpty ? null : total,
      'service_oli': service,
      'jasa': jasa,
    };

    final success = await provider.savePemakaian(
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
        provider.error ?? 'Gagal menyimpan data pemakaian BBM.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final master = context.watch<MasterDataProvider>();
    final hargaProvider = context.watch<HargaBbmProvider>();
    final provider = context.watch<PemakaianBbmProvider>();
    final harga = _hargaUntuk(_jenisBbm, hargaProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item == null ? 'Tambah Pemakaian BBM' : 'Edit Pemakaian BBM',
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'Pemakaian BBM',
                child: Column(
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
                      validator: (value) {
                        if (value == null) {
                          return 'Kendaraan wajib dipilih.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('jenis-bbm-${_jenisBbm ?? 'none'}'),
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
                        setState(() {
                          _jenisBbm = value;
                        });
                        _syncFromLastEdited();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Jenis BBM wajib dipilih.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _HargaPerLiterBox(
                      harga: harga,
                      hasJenis: _jenisBbm != null && _jenisBbm!.isNotEmpty,
                    ),
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
                      onSelectionChanged: (selection) {
                        setState(() {
                          _lokasiPembelian = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
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
                            },
                            validator: (value) {
                              final parsed = parseAngka(value ?? '');
                              if (parsed == null || parsed < 0) {
                                return 'Liter tidak valid.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _totalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
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
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Consumable Kendaraan',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _serviceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Sparepart Consumable',
                          hintText: '0',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return null;
                          }
                          final parsed = parseAngka(value!);
                          if (parsed == null || parsed < 0) {
                            return 'Tidak valid.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _jasaController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.,]'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Jasa',
                          hintText: '0',
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return null;
                          }
                          final parsed = parseAngka(value!);
                          if (parsed == null || parsed < 0) {
                            return 'Tidak valid.';
                          }
                          return null;
                        },
                      ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _HargaPerLiterBox extends StatelessWidget {
  final double? harga;
  final bool hasJenis;

  const _HargaPerLiterBox({required this.harga, required this.hasJenis});

  @override
  Widget build(BuildContext context) {
    final available = harga != null && harga! > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: available
            ? AppTheme.primary.withValues(alpha: 0.06)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: available
              ? AppTheme.primary.withValues(alpha: 0.2)
              : AppTheme.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.price_check_outlined : Icons.info_outline,
            color: available ? AppTheme.primary : AppTheme.error,
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
                        ? AppTheme.textSecondary
                        : AppTheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  available
                      ? '${formatRupiah(harga!)} / liter'
                      : hasJenis
                          ? 'Belum ada harga untuk tanggal ini'
                          : 'Pilih jenis BBM terlebih dahulu',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: available ? AppTheme.primary : AppTheme.error,
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
