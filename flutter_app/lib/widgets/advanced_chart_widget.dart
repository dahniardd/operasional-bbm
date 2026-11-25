import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../config/design_tokens.dart';
import '../models/jenis_bbm_usage.dart';
import '../services/api_service.dart';
import '../utils/api_error.dart';
import 'app_date_picker.dart';

typedef JenisBbmUsageLoader =
    Future<List<JenisBbmUsage>> Function(DateTime dari, DateTime sampai);

class AdvancedChartWidget extends StatefulWidget {
  final int refreshSignal;
  final JenisBbmUsageLoader? loader;
  final DateTimeRange? initialDateRange;

  const AdvancedChartWidget({
    super.key,
    this.refreshSignal = 0,
    this.loader,
    this.initialDateRange,
  });

  @override
  State<AdvancedChartWidget> createState() => _AdvancedChartWidgetState();
}

class _AdvancedChartWidgetState extends State<AdvancedChartWidget> {
  static const Map<String, Color> _barColors = {
    'pertamax': AppTokens.brand,
    'pertadex': AppTokens.accent,
    'dexlite': AppTokens.success,
    'pertamax_turbo': Color(0xFF7C3AED),
    'solar': AppTokens.warning,
  };

  static const Map<String, String> _shortLabels = {
    'pertamax': 'Pertamax',
    'pertadex': 'Pertadex',
    'dexlite': 'Dexlite',
    'pertamax_turbo': 'P. Turbo',
    'solar': 'Solar',
  };

  late DateTimeRange _range;
  late JenisBbmUsageLoader _loader;

