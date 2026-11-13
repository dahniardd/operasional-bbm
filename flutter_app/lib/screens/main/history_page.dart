import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../utils/display_format.dart';
import '../../widgets/pln_header_shell.dart';
import '../../utils/formatters.dart';
import 'profile_screen.dart';

// ============================================================
// Helper format
// ============================================================

String _errorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'];
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi lalu coba lagi.';
    }
  }
  return 'Gagal memuat data. Coba lagi.';
}

TextStyle _poppins(double size, FontWeight w, Color c, {double? ls}) =>
    GoogleFonts.poppins(
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: ls,
    );

const _bgBiru = AppColors.primarySoft;
const _bgHijau = AppColors.successSoft;
const _bgKuning = AppColors.warningSoft;

// Warna teks untuk chip/kartu berlatar pastel. Warna status bawaan
// (success/warning/textSecondary) terlalu terang di atas latar ini:
//   success   di atas _bgHijau  = 3,03:1 -> _fgHijau  = 4,61:1
//   warning   di atas _bgKuning = 1,96:1 -> _fgKuning = 4,58:1
//   textSecondary di atas _bgBiru = 4,26:1 -> _fgAbu  = di atas 7:1
const _fgHijau = Color(0xFF15803D);
const _fgKuning = Color(0xFFB45309);
const _fgAbu = Color(0xFF475569);

// ============================================================
// Halaman Riwayat: dua slide (Saya / Driver lain)
// ============================================================

class HistoryPage extends StatefulWidget {
  /// Naikkan nilainya untuk memuat ulang kedua slide (dipakai MainShell).
  final int refreshTick;
  const HistoryPage({super.key, this.refreshTick = 0});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _controller = PageController();
  final _mineKey = GlobalKey<_PemakaianListState>();
  final _othersKey = GlobalKey<_PemakaianListState>();

