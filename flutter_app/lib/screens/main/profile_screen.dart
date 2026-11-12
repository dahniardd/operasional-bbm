import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../utils/display_format.dart';
import '../../utils/formatters.dart';
import '../../widgets/pln_header_shell.dart';
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
  bool _aktivitasLoading = true;

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
        _totalLiter = asDouble(meta['total_liter']);
        _totalRp = asDouble(meta['total_jumlah']);
        if (data.isNotEmpty) {
          _terakhirTanggal = data.first['tanggal'] as String?;
          _terakhirPlat = data.first['plat_nomor'] as String?;
        }
      });
    } catch (_) {
      // Ringkasan tidak wajib; profil tetap tampil.
    } finally {
      if (mounted) setState(() => _aktivitasLoading = false);
    }
  }

  Future<void> _keluar() async {
    final ya = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) =>
          _KonfirmasiKeluar(nama: (_user?['username'] ?? '').toString()),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
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
            colors: [AppColors.primary, AppColors.darkNavy],
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
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
                  style: _poppins(15, FontWeight.w700, AppColors.textPrimary,
                      ls: -0.2)),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label,
                  maxLines: 1,
                  style: _poppins(
                      12, FontWeight.w500, AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  /// Kerangka bagian "Aktivitas Anda" (judul + tiga kotak statistik).
  Widget _skeletonAktivitas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10, left: 2),
          child: _Skeleton(width: 110, height: 16, radius: 6),
        ),
        Row(
          children: const [
            Expanded(child: _Skeleton(height: 96, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: _Skeleton(height: 96, radius: 18)),
            SizedBox(width: 10),
            Expanded(child: _Skeleton(height: 96, radius: 18)),
          ],
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  /// Kerangka seluruh halaman saat profil pertama kali dimuat.
  Widget _skeletonHalaman() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        const _Skeleton(height: 240, radius: 28),
        const SizedBox(height: 22),
        _skeletonAktivitas(),
        const Padding(
          padding: EdgeInsets.only(bottom: 10, left: 2),
          child: _Skeleton(width: 130, height: 16, radius: 6),
        ),
        const _Skeleton(height: 230, radius: 20),
      ],
    );
  }

  Widget _aktivitas() {
    if (_totalTransaksi == null) {
      // Pertama kali dimuat: tampilkan kerangka supaya layout tidak melompat.
      // Kalau gagal dimuat, bagian ini disembunyikan.
      return _aktivitasLoading ? _skeletonAktivitas() : const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _judul('Aktivitas Anda'),
        Row(
          children: [
            _statMini(Icons.receipt_long_outlined, '$_totalTransaksi',
                'Transaksi', AppColors.primary),
            const SizedBox(width: 10),
            _statMini(Icons.local_gas_station_outlined,
                '${formatLiter(_totalLiter)} L', 'Total BBM',
                AppColors.success),
            const SizedBox(width: 10),
            _statMini(Icons.payments_outlined, fmtRpRingkas(_totalRp),
                'Pengeluaran', AppColors.warning),
          ],
        ),
        if (_terakhirTanggal != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.history, size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Terakhir mengisi ${fmtTgl(_terakhirTanggal!)}'
                    '${_terakhirPlat != null ? ' • $_terakhirPlat' : ''}',
                    style: _poppins(
                        12, FontWeight.w500, AppColors.textPrimary),
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
            style: _poppins(14, FontWeight.w700, AppColors.textPrimary)),
      );

  Widget _kotak(List<Widget> isi) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
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
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: _poppins(
                            11, FontWeight.w500, AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: _poppins(
                            14, FontWeight.w600, AppColors.textPrimary)),
                    if (catatan != null) ...[
                      const SizedBox(height: 3),
                      Text(catatan,
                          style: _poppins(12, FontWeight.w400, AppColors.textSecondary)),
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
        if (!terakhir) Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nama = (_user?['username'] ?? '').toString();
    final role = (_user?['role'] ?? '').toString().toLowerCase();
    final peran = _peran(role);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Column(
          children: [
            PlnHeaderShell(
              onBack: () => Navigator.of(context).maybePop(),
              child: const PlnHeaderTitle(
                icon: Icons.person_outline_rounded,
                title: 'Profil',
                subtitle: 'Informasi akun dan aktivitas Anda',
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: _loading
            ? _skeletonHalaman()
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_outlined,
                              size: 48, color: AppColors.danger),
                          const SizedBox(height: 12),
                          Text(_error!,
                              textAlign: TextAlign.center,
                              style: _poppins(13, FontWeight.w400,
                                  AppColors.textSecondary)),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _load,
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAktivitas,
                    color: AppColors.primary,
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
                                  color: AppColors.success
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.lock_rounded,
                                    size: 16, color: AppColors.success),
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
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.danger.withValues(alpha: 0.5),
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
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Dialog konfirmasi keluar (sederhana, aksen gradien)
// ============================================================

class _KonfirmasiKeluar extends StatelessWidget {
  final String nama;
  const _KonfirmasiKeluar({required this.nama});

  @override
  Widget build(BuildContext context) {
    final merahGelap = Color.lerp(AppColors.danger, Colors.black, 0.3)!;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          constraints: const BoxConstraints(maxWidth: 340),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Satu ikon bergradien
              Container(
                width: 66,
                height: 66,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.danger, merahGelap],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.32),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.logout_rounded,
                    size: 32, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Keluar dari akun?',
                textAlign: TextAlign.center,
                style: _poppins(20, FontWeight.w700, AppColors.textPrimary,
                    ls: -0.3),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: _poppins(
                      13, FontWeight.w400, AppColors.textSecondary),
                  children: [
                    if (nama.isNotEmpty) ...[
                      const TextSpan(text: 'Akun '),
                      TextSpan(
                        text: nama,
                        style: _poppins(
                            13, FontWeight.w700, AppColors.textPrimary),
                      ),
                      const TextSpan(text: ' akan keluar dari perangkat ini. '),
                    ],
                    const TextSpan(
                        text: 'Anda perlu login lagi untuk memakai aplikasi.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  // Batal: abu-abu lembut
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.background,
                        foregroundColor: AppColors.textSecondary,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Batal',
                          style: _poppins(
                              14, FontWeight.w600, AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Ya, Keluar: gradien merah
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, true),
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.danger, merahGelap],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.danger.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text('Ya, Keluar',
                                style: _poppins(
                                    14, FontWeight.w600, Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Kerangka loading (skeleton) berdenyut
// ============================================================

class _Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  const _Skeleton({this.width, required this.height, this.radius = 12});

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}