  String _selectedMetric = 'liter';
  List<JenisBbmUsage> _items = [];
  bool _isLoading = true;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _range = widget.initialDateRange ?? _defaultRange();
    _loader = widget.loader ?? _fetchFromApi;
    _load();
  }

  @override
  void didUpdateWidget(covariant AdvancedChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _load();
    }
  }

  DateTimeRange _defaultRange() {
    final now = DateTime.now();
    return DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateUtils.dateOnly(now),
    );
  }

  Future<List<JenisBbmUsage>> _fetchFromApi(
    DateTime dari,
    DateTime sampai,
  ) async {
    final res = await ApiService().getGrafikJenisBbm(
      dari: dari,
      sampai: sampai,
    );
    final data = Map<String, dynamic>.from(
      (res.data['data'] as Map?) ?? const {},
    );
    final items = (data['items'] as List?) ?? const [];

    return items
        .map(
          (item) =>
              JenisBbmUsage.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<void> _load() async {
    final requestId = ++_requestId;

    if (_isLoading && _error == null) {
      _error = null;
    } else {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final items = await _loader(_range.start, _range.end);
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _error = parseApiError(e, 'Gagal memuat grafik pemakaian BBM.');
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        _error = 'Gagal memuat grafik pemakaian BBM.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showAppDatePicker(
      context,
      initialDate: _range.start,
      firstDate: DateTime(2020),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );

    if (!mounted || picked == null) return;

    final start = DateUtils.dateOnly(picked);
    setState(() {
      _range = DateTimeRange(
        start: start,
        end: start.isAfter(_range.end) ? start : _range.end,
      );
    });
    _load();
  }

  Future<void> _pickEndDate() async {
    final picked = await showAppDatePicker(
      context,
      initialDate: _range.end,
      firstDate: DateTime(2020),
      lastDate: DateUtils.dateOnly(DateTime.now()),
    );

    if (!mounted || picked == null) return;

    final end = DateUtils.dateOnly(picked);
    setState(() {
      _range = DateTimeRange(
        start: end.isBefore(_range.start) ? end : _range.start,
        end: end,
      );
    });
    _load();
  }

  void _selectMetric(String value) {
    if (_selectedMetric == value) return;
    setState(() => _selectedMetric = value);
  }

  double _valueOf(JenisBbmUsage item) =>
      _selectedMetric == 'liter' ? item.liter : item.jumlah;

  String _formatDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'id_ID').format(date);
  }

  String _barLabel(JenisBbmUsage item) {
    return _shortLabels[item.jenisBbm] ?? item.label;
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 1.6).toDouble();
    final bars = _items;

    return Container(
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
            _buildHeader(),
            const SizedBox(height: AppTokens.space12),
            _buildFilterRow(),
            const SizedBox(height: AppTokens.space12),
            if (_isLoading)
              _buildLoadingState()
            else if (_error != null)
              _buildErrorState()
            else if (bars.isEmpty)
              _buildEmptyState()
            else
              _buildBarChart(bars, textScale),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Grafik Pemakaian BBM',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: AppTokens.fontTitle,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              Text(
                'Total per jenis BBM • '
                '${_selectedMetric == 'liter' ? 'Liter' : 'Rupiah'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildFilterRow() {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Dari',
                  date: _range.start,
                  onTap: _pickStartDate,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space6,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppTokens.textSecondary,
                ),
              ),
              Expanded(
                child: _buildDateField(
                  label: 'Sampai',
                  date: _range.end,
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space6),
          Align(alignment: Alignment.centerRight, child: _buildMetricToggle()),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space6,
            vertical: AppTokens.space6,
          ),
          decoration: BoxDecoration(
            color: AppTokens.background,
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            border: Border.all(color: AppTokens.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                size: 14,
                color: AppTokens.brand,
              ),
              const SizedBox(width: AppTokens.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                        color: AppTokens.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatDate(date),
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: AppTokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricToggle() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTokens.background,
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        border: Border.all(color: AppTokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMetricButton('Liter', 'liter'),
          const SizedBox(width: 2),
          _buildMetricButton('Rupiah', 'cost'),
        ],
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
          constraints: const BoxConstraints(minHeight: 30),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space8,
            vertical: AppTokens.space4,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppTokens.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTokens.space6),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTokens.onBrand : AppTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 168,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: AppTokens.brand,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 168,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 36,
            color: AppTokens.border,
          ),
          const SizedBox(height: AppTokens.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space12),
            child: Text(
              _error ?? 'Gagal memuat grafik.',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: AppTokens.fontCaption,
                color: AppTokens.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space8),
          SizedBox(
            height: 32,
            child: OutlinedButton.icon(
              onPressed: _load,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTokens.brand,
                side: const BorderSide(color: AppTokens.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text('Coba Lagi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 168,
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
            'Belum ada data pada rentang ini',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: AppTokens.fontBody,
              fontWeight: FontWeight.w600,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            'Coba pilih rentang tanggal lain.',
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

  Widget _buildBarChart(List<JenisBbmUsage> bars, double textScale) {
    var maxValue = 0.0;
    for (final item in bars) {
      final value = _valueOf(item);
      if (value > maxValue) maxValue = value;
    }
    if (maxValue <= 0) maxValue = 1;

    final valueHeight = 18 * textScale;
    final labelHeight = 30 * textScale;
    final barArea = 104 * textScale;
    final chartHeight =
        valueHeight +
        AppTokens.space4 +
        barArea +
        AppTokens.space6 +
        labelHeight;

    return SizedBox(
      height: chartHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((item) {
          final value = _valueOf(item);
          final ratio = (value / maxValue).clamp(0.0, 1.0);
          final color = _barColors[item.jenisBbm] ?? AppTokens.brand;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: valueHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _compactValue(value),
                        maxLines: 1,
                        style: GoogleFonts.poppins(
                          fontSize: AppTokens.fontCaption,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Container(
                    height: value > 0
                        ? (barArea * ratio).clamp(3.0, barArea).toDouble()
                        : 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: value > 0
                          ? LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [color, color.withValues(alpha: 0.55)],
                            )
                          : null,
                      color: value > 0 ? null : AppTokens.border,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTokens.space6),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTokens.space6),
                  SizedBox(
                    height: labelHeight,
                    child: Center(
                      child: Text(
                        _barLabel(item),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: AppTokens.fontCaption,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                          color: AppTokens.textSecondary,
                        ),
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
