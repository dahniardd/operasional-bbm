import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/harga_bbm.dart';
import '../../providers/auth_provider.dart';
import '../../providers/harga_bbm_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import 'harga_form_screen.dart';

class HargaBbmListScreen extends StatefulWidget {
  const HargaBbmListScreen({super.key});

  @override
  State<HargaBbmListScreen> createState() => _HargaBbmListScreenState();
}

class _HargaBbmListScreenState extends State<HargaBbmListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HargaBbmProvider>();

      if (provider.hargaList.isEmpty) {
        provider.loadHargaBbm();
      } else if (provider.error != null) {
        provider.clearMessages();
      }
    });
  }

  Future<void> _openForm([HargaBbm? item]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => HargaBbmFormScreen(item: item),
      ),
    );

    if (changed != true || !mounted) {
      return;
    }

    final message = context.read<HargaBbmProvider>().successMessage;

    if (message != null) {
      AppSnackbar.success(context, message);
    }
  }

  Future<void> _confirmDelete(HargaBbm item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Harga BBM?'),
        content: Text(
          'Data harga BBM tanggal ${formatTanggal(item.tanggalBerlaku)} akan dihapus. Tindakan ini tidak dapat dibatalkan.',
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

    final provider = context.read<HargaBbmProvider>();
    final success = await provider.deleteHargaBbm(item.id);

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HargaBbmProvider>();
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.isAdmin ?? false;
    final canManage = user?.canManageHarga ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Harga'),
            )
          : null,
      body: _buildBody(provider, isAdmin, canManage),
    );
  }

  Widget _buildBody(
    HargaBbmProvider provider,
    bool isAdmin,
    bool canManage,
  ) {
    if (provider.isLoading && provider.hargaList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.hargaList.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.loadHargaBbm,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 360,
              child: EmptyState(
                icon: Icons.local_gas_station_outlined,
                title: 'Belum ada harga BBM',
                message: provider.error ??
                    'Tambahkan harga BBM terlebih dahulu agar transaksi pemakaian bisa dicatat.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadHargaBbm,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _LatestPriceCard(harga: provider.terakhir!),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Riwayat Harga BBM',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${provider.hargaList.length} data',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...provider.hargaList.map(
            (harga) => _HargaCard(
              harga: harga,
              isAdmin: isAdmin,
              canManage: canManage,
              onEdit: () => _openForm(harga),
              onDelete: () => _confirmDelete(harga),
            ),
          ),
        ],
      ),
    );
  }
}

class _LatestPriceCard extends StatelessWidget {
  final HargaBbm harga;

  const _LatestPriceCard({required this.harga});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harga Berlaku Terakhir',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Berlaku sejak ${formatTanggalPanjang(harga.tanggalBerlaku)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _LatestPriceTile(
                label: 'Pertamax',
                value: harga.hargaPertamax,
              ),
              _LatestPriceTile(
                label: 'Pertamax Turbo',
                value: harga.hargaPertamaxTurbo,
              ),
              _LatestPriceTile(
                label: 'Dexlite',
                value: harga.hargaDexlite,
              ),
              _LatestPriceTile(
                label: 'Pertadex',
                value: harga.hargaPertadex,
              ),
              _LatestPriceTile(
                label: 'Solar',
                value: harga.hargaSolar,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LatestPriceTile extends StatelessWidget {
  final String label;
  final double value;

  const _LatestPriceTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatRupiah(value),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HargaCard extends StatelessWidget {
  final HargaBbm harga;
  final bool isAdmin;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HargaCard({
    required this.harga,
    required this.isAdmin,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: const Color(0xFFE8EDF3)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_outlined,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formatTanggalPanjang(harga.tanggalBerlaku),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (harga.isDipakai) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.lock_outline,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _PriceChip(label: 'Pertamax', value: harga.hargaPertamax),
                    _PriceChip(
                      label: 'Turbo',
                      value: harga.hargaPertamaxTurbo,
                    ),
                    _PriceChip(label: 'Dexlite', value: harga.hargaDexlite),
                    _PriceChip(label: 'Pertadex', value: harga.hargaPertadex),
                    _PriceChip(label: 'Solar', value: harga.hargaSolar),
                  ],
                ),
              ],
            ),
          ),
          if (canManage)
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
                if (isAdmin && !harga.isDipakai)
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
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final double value;

  const _PriceChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE8EDF3)),
      ),
      child: Text(
        '$label ${formatRupiah(value)}',
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