  int _page = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _mineKey.currentState?.reload();
      _othersKey.currentState?.reload();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    try {
      final res = await ApiService().getUser();
      final role = res.data['user']?['role'];
      if (mounted) setState(() => _isAdmin = role == 'admin');
    } catch (_) {
      // Tanpa role, hanya tombol hapus yang disembunyikan.
    }
  }

  void _goTo(int i) {
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            PlnHeaderShell(
              onProfileTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: const PlnHeaderTitle(
                icon: Icons.history_rounded,
                title: 'Riwayat Pengisian',
                subtitle: 'Geser untuk melihat data driver lain',
              ),
            ),
            _SlideSwitch(page: _page, onTab: _goTo),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _PemakaianList(
                      key: _mineKey, scope: 'mine', isAdmin: _isAdmin),
                  _PemakaianList(
                      key: _othersKey, scope: 'others', isAdmin: _isAdmin),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Daftar pemakaian (dipakai kedua slide)
// ============================================================

class _PemakaianList extends StatefulWidget {
  /// 'mine' = milik user login, 'others' = driver lain (hanya lihat).
  final String scope;
  final bool isAdmin;
  const _PemakaianList({super.key, required this.scope, required this.isAdmin});

  @override
  State<_PemakaianList> createState() => _PemakaianListState();
}

class _PemakaianListState extends State<_PemakaianList>
    with AutomaticKeepAliveClientMixin {
  static const _filters = <(String, String?)>[
    ('Semua', null),
    ('Paiton', 'paiton'),
    ('Luar Paiton', 'luar_paiton'),
  ];

  /// Jumlah data per halaman.
  static const _perPage = 20;

  final _scroll = ScrollController();
  final _items = <Map<String, dynamic>>[];

  Timer? _debounce;
  String _search = '';
  String? _lokasi;
  int _page = 1;
  int _lastPage = 1;
  int _total = 0;
  double _totalRp = 0;
  double _totalLiter = 0;
  bool _loading = true;
  String? _error;

  /// Penanda permintaan terbaru: respons lama (mis. saat mengetik cepat atau
  /// ganti filter) diabaikan supaya tidak menimpa hasil yang lebih baru.
  int _reqId = 0;

  bool get _mine => widget.scope == 'mine';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Dipanggil dari luar (mis. setelah input baru), tetap di halaman sekarang
  /// tanpa menampilkan spinner.
  Future<void> reload() => _load(silent: true, page: _page);

  Future<Map<String, dynamic>> _fetch(int page) async {
    final res = await ApiService().getPemakaianBbm(
      search: _search,
      lokasiPembelian: _lokasi,
      scope: widget.scope,
      page: page,
      perPage: _perPage,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> _load({bool silent = false, int page = 1}) async {
    if (!silent || _items.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final req = ++_reqId;
    try {
      final body = await _fetch(page);
      if (req != _reqId) return;
      final data = (body['data'] as List).cast<Map<String, dynamic>>();
      final meta = body['meta'] as Map;

      // Kalau halaman ini kosong (mis. data terakhir di halaman ini baru
      // dihapus), mundur satu halaman.
      if (data.isEmpty && page > 1) {
        return _load(silent: silent, page: page - 1);
      }

      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(data);
        _page = page;
        _lastPage = (meta['last_page'] as num).toInt();
        _total = (meta['total'] as num).toInt();
        _totalRp = asDouble(meta['total_jumlah']);
        _totalLiter = asDouble(meta['total_liter']);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || req != _reqId) return;
      setState(() {
        _error = _errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _goToPage(int p) async {
    if (p < 1 || p > _lastPage || p == _page || _loading) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    await _load(page: p);
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search = v.trim();
      _load();
    });
  }

  void _snack(String msg, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _hapus(Map<String, dynamic> m) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus Transaksi',
            style: _poppins(16, FontWeight.w700, AppColors.textPrimary)),
        content: Text(
          'Pemakaian ${m['plat_nomor']} tanggal ${fmtTgl(m['tanggal'])} '
          '(${formatRupiah(asDouble(m['jumlah']))}) akan dihapus dan tidak bisa dikembalikan.',
          style: _poppins(13, FontWeight.w400, AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ya != true) return;

    try {
      await ApiService().deletePemakaianBbm(m['id'] as int);
      if (!mounted) return;
      _snack('Data dihapus.');
      _load(silent: true, page: _page);
    } catch (e) {
      if (!mounted) return;
      _snack(_errorMessage(e), color: AppColors.danger);
    }
  }

  void _detail(Map<String, dynamic> m) {
    final liter = asDouble(m['liter']);
    final rp = asDouble(m['rp']);
    final jumlah = asDouble(m['jumlah']);
    final paiton = m['lokasi_pembelian'] == 'paiton';
    final pencatat = (m['pencatat'] ?? '-').toString();
    final fotoUrl = (m['bukti_bbm_url'] ?? '').toString();
    final sub = [m['nama_jenis'], m['unit']]
        .where((e) => e != null && '$e'.isNotEmpty)
        .join(' • ');

    Widget chipGelap(IconData icon, String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(t, style: _poppins(12, FontWeight.w600, Colors.white)),
            ],
          ),
        );

    Widget baris(IconData icon, String label, String value,
        {Color? warnaNilai, bool redup = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: _poppins(
                      12, FontWeight.w500, AppColors.textSecondary)),
            ),
            Text(
              value,
              style: _poppins(
                13,
                FontWeight.w600,
                warnaNilai ??
                    (redup ? AppColors.textSecondary : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );
    }

    Widget kartu(String judul, List<Widget> isi) => Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul,
                  style: _poppins(
                      13, FontWeight.w700, AppColors.textPrimary)),
              const SizedBox(height: 4),
              ...isi,
            ],
          ),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Kepala: kendaraan
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.directions_car_filled_outlined,
                          color: AppColors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['plat_nomor'] ?? '-',
                              style: _poppins(
                                  20, FontWeight.w700, AppColors.textPrimary,
                                  ls: -0.4)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (sub.isNotEmpty)
                                Text(sub,
                                    style: _poppins(12, FontWeight.w400,
                                        AppColors.textSecondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: paiton ? _bgHijau : _bgKuning,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  fmtTitle(m['lokasi_pembelian']),
                                  style: _poppins(12,
                                      FontWeight.w600,
                                      paiton ? _fgHijau : _fgKuning),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol tutup (X) di ujung kanan atas
                    Material(
                      color: AppColors.background,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(sheetContext),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.close_rounded,
                              size: 20, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Total (sorotan utama)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.darkNavy],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Pengeluaran',
                          style: _poppins(
                              12,
                              FontWeight.w500,
                              Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 4),
                      Text(formatRupiah(jumlah),
                          style: _poppins(28, FontWeight.w800, Colors.white,
                              ls: -0.6)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          chipGelap(Icons.calendar_today_outlined,
                              fmtTgl(m['tanggal'])),
                          chipGelap(Icons.local_gas_station_outlined,
                              '${formatLiter(liter)} L'),
                          chipGelap(Icons.opacity_outlined,
                              fmtTitle(m['jenis_bbm'])),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Informasi pembelian
                kartu('Informasi Pembelian', [
                  baris(Icons.local_gas_station_outlined, 'Jenis BBM',
                      fmtTitle(m['jenis_bbm'])),
                  baris(Icons.place_outlined, 'Lokasi pembelian',
                      fmtTitle(m['lokasi_pembelian'])),
                  baris(Icons.water_drop_outlined, 'Volume',
                      '${formatLiter(liter)} L'),
                  if (liter > 0)
                    baris(Icons.speed_outlined, 'Rata-rata per liter',
                        formatRupiah(rp / liter)),
                  baris(Icons.receipt_long_outlined, 'Biaya BBM', formatRupiah(rp),
                      warnaNilai: AppColors.primary),
                ]),
                const SizedBox(height: 12),

                // Bukti foto struk
                kartu('Bukti Foto Struk', [
                  const SizedBox(height: 4),
                  _BuktiFoto(url: fotoUrl),
                ]),
                const SizedBox(height: 14),

                // Pencatat
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        pencatat.isEmpty ? '?' : pencatat[0].toUpperCase(),
                        style: _poppins(
                            13, FontWeight.w700, AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dicatat oleh',
                              style: _poppins(12, FontWeight.w400,
                                  AppColors.textSecondary)),
                          Text(
                            _mine ? '$pencatat (Anda)' : pencatat,
                            style: _poppins(
                                13, FontWeight.w600, AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (widget.isAdmin) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _hapus(m);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      label: Text('Hapus Data',
                          style: _poppins(13, FontWeight.w600, Colors.white)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // wajib untuk AutomaticKeepAliveClientMixin
    return RefreshIndicator(
      onRefresh: () => _load(silent: true, page: _page),
      color: AppColors.primary,
      backgroundColor: Colors.white,
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header()),
          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary, strokeWidth: 3),
                ),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(child: _errorBox())
          else if (_items.isEmpty)
            SliverToBoxAdapter(child: _emptyBox())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    if (i.isOdd) return const SizedBox(height: 12);
                    final m = _items[i ~/ 2];
                    return _Kartu(
                      m: m,
                      tampilkanPencatat: !_mine,
                      onTap: () => _detail(m),
                    );
                  },
                  childCount: _items.length * 2 - 1,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (!_loading && _error == null && _lastPage > 1)
                  _pagination(),
                // Ruang bawah supaya tidak tertutup navigasi melayang.
                const SizedBox(height: 130),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    final dari = (_page - 1) * _perPage + 1;
    final sampai = dari + _items.length - 1;

    Widget tombol(String label, IconData icon, bool aktif, VoidCallback onTap,
        {bool ikonKanan = false}) {
      final warna = aktif ? AppColors.primary : AppColors.border;
      return Expanded(
        child: GestureDetector(
          onTap: aktif ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: aktif ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: warna),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!ikonKanan)
                  Icon(icon,
                      size: 18,
                      color: aktif ? Colors.white : AppColors.border),
                if (!ikonKanan) const SizedBox(width: 4),
                Text(label,
                    style: _poppins(12, FontWeight.w600,
                        aktif ? Colors.white : AppColors.textSecondary)),
                if (ikonKanan) const SizedBox(width: 4),
                if (ikonKanan)
                  Icon(icon,
                      size: 18,
                      color: aktif ? Colors.white : AppColors.border),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Text('Menampilkan $dari–$sampai dari $_total transaksi',
              style: _poppins(12, FontWeight.w500, AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Halaman $_page dari $_lastPage',
              style: _poppins(12, FontWeight.w700, AppColors.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              tombol('Sebelumnya', Icons.chevron_left_rounded, _page > 1,
                  () => _goToPage(_page - 1)),
              const SizedBox(width: 12),
              tombol('Berikutnya', Icons.chevron_right_rounded,
                  _page < _lastPage, () => _goToPage(_page + 1),
                  ikonKanan: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: _onSearch,
            style: _poppins(14, FontWeight.w400, AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Cari plat nomor atau tanggal…',
              hintStyle:
                  _poppins(13, FontWeight.w400, AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (label, value) in _filters)
                  Builder(builder: (_) {
                    final aktif = _lokasi == value;
                    return GestureDetector(
                      onTap: () {
                        if (aktif) return;
                        setState(() => _lokasi = value);
                        _load();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                          color: aktif
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: aktif
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          label,
                          style: _poppins(
                            12,
                            FontWeight.w600,
                            aktif ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Ringkas(
                  label: 'Total Pengeluaran',
                  value: _loading ? '—' : formatRupiah(_totalRp),
                  note: _loading ? '' : '$_total transaksi',
                  icon: Icons.attach_money,
                  warna: AppColors.primary,
                  latar: _bgBiru,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Ringkas(
                  label: 'Total Liter',
                  value: _loading ? '—' : '${formatLiter(_totalLiter)} L',
                  note: _mine ? 'milik Anda' : 'hanya dilihat',
                  icon: Icons.local_gas_station,
                  warna: AppColors.success,
                  teks: _fgHijau,
                  latar: _bgHijau,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyBox() {
    final pesan = _search.isNotEmpty || _lokasi != null
        ? 'Tidak ada data yang cocok'
        : _mine
            ? 'Belum ada riwayat pengisian'
            : 'Belum ada data dari driver lain';
    final sub = _search.isNotEmpty || _lokasi != null
        ? 'Ubah kata kunci atau filter'
        : _mine
            ? 'Mulai dengan catat BBM untuk melihat riwayat'
            : 'Data akan muncul setelah driver lain mencatat';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            Text(pesan,
                textAlign: TextAlign.center,
                style:
                    _poppins(14, FontWeight.w500, AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style:
                    _poppins(12, FontWeight.w400, AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _errorBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 44, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style:
                    _poppins(13, FontWeight.w400, AppColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _load(page: _page),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Komponen tampilan
// ============================================================

class _Ringkas extends StatelessWidget {
  final String label, value, note;
  final IconData icon;
  final Color warna, latar;

  /// Warna teks catatan; kalau kosong memakai [warna].
  final Color? teks;
  const _Ringkas({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.warna,
    required this.latar,
    this.teks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: warna.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: warna),
          ),
          const SizedBox(height: 10),
          Text(label, style: _poppins(12, FontWeight.w500, _fgAbu)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: _poppins(16, FontWeight.w700, AppColors.textPrimary,
                    ls: -0.3)),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(note, style: _poppins(12, FontWeight.w500, teks ?? warna)),
          ],
        ],
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  final Map<String, dynamic> m;
  final bool tampilkanPencatat;
  final VoidCallback onTap;
  const _Kartu({
    required this.m,
    required this.tampilkanPencatat,
    required this.onTap,
  });

  Widget _chip(String t, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t, style: _poppins(12, FontWeight.w600, fg)),
      );

  Widget _chipFoto() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _bgBiru,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text('Foto',
                style: _poppins(12, FontWeight.w600, AppColors.primary)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final paiton = m['lokasi_pembelian'] == 'paiton';
    final pencatat = (m['pencatat'] ?? '-').toString();
    final adaFoto = (m['bukti_bbm_url'] ?? '').toString().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_gas_station,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['plat_nomor'] ?? '-',
                              style: _poppins(
                                  14, FontWeight.w600, AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(fmtTgl(m['tanggal']),
                              style: _poppins(12, FontWeight.w400,
                                  AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(formatRupiah(asDouble(m['jumlah'])),
                        style: _poppins(
                            14, FontWeight.w700, AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(fmtTitle(m['jenis_bbm']), AppColors.primary,
                        _bgBiru),
                    _chip(
                      fmtTitle(m['lokasi_pembelian']),
                      paiton ? _fgHijau : _fgKuning,
                      paiton ? _bgHijau : _bgKuning,
                    ),
                    _chip('${formatLiter(asDouble(m['liter']))} L',
                        _fgAbu, AppColors.background),
                    if (adaFoto) _chipFoto(),
                  ],
                ),
                if (tampilkanPencatat) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          pencatat.isEmpty ? '?' : pencatat[0].toUpperCase(),
                          style: _poppins(12, FontWeight.w700, AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Dicatat oleh $pencatat',
                            overflow: TextOverflow.ellipsis,
                            style: _poppins(12, FontWeight.w500, AppColors.textSecondary)),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ],
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

// ============================================================
// Foto bukti
// ============================================================

Widget _loadingFoto(BuildContext context, Widget child, ImageChunkEvent? p) {
  if (p == null) return child;
  final total = p.expectedTotalBytes;
  return Container(
    color: AppColors.surface,
    alignment: Alignment.center,
    child: CircularProgressIndicator(
      value: total != null ? p.cumulativeBytesLoaded / total : null,
      color: AppColors.primary,
      strokeWidth: 3,
    ),
  );
}

/// Foto struk di popup detail. Ketuk untuk membuka layar penuh.
class _BuktiFoto extends StatefulWidget {
  final String? url;
  const _BuktiFoto({required this.url});

  @override
  State<_BuktiFoto> createState() => _BuktiFotoState();
}

class _BuktiFotoState extends State<_BuktiFoto> {
  int _percobaan = 0;

  String get _src {
    final u = widget.url!;
    return _percobaan == 0 ? u : '$u${u.contains('?') ? '&' : '?'}r=$_percobaan';
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;

    if (url == null || url.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 30, color: AppColors.border),
            const SizedBox(height: 8),
            Text('Tidak ada foto bukti',
                style:
                    _poppins(12, FontWeight.w500, AppColors.textSecondary)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => _FotoViewer(url: _src),
            ),
          ),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                height: 220,
                child: Image.network(
                  _src,
                  fit: BoxFit.cover,
                  loadingBuilder: _loadingFoto,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surface,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            size: 36, color: AppColors.textSecondary),
                        const SizedBox(height: 8),
                        Text('Foto tidak dapat dimuat',
                            style: _poppins(12, FontWeight.w500,
                                AppColors.textSecondary)),
                        TextButton(
                          onPressed: () => setState(() => _percobaan++),
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_out_map_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text('Perbesar',
                          style: _poppins(12, FontWeight.w600, Colors.white)),
                    ],
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

/// Layar penuh: foto bisa dicubit untuk zoom dan digeser.
class _FotoViewer extends StatelessWidget {
  final String url;
  const _FotoViewer({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bukti Foto Struk',
            style: _poppins(15, FontWeight.w600, Colors.white)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, p) {
              if (p == null) return child;
              final total = p.expectedTotalBytes;
              return Center(
                child: CircularProgressIndicator(
                  value: total != null ? p.cumulativeBytesLoaded / total : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (_, __, ___) => Center(
              child: Text('Foto tidak dapat dimuat',
                  style: _poppins(13, FontWeight.w500, Colors.white70)),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Tombol geser: Riwayat Saya / Driver Lain (di bawah header)
// ============================================================

class _SlideSwitch extends StatelessWidget {
  final int page;
  final ValueChanged<int> onTab;
  const _SlideSwitch({required this.page, required this.onTab});

  Widget _tab(String label, IconData icon, int index) {
    final aktif = page == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: aktif
                ? LinearGradient(
                    colors: [AppColors.primary, AppColors.darkNavy],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: aktif
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: aktif ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: _poppins(13, FontWeight.w600,
                      aktif ? Colors.white : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _tab('Riwayat Saya', Icons.person_outline_rounded, 0),
            _tab('Driver Lain', Icons.groups_outlined, 1),
          ],
        ),
      ),
    );
  }
}