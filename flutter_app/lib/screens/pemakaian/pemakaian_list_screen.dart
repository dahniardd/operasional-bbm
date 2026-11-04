import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/pemakaian_bbm.dart';
import '../../providers/auth_provider.dart';
import '../../providers/master_data_provider.dart';
import '../../providers/pemakaian_bbm_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import 'pemakaian_form_screen.dart';

class PemakaianListScreen extends StatefulWidget {
  const PemakaianListScreen({super.key});

  @override
  State<PemakaianListScreen> createState() => _PemakaianListScreenState();
}

class _PemakaianListScreenState extends State<PemakaianListScreen> {
  final _searchController = TextEditingController();

  Timer? _searchDebounce;
  bool _showFilters = false;

  String? _jenisKendaraan;
  int? _kendaraanId;
  String? _jenisBbm;
  String? _lokasiPembelian;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialLoad());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    final master = context.read<MasterDataProvider>();

    if (master.kendaraanList.isEmpty) {
      await master.loadKendaraan();
    }

    if (!mounted) {
      return;
    }

    await _load();
  }

  Future<void> _load({bool reset = true}) {
    return context.read<PemakaianBbmProvider>().loadPemakaian(
          search: _searchController.text.trim(),
          jenisKendaraan: _jenisKendaraan,
          kendaraanId: _kendaraanId,
          jenisBbm: _jenisBbm,
          lokasiPembelian: _lokasiPembelian,
          reset: reset,
        );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      _load();
    });
  }

  void _resetFilter() {
    setState(() {
      _jenisKendaraan = null;
      _kendaraanId = null;
      _jenisBbm = null;
      _lokasiPembelian = null;
      _searchController.clear();
    });
    _load();
  }

  Future<void> _openForm([PemakaianBbm? item]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PemakaianFormScreen(item: item),
      ),
    );

    if (changed != true || !mounted) {
      return;
    }

    await _load();

    if (!mounted) {
      return;
    }

    final message = context.read<PemakaianBbmProvider>().successMessage;

    if (message != null) {
      AppSnackbar.success(context, message);
    }
  }

  Future<void> _confirmDelete(PemakaianBbm item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Pemakaian?'),
        content: Text(
          'Data ${item.platNomor} tanggal ${formatTanggal(item.tanggal)} akan dihapus. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final provider = context.read<PemakaianBbmProvider>();
    final success = await provider.deletePemakaian(item.id);

    if (!mounted) {
      return;
    }

    if (success) {
      AppSnackbar.success(
        context,
        provider.successMessage ?? 'Data berhasil dihapus.',
      );
    } else {
      AppSnackbar.error(
        context,
        provider.error ?? 'Gagal menghapus data.',
      );
    }
  }

  Future<void> _refreshHarga() async {
    final provider = context.read<PemakaianBbmProvider>();
    final success = await provider.refreshHarga();

    if (!mounted) {
      return;
    }

    if (success) {
      AppSnackbar.success(
        context,
        provider.successMessage ?? 'Refresh harga selesai.',
      );
    } else {
      AppSnackbar.error(
        context,
        provider.error ?? 'Gagal refresh harga.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PemakaianBbmProvider>();
    final master = context.watch<MasterDataProvider>();
    final user = context.watch<AuthProvider>().user;
    final canManageHarga = user?.canManageHarga ?? false;

    final kendaraanOptions = master.kendaraanList.where((kendaraan) {
      if (_jenisKendaraan == null) {
        return true;
      }

      return kendaraan.namaJenis == _jenisKendaraan;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Cari plat nomor atau tanggal...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                    });
                                    _load();
                                  },
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _showFilters
                            ? AppTheme.primary.withValues(alpha: 0.1)
                            : const Color(0xFFF8FAFC),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: IconButton(
                        tooltip: 'Filter',
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        icon: Icon(
                          _showFilters
                              ? Icons.filter_alt_off_outlined
                              : Icons.filter_alt_outlined,
                          color: _showFilters
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showFilters) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            'jenis-kendaraan-${_jenisKendaraan ?? 'all'}',
                          ),
                          initialValue: _jenisKendaraan,
                          isExpanded: true,
                          hint: const Text('Semua'),
                          decoration: const InputDecoration(
                            labelText: 'Jenis Kendaraan',
                            isDense: true,
                          ),
                          items: [
                            ...master.jenisKendaraanList.map(
                              (jenis) => DropdownMenuItem(
                                value: jenis,
                                child: Text(jenis),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _jenisKendaraan = value;
                              _kendaraanId = null;
                            });
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey(
                            'kendaraan-${_jenisKendaraan ?? 'all'}-${_kendaraanId ?? 'all'}',
                          ),
                          initialValue: _kendaraanId,
                          isExpanded: true,
                          hint: const Text('Semua'),
                          decoration: const InputDecoration(
                            labelText: 'Kendaraan',
                            isDense: true,
                          ),
                          items: [
                            ...kendaraanOptions.map(
                              (kendaraan) => DropdownMenuItem(
                                value: kendaraan.id,
                                child: Text(
                                  kendaraan.platNomor,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _kendaraanId = value;
                            });
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('jenis-bbm-${_jenisBbm ?? 'all'}'),
                          initialValue: _jenisBbm,
                          isExpanded: true,
                          hint: const Text('Semua'),
                          decoration: const InputDecoration(
                            labelText: 'Jenis BBM',
                            isDense: true,
                          ),
                          items: [
                            ...PemakaianBbm.jenisBbmLabels.entries.map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _jenisBbm = value;
                            });
                            _load();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            'lokasi-${_lokasiPembelian ?? 'all'}',
                          ),
                          initialValue: _lokasiPembelian,
                          isExpanded: true,
                          hint: const Text('Semua'),
                          decoration: const InputDecoration(
                            labelText: 'Lokasi',
                            isDense: true,
                          ),
                          items: [
                            ...PemakaianBbm.lokasiLabels.entries.map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _lokasiPembelian = value;
                            });
                            _load();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _resetFilter,
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text('Reset Filter'),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${provider.total} transaksi',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (canManageHarga)
                      OutlinedButton.icon(
                        onPressed: provider.isRefreshing ? null : _refreshHarga,
                        icon: provider.isRefreshing
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync, size: 16),
                        label: const Text('Refresh Harga'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(provider, user?.isAdmin ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PemakaianBbmProvider provider, bool isAdmin) {
    if (provider.isLoading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Belum ada data pemakaian',
                message:
                    'Tekan tombol Tambah untuk mencatat pemakaian BBM kendaraan.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: provider.items.length + (provider.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= provider.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: provider.isLoadingMore
                    ? const CircularProgressIndicator()
                    : OutlinedButton(
                        onPressed: () => _load(reset: false),
                        child: const Text('Muat lebih banyak'),
                      ),
              ),
            );
          }

          final item = provider.items[index];

          return _PemakaianCard(
            item: item,
            isAdmin: isAdmin,
            onEdit: () => _openForm(item),
            onDelete: () => _confirmDelete(item),
          );
        },
      ),
    );
  }
}

class _PemakaianCard extends StatelessWidget {
  final PemakaianBbm item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PemakaianCard({
    required this.item,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.platNomor,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        formatRupiah(item.jumlah),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatTanggal(item.tanggal)} • ${item.jenisBbmLabel} • ${item.lokasiLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _InfoPill(
                        label: 'Liter',
                        value: formatLiter(item.liter),
                      ),
                      _InfoPill(
                        label: 'Harga',
                        value: formatRupiah(item.rp),
                      ),
                      if (item.serviceOli > 0)
                        _InfoPill(
                          label: 'Sparepart',
                          value: formatRupiah(item.serviceOli),
                        ),
                      if (item.jasa > 0)
                        _InfoPill(
                          label: 'Jasa',
                          value: formatRupiah(item.jasa),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                if (isAdmin)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.error,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Hapus',
                          style: TextStyle(color: AppTheme.error),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
