import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../config/design_tokens.dart';
import '../models/pemakaian_bbm.dart';

/// Kartu transaksi dengan detail yang dapat dibuka tanpa controller eksplisit.
class AdvancedTransactionCard extends StatefulWidget {
  final PemakaianBbm pemakaian;
  final bool isExpanded;

  const AdvancedTransactionCard({
    super.key,
    required this.pemakaian,
    this.isExpanded = false,
  });

  @override
  State<AdvancedTransactionCard> createState() =>
      _AdvancedTransactionCardState();
}

class _AdvancedTransactionCardState extends State<AdvancedTransactionCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
  }

  @override
  void didUpdateWidget(AdvancedTransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      _isExpanded = widget.isExpanded;
    }
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  String _formatBbmName(String jenisBbm) {
    switch (jenisBbm) {
      case 'pertamax':
        return 'Pertamax';
      case 'pertadex':
        return 'Pertadex';
      case 'dexlite':
        return 'Dexlite';
      case 'pertamax_turbo':
        return 'Pertamax Turbo';
      case 'solar':
        return 'Solar';
      default:
        return jenisBbm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.pemakaian;
    final price = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(tx.jumlah);
    final pricePerLiter = tx.liter > 0
        ? NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          ).format(tx.jumlah / tx.liter)
        : '-';

    return Semantics(
      button: true,
      label: 'Transaksi ${tx.platNomor}, $price',
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: AppTokens.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: AppTokens.space8,
              offset: const Offset(0, AppTokens.space2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTokens.brand.withValues(alpha: 0.1),
                              AppTokens.brand.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusMd,
                          ),
                        ),
                        child: const Icon(
                          Icons.local_gas_station,
                          color: AppTokens.brand,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppTokens.space12),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.platNomor,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTokens.space2),
                            Wrap(
                              spacing: AppTokens.space8,
                              runSpacing: AppTokens.space4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _buildMeta(
                                  Icons.calendar_today,
                                  DateFormat(
                                    'd MMM yyyy',
                                    'id_ID',
                                  ).format(tx.tanggal),
                                ),
                                _buildMeta(
                                  Icons.local_gas_station,
                                  '${tx.liter.toStringAsFixed(1)}L',
                                  color: AppTokens.brand,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTokens.space8),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              price,
                              textAlign: TextAlign.right,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTokens.brand,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppTokens.space2),
                            Icon(
                              _isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: AppTokens.textSecondary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: _isExpanded
                        ? Column(
                            children: [
                              const SizedBox(height: AppTokens.space12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTokens.space12,
                                  vertical: AppTokens.space2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTokens.background,
                                  borderRadius: BorderRadius.circular(
                                    AppTokens.radiusMd,
                                  ),
                                  border: Border.all(color: AppTokens.border),
                                ),
                                child: Column(
                                  children: [
                                    _buildDetailRow(
                                      'Jenis BBM',
                                      _formatBbmName(tx.jenisBbm),
                                      Icons.local_gas_station,
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: AppTokens.border,
                                    ),
                                    _buildDetailRow(
                                      'Jumlah',
                                      '${tx.liter.toStringAsFixed(1)} Liter',
                                      Icons.format_list_numbered,
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: AppTokens.border,
                                    ),
                                    _buildDetailRow(
                                      'Lokasi',
                                      tx.lokasiPembelian == 'paiton'
                                          ? 'Paiton'
                                          : 'Luar Paiton',
                                      Icons.location_on,
                                    ),
                                    const Divider(
                                      height: 1,
                                      color: AppTokens.border,
                                    ),
                                    _buildDetailRow(
                                      'Harga/Liter',
                                      pricePerLiter,
                                      Icons.price_check,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeta(
    IconData icon,
    String text, {
    Color color = AppTokens.textSecondary,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppTokens.fontCaption, color: color),
        const SizedBox(width: AppTokens.space4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: AppTokens.fontCaption,
            fontWeight: fontWeight,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space10),
      child: Row(
        children: [
          Icon(icon, size: AppTokens.fontBody, color: AppTokens.textSecondary),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: AppTokens.fontCaption,
                fontWeight: FontWeight.w500,
                color: AppTokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: AppTokens.fontCaption,
                fontWeight: FontWeight.w600,
                color: AppTokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
