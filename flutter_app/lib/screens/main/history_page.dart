import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/pln_colors.dart';
import '../../services/api_service.dart';
import 'profile_screen.dart';

// ============================================================
// Helper format
// ============================================================

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _rp(num v) {
  final s = v.round().abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}Rp $b';
}

String _liter(num v) => v.toStringAsFixed(2).replaceAll('.', ',');

/// '2026-09-14' -> '14 Sep 2026'
/// Aman terhadap nilai kosong (null) dari API: tampil '-'.
String _tgl(dynamic value) {
  final raw = (value ?? '').toString();
  if (raw.isEmpty) return '-';
  final iso = raw.length >= 10 ? raw.substring(0, 10) : raw;
  final p = iso.split('-');
  if (p.length != 3) return raw;
  final m = int.tryParse(p[1]) ?? 0;
  if (m < 1 || m > 12) return raw;
  return '${int.tryParse(p[2]) ?? p[2]} ${_bulan[m - 1]} ${p[0]}';
}

/// 'luar_paiton' -> 'Luar Paiton'. Nilai kosong (null) tampil '-'.
String _title(dynamic value) {
  final s = (value ?? '').toString();
  if (s.isEmpty) return '-';
  return s
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

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

const _bgBiru = Color(0xFFE8F4FF);
const _bgHijau = Color(0xFFE8F9F5);
const _bgKuning = Color(0xFFFEF3E2);

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
        color: PlnColors.background,
        child: Column(
          children: [
            _RiwayatHeader(
              onProfileTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
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
  bool _loadingMore = false;
  String? _error;

  bool get _mine => widget.scope == 'mine';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients &&
          _scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
        _loadMore();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  /// Dipanggil dari luar (mis. setelah input baru) tanpa menampilkan spinner.
  Future<void> reload() => _load(silent: true);

  Future<Map<String, dynamic>> _fetch(int page) async {
    final res = await ApiService().getPemakaianBbm(
      search: _search,
      lokasiPembelian: _lokasi,
      scope: widget.scope,
      page: page,
      perPage: 20,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent || _items.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final body = await _fetch(1);
      final data = (body['data'] as List).cast<Map<String, dynamic>>();
      final meta = body['meta'] as Map;
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(data);
        _page = 1;
        _lastPage = (meta['last_page'] as num).toInt();
        _total = (meta['total'] as num).toInt();
        _totalRp = ((meta['total_jumlah'] ?? 0) as num).toDouble();
        _totalLiter = ((meta['total_liter'] ?? 0) as num).toDouble();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _errorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || _page >= _lastPage) return;
    setState(() => _loadingMore = true);
    try {
      final body = await _fetch(_page + 1);
      final data = (body['data'] as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _items.addAll(data);
        _page += 1;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
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
        title: Text('Hapus Transaksi', style: _poppins(16, FontWeight.w700, PlnColors.textPrimary)),
        content: Text(
          'Pemakaian ${m['plat_nomor']} tanggal ${_tgl(m['tanggal'])} '
          '(${_rp(m['jumlah'] as num)}) akan dihapus dan tidak bisa dikembalikan.',
          style: _poppins(13, FontWeight.w400, PlnColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus',
                style: TextStyle(color: PlnColors.danger)),
          ),
        ],
      ),
    );
    if (ya != true) return;

    try {
      await ApiService().deletePemakaianBbm(m['id'] as int);
      if (!mounted) return;
      _snack('Data dihapus.');
      _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      _snack(_errorMessage(e), color: PlnColors.danger);
    }
  }

  void _detail(Map<String, dynamic> m) {
    final liter = (m['liter'] as num).toDouble();
    final rp = (m['rp'] as num).toDouble();
    final jumlah = (m['jumlah'] as num).toDouble();
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
                color: PlnColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: PlnColors.primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: _poppins(
                      12, FontWeight.w500, PlnColors.textSecondary)),
            ),
            Text(
              value,
              style: _poppins(
                13,
                FontWeight.w600,
                warnaNilai ??
                    (redup ? PlnColors.textSecondary : PlnColors.textPrimary),
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
            color: PlnColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PlnColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul,
                  style: _poppins(
                      13, FontWeight.w700, PlnColors.textPrimary)),
              const SizedBox(height: 4),
              ...isi,
            ],
          ),
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: PlnColors.surface,
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
                      color: PlnColors.border,
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
                        color: PlnColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.directions_car_filled_outlined,
                          color: PlnColors.primaryBlue, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['plat_nomor'] ?? '-',
                              style: _poppins(
                                  20, FontWeight.w700, PlnColors.textPrimary,
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
                                        PlnColors.textSecondary)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: paiton ? _bgHijau : _bgKuning,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _title(m['lokasi_pembelian']),
                                  style: _poppins(
                                      11,
                                      FontWeight.w600,
                                      paiton
                                          ? PlnColors.success
                                          : PlnColors.warning),
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
                      color: PlnColors.background,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(sheetContext),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.close_rounded,
                              size: 20, color: PlnColors.textSecondary),
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
                      colors: [PlnColors.primaryBlue, PlnColors.darkNavy],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: PlnColors.primaryBlue.withValues(alpha: 0.28),
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
                      Text(_rp(jumlah),
                          style: _poppins(28, FontWeight.w800, Colors.white,
                              ls: -0.6)),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          chipGelap(Icons.calendar_today_outlined,
                              _tgl(m['tanggal'])),
                          chipGelap(Icons.local_gas_station_outlined,
                              '${_liter(liter)} L'),
                          chipGelap(Icons.opacity_outlined,
                              _title(m['jenis_bbm'])),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Informasi pembelian
                kartu('Informasi Pembelian', [
                  baris(Icons.local_gas_station_outlined, 'Jenis BBM',
                      _title(m['jenis_bbm'])),
                  baris(Icons.place_outlined, 'Lokasi pembelian',
                      _title(m['lokasi_pembelian'])),
                  baris(Icons.water_drop_outlined, 'Volume',
                      '${_liter(liter)} L'),
                  if (liter > 0)
                    baris(Icons.speed_outlined, 'Rata-rata per liter',
                        _rp(rp / liter)),
                  baris(Icons.receipt_long_outlined, 'Biaya BBM', _rp(rp),
                      warnaNilai: PlnColors.primaryBlue),
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
                          PlnColors.primaryBlue.withValues(alpha: 0.12),
                      child: Text(
                        pencatat.isEmpty ? '?' : pencatat[0].toUpperCase(),
                        style: _poppins(
                            13, FontWeight.w700, PlnColors.primaryBlue),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dicatat oleh',
                              style: _poppins(10, FontWeight.w400,
                                  PlnColors.textSecondary)),
                          Text(
                            _mine ? '$pencatat (Anda)' : pencatat,
                            style: _poppins(
                                13, FontWeight.w600, PlnColors.textPrimary),
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
                        backgroundColor: PlnColors.danger,
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
      onRefresh: () => _load(silent: true),
      color: PlnColors.primaryBlue,
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
                      color: PlnColors.primaryBlue, strokeWidth: 3),
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
            child: _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: PlnColors.primaryBlue, strokeWidth: 3),
                    ),
                  )
                // Ruang bawah supaya tidak tertutup navigasi melayang.
                : const SizedBox(height: 130),
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
            style: _poppins(14, FontWeight.w400, PlnColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Cari plat nomor atau tanggal…',
              hintStyle:
                  _poppins(13, FontWeight.w400, PlnColors.textSecondary),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: PlnColors.textSecondary),
              filled: true,
              fillColor: PlnColors.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PlnColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PlnColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, value) = _filters[i];
                final aktif = _lokasi == value;
                return GestureDetector(
                  onTap: () {
                    if (aktif) return;
                    setState(() => _lokasi = value);
                    _load();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: aktif ? PlnColors.primaryBlue : PlnColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            aktif ? PlnColors.primaryBlue : PlnColors.border,
                      ),
                    ),
                    child: Text(label,
                        style: _poppins(
                            12,
                            FontWeight.w600,
                            aktif ? Colors.white : PlnColors.textSecondary)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Ringkas(
                  label: 'Total Pengeluaran',
                  value: _loading ? '—' : _rp(_totalRp),
                  note: _loading ? '' : '$_total transaksi',
                  icon: Icons.attach_money,
                  warna: PlnColors.primaryBlue,
                  latar: _bgBiru,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Ringkas(
                  label: 'Total Liter',
                  value: _loading ? '—' : '${_totalLiter.toStringAsFixed(1).replaceAll('.', ',')} L',
                  note: _mine ? 'milik Anda' : 'hanya dilihat',
                  icon: Icons.local_gas_station,
                  warna: PlnColors.success,
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
          color: PlnColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PlnColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: PlnColors.border),
            const SizedBox(height: 12),
            Text(pesan,
                textAlign: TextAlign.center,
                style:
                    _poppins(14, FontWeight.w500, PlnColors.textSecondary)),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style:
                    _poppins(12, FontWeight.w400, PlnColors.textSecondary)),
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
          color: PlnColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PlnColors.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 44, color: PlnColors.danger),
            const SizedBox(height: 12),
            Text(_error!,
                textAlign: TextAlign.center,
                style:
                    _poppins(13, FontWeight.w400, PlnColors.textSecondary)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(
                  backgroundColor: PlnColors.primaryBlue),
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
  const _Ringkas({
    required this.label,
    required this.value,
    required this.note,
    required this.icon,
    required this.warna,
    required this.latar,
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
          Text(label,
              style: _poppins(11, FontWeight.w500, PlnColors.textSecondary)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: _poppins(16, FontWeight.w700, PlnColors.textPrimary,
                    ls: -0.3)),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(note, style: _poppins(11, FontWeight.w500, warna)),
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
        child: Text(t, style: _poppins(11, FontWeight.w600, fg)),
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
            Icon(Icons.image_outlined, size: 13, color: PlnColors.primaryBlue),
            const SizedBox(width: 4),
            Text('Foto',
                style: _poppins(11, FontWeight.w600, PlnColors.primaryBlue)),
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
        color: PlnColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PlnColors.border),
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
                        color: PlnColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_gas_station,
                          color: PlnColors.primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['plat_nomor'] ?? '-',
                              style: _poppins(
                                  14, FontWeight.w600, PlnColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(_tgl(m['tanggal']),
                              style: _poppins(11, FontWeight.w400,
                                  PlnColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(_rp(m['jumlah'] as num),
                        style: _poppins(
                            14, FontWeight.w700, PlnColors.primaryBlue)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(_title(m['jenis_bbm']), PlnColors.primaryBlue,
                        _bgBiru),
                    _chip(
                      _title(m['lokasi_pembelian']),
                      paiton ? PlnColors.success : PlnColors.warning,
                      paiton ? _bgHijau : _bgKuning,
                    ),
                    _chip('${_liter(m['liter'] as num)} L',
                        PlnColors.textSecondary, PlnColors.background),
                    if (adaFoto) _chipFoto(),
                  ],
                ),
                if (tampilkanPencatat) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: PlnColors.border),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor:
                            PlnColors.primaryBlue.withValues(alpha: 0.12),
                        child: Text(
                          pencatat.isEmpty ? '?' : pencatat[0].toUpperCase(),
                          style: _poppins(
                              11, FontWeight.w700, PlnColors.primaryBlue),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Dicatat oleh $pencatat',
                            overflow: TextOverflow.ellipsis,
                            style: _poppins(
                                11, FontWeight.w500, PlnColors.textSecondary)),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          size: 18, color: PlnColors.textSecondary),
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
    color: PlnColors.surface,
    alignment: Alignment.center,
    child: CircularProgressIndicator(
      value: total != null ? p.cumulativeBytesLoaded / total : null,
      color: PlnColors.primaryBlue,
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
          color: PlnColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PlnColors.border),
        ),
        child: Column(
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 30, color: PlnColors.border),
            const SizedBox(height: 8),
            Text('Tidak ada foto bukti',
                style:
                    _poppins(12, FontWeight.w500, PlnColors.textSecondary)),
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
                    color: PlnColors.surface,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_outlined,
                            size: 36, color: PlnColors.textSecondary),
                        const SizedBox(height: 8),
                        Text('Foto tidak dapat dimuat',
                            style: _poppins(12, FontWeight.w500,
                                PlnColors.textSecondary)),
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
                          style: _poppins(11, FontWeight.w600, Colors.white)),
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
// Header Riwayat (gaya sama dengan header Dashboard)
// ============================================================

