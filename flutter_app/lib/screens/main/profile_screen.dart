import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/pln_colors.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../login_screen.dart';

// ============================================================
// Helper
// ============================================================

TextStyle _poppins(double size, FontWeight w, Color c, {double? ls}) =>
    GoogleFonts.poppins(
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: ls,
    );

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

String _tgl(String raw) {
  final iso = raw.length >= 10 ? raw.substring(0, 10) : raw;
  final p = iso.split('-');
  if (p.length != 3) return raw;
  final m = int.tryParse(p[1]) ?? 0;
  if (m < 1 || m > 12) return raw;
  return '${int.tryParse(p[2]) ?? p[2]} ${_bulan[m - 1]} ${p[0]}';
}

String _angka(num v, {int desimal = 0}) {
  final s = v.toStringAsFixed(desimal);
  final parts = s.split('.');
  final b = StringBuffer();
  final d = parts[0];
  for (var i = 0; i < d.length; i++) {
    if (i > 0 && (d.length - i) % 3 == 0) b.write('.');
    b.write(d[i]);
  }
  return parts.length > 1 ? '$b,${parts[1]}' : b.toString();
}

/// 1.250.000 -> "Rp 1,25 jt", 300.000 -> "Rp 300 rb"
String _rpRingkas(num v) {
  if (v >= 1000000) {
    final x = (v / 1000000).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    return 'Rp ${x.replaceAll('.', ',')} jt';
  }
  if (v >= 1000) {
    final x = (v / 1000).toStringAsFixed(1).replaceAll(RegExp(r'\.?0+$'), '');
    return 'Rp ${x.replaceAll('.', ',')} rb';
  }
  return 'Rp ${_angka(v)}';
}

class _PeranInfo {
  final String label;
  final String deskripsi;
  final IconData icon;
  const _PeranInfo(this.label, this.deskripsi, this.icon);
}

_PeranInfo _peran(String? role) {
  final r = (role ?? '').toLowerCase();
  if (r == 'admin') {
    return const _PeranInfo('Administrator',
        'Mengelola seluruh data, termasuk menghapus dan mengatur harga BBM',
        Icons.admin_panel_settings_outlined);
  }
  if (r == 'petugas') {
    return const _PeranInfo('Petugas',
        'Mengelola harga BBM dan data pemakaian',
        Icons.assignment_ind_outlined);
  }
  if (r.contains('driver')) {
    return const _PeranInfo('Driver',
        'Mencatat dan melihat pemakaian BBM kendaraan',
        Icons.local_shipping_outlined);
  }
  final label = r.isEmpty ? '-' : '${r[0].toUpperCase()}${r.substring(1)}';
  return _PeranInfo(label, 'Akses sesuai pengaturan akun', Icons.badge_outlined);
}

// ============================================================
// Halaman
// ============================================================

