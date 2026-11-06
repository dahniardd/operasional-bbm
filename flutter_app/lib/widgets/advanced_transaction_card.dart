import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/pln_colors.dart';
import '../models/pemakaian_bbm.dart';

/// Advanced Transaction Card dengan detail expandable
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

class _AdvancedTransactionCardState extends State<AdvancedTransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (_isExpanded) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AdvancedTransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      _isExpanded = widget.isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
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

    return Container(
      decoration: BoxDecoration(
        color: PlnColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PlnColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            PlnColors.primaryBlue.withValues(alpha: 0.1),
                            PlnColors.primaryBlue.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.local_gas_station,
                        color: PlnColors.primaryBlue,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.platNomor,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: PlnColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 12,
                                color: PlnColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat(
                                  'd MMM yyyy',
                                  'id_ID',
                                ).format(tx.tanggal),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: PlnColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 1,
                                height: 10,
                                color: PlnColors.border,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${tx.liter.toStringAsFixed(1)}L',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: PlnColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Amount dan expand icon
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: PlnColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: PlnColors.textSecondary,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
                // Expanded details
                SizeTransition(
                  sizeFactor: _expandAnimation,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PlnColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: PlnColors.border),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              'Jenis BBM',
                              _formatBbmName(tx.jenisBbm),
                              Icons.local_gas_station,
                            ),
                            const Divider(height: 1, color: PlnColors.border),
                            _buildDetailRow(
                              'Jumlah',
                              '${tx.liter.toStringAsFixed(1)} Liter',
                              Icons.format_list_numbered,
                            ),
                            const Divider(height: 1, color: PlnColors.border),
                            _buildDetailRow(
                              'Lokasi',
                              tx.lokasiPembelian == 'paiton'
                                  ? 'Paiton'
                                  : 'Luar Paiton',
                              Icons.location_on,
                            ),
                            const Divider(height: 1, color: PlnColors.border),
                            _buildDetailRow(
                              'Harga/Liter',
                              pricePerLiter,
                              Icons.price_check,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 14, color: PlnColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: PlnColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: PlnColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
