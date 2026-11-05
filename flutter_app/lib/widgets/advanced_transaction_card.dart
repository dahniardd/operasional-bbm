import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/pln_colors.dart';
import '../models/pemakaian_bbm.dart';

/// Advanced Transaction Card dengan swipe action dan detail expandable
class AdvancedTransactionCard extends StatefulWidget {
  final PemakaianBbm pemakaian;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isExpanded;

  const AdvancedTransactionCard({
    super.key,
    required this.pemakaian,
    this.onEdit,
    this.onDelete,
    this.isExpanded = false,
  });

  @override
  State<AdvancedTransactionCard> createState() => _AdvancedTransactionCardState();
}

class _AdvancedTransactionCardState extends State<AdvancedTransactionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.isExpanded) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AdvancedTransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
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

    return Column(
      children: [
        // Main card
        Container(
          decoration: BoxDecoration(
            color: PlnColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: PlnColors.border,
              width: 1,
            ),
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
              onTap: () {
                setState(() {
                  if (widget.isExpanded) {
                    _controller.reverse();
                  } else {
                    _controller.forward();
                  }
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header row
                    Row(
                      children: [
                        // Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                PlnColors.primaryBlue.withValues(alpha: 0.1),
                                PlnColors.primaryBlue.withValues(alpha: 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.local_gas_station,
                            color: PlnColors.primaryBlue,
                            size: 24,
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
                                    DateFormat('d MMM yyyy', 'id_ID').format(tx.tanggal),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: PlnColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 1,
                                    height: 12,
                                    color: PlnColors.border,
                                  ),
                                  const SizedBox(width: 12),
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
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: PlnColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              widget.isExpanded ? Icons.expand_less : Icons.expand_more,
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
                          const SizedBox(height: 16),
                          Divider(
                            color: PlnColors.border,
                            height: 1,
                          ),
                          const SizedBox(height: 16),
                          // Details grid
                          GridView.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildDetailItem(
                                'Jenis BBM',
                                _formatBbmName(tx.jenisBbm),
                                Icons.local_gas_station,
                              ),
                              _buildDetailItem(
                                'Jumlah',
                                '${tx.liter.toStringAsFixed(1)} Liter',
                                Icons.format_list_numbered,
                              ),
                              _buildDetailItem(
                                'Lokasi',
                                tx.lokasiPembelian == 'paiton' ? 'Paiton' : 'Luar Paiton',
                                Icons.location_on,
                              ),
                              _buildDetailItem(
                                'Harga/Liter',
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(tx.jumlah / tx.liter),
                                Icons.price_check,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  'Edit',
                                  Icons.edit_outlined,
                                  PlnColors.primaryBlue,
                                  widget.onEdit,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildActionButton(
                                  'Hapus',
                                  Icons.delete_outlined,
                                  PlnColors.danger,
                                  widget.onDelete,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PlnColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PlnColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: PlnColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: PlnColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: PlnColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