class _RiwayatHeader extends StatelessWidget {
  final VoidCallback onProfileTap;

  const _RiwayatHeader({required this.onProfileTap});

  Widget _tombolProfil() {
    return Tooltip(
      message: 'Profil',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PlnColors.primaryBlue, PlnColors.darkNavy],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: PlnColors.primaryBlue.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Hiasan lingkaran (sama dengan Dashboard)
          Positioned(
            right: -24,
            top: -28,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PlnColors.accentYellow.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                children: [
                  // Identitas aplikasi + tombol profil
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLN NP',
                            style: _poppins(10, FontWeight.w600,
                                Colors.white.withValues(alpha: 0.9)),
                          ),
                          Text(
                            'e-Operasional',
                            style: _poppins(13, FontWeight.w700, Colors.white),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _tombolProfil(),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Judul halaman
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Icon(Icons.history_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Riwayat Pengisian',
                              style: _poppins(18, FontWeight.w700, Colors.white,
                                  ls: -0.4),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Geser untuk melihat data driver lain',
                              style: _poppins(11, FontWeight.w400,
                                  Colors.white.withValues(alpha: 0.7)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
                    colors: [PlnColors.primaryBlue, PlnColors.darkNavy],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: aktif
                ? [
                    BoxShadow(
                      color: PlnColors.primaryBlue.withValues(alpha: 0.25),
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
                  color: aktif ? Colors.white : PlnColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: _poppins(13, FontWeight.w600,
                      aktif ? Colors.white : PlnColors.textSecondary)),
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
          color: PlnColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PlnColors.border),
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