/// Halaman profil: hanya menampilkan informasi akun dan tombol keluar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _loggingOut = false;
  String? _error;

  // Ringkasan aktivitas (opsional; kalau gagal dimuat, bagian ini disembunyikan)
  int? _totalTransaksi;
  double _totalLiter = 0;
  double _totalRp = 0;
  String? _terakhirTanggal;
  String? _terakhirPlat;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().getUser();
      final user = Map<String, dynamic>.from(res.data['user'] as Map);
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat profil. Periksa koneksi lalu coba lagi.';
        _loading = false;
      });
      return;
    }
    _loadAktivitas();
  }

  Future<void> _loadAktivitas() async {
    try {
      final res = await ApiService()
          .getPemakaianBbm(scope: 'mine', page: 1, perPage: 1);
      final body = Map<String, dynamic>.from(res.data as Map);
      final meta = body['meta'] as Map;
      final data = (body['data'] as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _totalTransaksi = (meta['total'] as num).toInt();
        _totalLiter = ((meta['total_liter'] ?? 0) as num).toDouble();
        _totalRp = ((meta['total_jumlah'] ?? 0) as num).toDouble();
        if (data.isNotEmpty) {
          _terakhirTanggal = data.first['tanggal'] as String?;
          _terakhirPlat = data.first['plat_nomor'] as String?;
        }
      });
    } catch (_) {
      // Ringkasan tidak wajib; profil tetap tampil.
    }
  }

  Future<void> _keluar() async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Keluar dari akun?',
            style: _poppins(16, FontWeight.w700, PlnColors.textPrimary)),
        content: Text(
          'Anda perlu login lagi untuk memakai aplikasi.',
          style: _poppins(13, FontWeight.w400, PlnColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Keluar', style: TextStyle(color: PlnColors.danger)),
          ),
        ],
      ),
    );
    if (ya != true) return;

    // Simpan navigator sebelum proses async supaya aman dipakai sesudahnya.
    final nav = Navigator.of(context, rootNavigator: true);
    setState(() => _loggingOut = true);

    try {
      await ApiService().logout();
    } catch (_) {
      // Server hanya membalas pesan; token tetap dihapus di perangkat.
    }
    await StorageService.clearAll();

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ----------------------------------------------------------
  // Bagian tampilan
  // ----------------------------------------------------------

  Widget _avatar(String nama, String? photoUrl) {
    final inisial = nama.isEmpty ? '?' : nama[0].toUpperCase();
    final fallback = Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      color: Colors.white.withValues(alpha: 0.2),
      child: Text(inisial, style: _poppins(38, FontWeight.w700, Colors.white)),
    );

    final isi = (photoUrl == null || photoUrl.isEmpty)
        ? fallback
        : Image.network(
            photoUrl,
            width: 92,
            height: 92,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => fallback,
          );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipOval(child: isi),
    );
  }

  Widget _hero(String nama, _PeranInfo peran) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PlnColors.primaryBlue, PlnColors.darkNavy],
          ),
        ),
        child: Stack(
          children: [
            // Hiasan lingkaran
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  _avatar(nama, _user?['photo_url'] as String?),
                  const SizedBox(height: 16),
                  Text(nama,
                      style: _poppins(22, FontWeight.w700, Colors.white,
                          ls: -0.4)),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(peran.icon, size: 15, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(peran.label,
                            style:
                                _poppins(12, FontWeight.w600, Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statMini(IconData icon, String nilai, String label, Color warna) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        decoration: BoxDecoration(
          color: PlnColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PlnColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: warna),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(nilai,
                  style: _poppins(15, FontWeight.w700, PlnColors.textPrimary,
                      ls: -0.2)),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: _poppins(10, FontWeight.w500, PlnColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _aktivitas() {
    if (_totalTransaksi == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _judul('Aktivitas Anda'),
        Row(
          children: [
            _statMini(Icons.receipt_long_outlined, '$_totalTransaksi',
                'Transaksi', PlnColors.primaryBlue),
            const SizedBox(width: 10),
            _statMini(Icons.local_gas_station_outlined,
                '${_angka(_totalLiter, desimal: 1)} L', 'Total BBM',
                PlnColors.success),
            const SizedBox(width: 10),
            _statMini(Icons.payments_outlined, _rpRingkas(_totalRp),
                'Pengeluaran', PlnColors.warning),
          ],
        ),
        if (_terakhirTanggal != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: PlnColors.primaryBlue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.history, size: 20, color: PlnColors.primaryBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Terakhir mengisi ${_tgl(_terakhirTanggal!)}'
                    '${_terakhirPlat != null ? ' • $_terakhirPlat' : ''}',
                    style: _poppins(
                        12, FontWeight.w500, PlnColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _judul(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 2),
        child: Text(t,
            style: _poppins(14, FontWeight.w700, PlnColors.textPrimary)),
      );

  Widget _kotak(List<Widget> isi) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: PlnColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: PlnColors.border),
        ),
        child: Column(children: isi),
      );

  Widget _baris(IconData icon, String label, String value,
      {String? catatan, Widget? trailing, bool terakhir = false}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PlnColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: PlnColors.primaryBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: _poppins(
                            11, FontWeight.w500, PlnColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: _poppins(
                            14, FontWeight.w600, PlnColors.textPrimary)),
                    if (catatan != null) ...[
                      const SizedBox(height: 3),
                      Text(catatan,
                          style: _poppins(
                              11, FontWeight.w400, PlnColors.textSecondary)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing,
              ],
            ],
          ),
        ),
        if (!terakhir) Divider(height: 1, color: PlnColors.border),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = (_user?['username'] ?? '').toString();
    final role = (_user?['role'] ?? '').toString().toLowerCase();
    final peran = _peran(role);

    return Scaffold(
      backgroundColor: PlnColors.background,
      appBar: AppBar(
        backgroundColor: PlnColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: PlnColors.textPrimary,
        title: Text('Profil',
            style: _poppins(18, FontWeight.w700, PlnColors.textPrimary,
                ls: -0.3)),
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                    color: PlnColors.primaryBlue, strokeWidth: 3),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_outlined,
                              size: 48, color: PlnColors.danger),
                          const SizedBox(height: 12),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: _poppins(13, FontWeight.w400,
                                  PlnColors.textSecondary)),
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
                  )
                : RefreshIndicator(
                    onRefresh: _loadAktivitas,
                    color: PlnColors.primaryBlue,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                      children: [
                        _hero(nama, peran),
                        const SizedBox(height: 22),

                        _aktivitas(),

                        _judul('Informasi Akun'),
                        _kotak([
                          _baris(Icons.person_outline_rounded, 'Username',
                              nama),
                          _baris(peran.icon, 'Peran', peran.label,
                              catatan: peran.deskripsi),
                          _baris(Icons.lock_outline_rounded, 'Password',
                              '••••••••',
                              catatan: 'Disembunyikan demi keamanan',
                              trailing: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: PlnColors.success
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.lock_rounded,
                                    size: 16, color: PlnColors.success),
                              ),
                              terakhir: true),
                        ]),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _loggingOut ? null : _keluar,
                            icon: _loggingOut
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.logout_rounded, size: 20),
                            label: Text(_loggingOut ? 'Keluar…' : 'Keluar',
                                style: _poppins(
                                    14, FontWeight.w600, Colors.white)),
                            style: FilledButton.styleFrom(
                              backgroundColor: PlnColors.danger,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  PlnColors.danger.withValues(alpha: 0.5),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
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