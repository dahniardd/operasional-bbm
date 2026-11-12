import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../config/design_tokens.dart';
import '../models/pemakaian_bbm.dart';

/// Grafik pemakaian BBM dengan filter periode dan metrik.
///
/// Ringkasan angka tidak ditampilkan di sini agar tidak duplikat dengan
/// kartu ringkasan server di dashboard.
class AdvancedChartWidget extends StatefulWidget {
  final List<PemakaianBbm> pemakaianList;

  const AdvancedChartWidget({super.key, required this.pemakaianList});

  @override
  State<AdvancedChartWidget> createState() => _AdvancedChartWidgetState();
}

class _AdvancedChartWidgetState extends State<AdvancedChartWidget>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = '7days'; // 7days, 30days, month
  String _selectedMetric = 'liter'; // liter, cost
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectPeriod(String value) {
    if (_selectedPeriod == value) return;
    setState(() => _selectedPeriod = value);
    _animationController.forward(from: 0);
  }

  void _selectMetric(String value) {
    if (_selectedMetric == value) return;
    setState(() => _selectedMetric = value);
    _animationController.forward(from: 0);
  }

  Map<String, dynamic> _calculateChartData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<PemakaianBbm> filteredData = [];
    String periodLabel = '';

    switch (_selectedPeriod) {
      case '7days':
        final start = today.subtract(const Duration(days: 6));
        filteredData = widget.pemakaianList
            .where((item) => !_dateOnly(item.tanggal).isBefore(start))
            .toList();
        periodLabel = 'Terakhir 7 Hari';
        break;
      case '30days':
        final start = today.subtract(const Duration(days: 29));
        filteredData = widget.pemakaianList
            .where((item) => !_dateOnly(item.tanggal).isBefore(start))
            .toList();
        periodLabel = 'Terakhir 30 Hari';
        break;
      case 'month':
        filteredData = widget.pemakaianList
            .where(
              (item) =>
                  item.tanggal.year == now.year &&
                  item.tanggal.month == now.month,
            )
            .toList();
        periodLabel = 'Bulan ${DateFormat('MMMM', 'id_ID').format(now)}';
        break;
    }

    return {'data': filteredData, 'periodLabel': periodLabel};
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<_BarData> _buildBars(List<PemakaianBbm> data) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bars = <_BarData>[];

    double sumBetween(DateTime start, DateTime endExclusive) {
      var sum = 0.0;
      for (final item in data) {
        final date = _dateOnly(item.tanggal);
        if (!date.isBefore(start) && date.isBefore(endExclusive)) {
          sum += _selectedMetric == 'liter' ? item.liter : item.jumlah;
        }
      }
      return sum;
    }

    if (_selectedPeriod == '7days') {
      for (var i = 6; i >= 0; i--) {
        final start = today.subtract(Duration(days: i));
        final end = start.add(const Duration(days: 1));
        bars.add(
          _BarData(
            DateFormat('E', 'id_ID').format(start),
            sumBetween(start, end),
          ),
        );
      }
      return bars;
    }

    if (_selectedPeriod == '30days') {
      final start = today.subtract(const Duration(days: 29));
      for (var i = 0; i < 5; i++) {
        final bucketStart = start.add(Duration(days: i * 6));
        final bucketEnd = bucketStart.add(const Duration(days: 6));
        bars.add(
          _BarData(
            DateFormat('d/M', 'id_ID').format(bucketStart),
            sumBetween(bucketStart, bucketEnd),
          ),
        );
      }
      return bars;
    }

    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    var bucketStart = monthStart;
    var week = 1;
    while (bucketStart.isBefore(nextMonth)) {
      final bucketEnd = bucketStart.add(const Duration(days: 7));
      final cappedEnd = bucketEnd.isAfter(nextMonth) ? nextMonth : bucketEnd;
      bars.add(_BarData('M$week', sumBetween(bucketStart, cappedEnd)));
      bucketStart = cappedEnd;
      week++;
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _calculateChartData();
    final data = chartData['data'] as List<PemakaianBbm>;
    final periodLabel = chartData['periodLabel'] as String;
    final bars = _buildBars(data);
    final hasAnyData = widget.pemakaianList.isNotEmpty;
    final hasPeriodData = bars.any((bar) => bar.value > 0);
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.6).toDouble();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(color: AppTokens.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: AppTokens.space10,
              offset: const Offset(0, AppTokens.space4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Grafik Pemakaian BBM',
                          style: GoogleFonts.poppins(
                            fontSize: AppTokens.fontTitle,
                            fontWeight: FontWeight.w700,
                            color: AppTokens.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppTokens.space2),
                        Text(
                          '$periodLabel • ${_selectedMetric == 'liter' ? 'Liter' : 'Rupiah'}',
                          style: GoogleFonts.poppins(
                            fontSize: AppTokens.fontCaption,
                            fontWeight: FontWeight.w500,
                            color: AppTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppTokens.space8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTokens.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppTokens.brand,
                      size: 20,
                    ),
                  ),
                ],
              ),
              if (hasAnyData) ...[
                const SizedBox(height: AppTokens.space14),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTokens.background,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Row(
                    children: [
                      _buildPeriodButton('7 Hari', '7days'),
                      const SizedBox(width: 3),
                      _buildPeriodButton('30 Hari', '30days'),
                      const SizedBox(width: 3),
                      _buildPeriodButton('Bulan Ini', 'month'),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space10),
                Text(
                  'Tampilkan',
                  style: GoogleFonts.poppins(
                    fontSize: AppTokens.fontCaption,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTokens.space6),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppTokens.background,
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildMetricButton('Liter', 'liter')),
                      const SizedBox(width: 2),
                      Expanded(child: _buildMetricButton('Rupiah', 'cost')),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space12),
              ] else
                const SizedBox(height: AppTokens.space14),
              if (!hasPeriodData)
                _buildEmptyState(hasAnyData)
              else
                _buildBarChart(bars, textScale),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool hasAnyData) {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart_outlined,
            size: 40,
            color: AppTokens.border,
          ),
          const SizedBox(height: AppTokens.space10),
          Text(
            hasAnyData
                ? 'Belum ada data pada periode ini'
                : 'Belum ada data pemakaian BBM',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppTokens.fontBody,
              fontWeight: FontWeight.w600,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            hasAnyData
                ? 'Coba pilih periode lain atau catat transaksi baru.'
                : 'Grafik akan muncul setelah ada transaksi tercatat.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppTokens.fontCaption,
              color: AppTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPeriod(value),
          borderRadius: BorderRadius.circular(AppTokens.space6),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: AppTokens.minTapTarget,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space4,
              vertical: AppTokens.space6,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppTokens.brand : Colors.transparent,
              borderRadius: BorderRadius.circular(AppTokens.space6),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: AppTokens.fontCaption,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppTokens.onBrand : AppTokens.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricButton(String label, String value) {
    final isSelected = _selectedMetric == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectMetric(value),
        borderRadius: BorderRadius.circular(AppTokens.space6),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppTokens.minTapTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space12,
            vertical: AppTokens.space6,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTokens.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.space6),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: AppTokens.fontCaption,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTokens.onBrand : AppTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<_BarData> bars, double textScale) {
    var maxValue = 0.0;
    for (final bar in bars) {
      if (bar.value > maxValue) maxValue = bar.value;
    }
    if (maxValue <= 0) maxValue = 1;

    final labelHeight = 18 * textScale;
    final valueHeight = 18 * textScale;
    final barArea = 96 * textScale;
    final chartHeight = labelHeight + valueHeight + barArea + 10;

    return SizedBox(
      height: chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final ratio = (bar.value / maxValue).clamp(0.0, 1.0);
          final isMax = bar.value > 0 && bar.value == maxValue;
          final gap = bars.length > 5 ? 3.0 : 6.0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gap),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: valueHeight,
                    child: isMax
                        ? Text(
                            _compactValue(bar.value),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: AppTokens.fontCaption,
                              fontWeight: FontWeight.w600,
                              color: AppTokens.brand,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Container(
                    height: (barArea * ratio)
                        .clamp(bar.value > 0 ? 3.0 : 0.0, barArea)
                        .toDouble(),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTokens.brand,
                          AppTokens.brand.withValues(alpha: isMax ? 0.7 : 0.45),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTokens.space6),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space6),
                  SizedBox(
                    height: labelHeight,
                    child: Text(
                      bar.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: AppTokens.fontCaption,
                        fontWeight: FontWeight.w500,
                        color: AppTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _compactValue(double value) {
    if (value <= 0) return '0';

    if (_selectedMetric == 'cost') {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}jt';
      }
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(0)}rb';
      }
      return value.toStringAsFixed(0);
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}rb';
    }
    return value.toStringAsFixed(value >= 10 ? 0 : 1);
  }
}

class _BarData {
  final String label;
  final double value;

  const _BarData(this.label, this.value);
}
