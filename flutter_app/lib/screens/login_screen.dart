import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'main_shell.dart';

// Design tokens
class _C {
  static const primary = Color(0xFF006877);
  static const primaryContainer = Color(0xFF00A2B9);
  static const navy = Color(0xFF0B1C30);
  static const surface = Color(0xFFF8F9FF);
  static const secondary = Color(0xFF505F76);
  static const error = Color(0xFFDC2626);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();

  late final AnimationController _kenBurns;

  bool _obscurePassword = true;

  // Foto background hero
  static const String _heroImage = 'assets/images/login3.jpg';

  // Bagian foto yang ditampilkan. Foto ini portrait, jadi area hero hanya
  // menampilkan sebagian. y = -1 (paling atas), 0 (tengah), 1 (paling bawah).
  // Jangan di luar rentang -1 sampai 1.
  static const Alignment _imageAlignment = Alignment(0, -1);

  // Lengkungan sudut kiri atas kartu & seberapa jauh kartu menimpa foto
  static const double _cardRadius = 80;
  static const double _overlap = 48;

  // Menurunkan seluruh kartu (termasuk lengkung sudutnya).
  // Makin besar = kartu makin turun. Negatif = kartu naik.
  static const double _cardDrop = 52;

  // Dasar tinggi foto sebagai pecahan tinggi layar. Foto lalu dipanjangkan
  // sampai ke belakang kartu, jadi lengkungan kartu tidak menampakkan putih.
  static const double _heroFraction = 0.34;

  // Zoom foto: mulai dari skala dasar, membesar sejauh _zoomRange.
  // Set _zoomRange = 0 kalau mau foto diam tanpa efek zoom.
  static const double _baseScale = 1.0;
  static const double _zoomRange = 0.05;

  // Seberapa cepat foto ikut bergeser saat form di-scroll (0 = diam,
  // 1 = ikut sama cepat dengan kartu).
  static const double _parallax = 0.35;

  // Tambahan tinggi kartu supaya bisa di-scroll (dalam piksel).
  // 0 = kartu pas setinggi sisa layar.
  static const double _extraScroll = 0;

  @override
  void initState() {
    super.initState();
    _kenBurns = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    _kenBurns.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    UnderlineInputBorder line(Color color, [double width = 1.4]) {
      return UnderlineInputBorder(
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _C.slate400,
      ),
      floatingLabelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _C.primary,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _C.slate400,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      prefixIcon: Icon(icon, size: 26),
      prefixIconColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? _C.primary
            : _C.slate400,
      ),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 20),
      enabledBorder: line(_C.slate300),
      border: line(_C.slate300),
      focusedBorder: line(_C.primaryContainer, 2.4),
      errorBorder: line(_C.error),
      focusedErrorBorder: line(_C.error, 2.4),
      errorStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _C.error,
      ),
    );
  }

  // Logo + nama aplikasi (langsung di atas foto, tanpa kaca)
  Widget _buildBrandBadge() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            'assets/images/logo.png',
            height: 26,
            width: 26,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.local_gas_station_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'e-Operasional BBM',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(double height, double topPad) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Foto background (asset lokal) dengan efek Ken Burns halus
          ClipRect(
            child: AnimatedBuilder(
              animation: _kenBurns,
              builder: (context, child) {
                return Transform.scale(
                  scale: _baseScale + (_zoomRange * _kenBurns.value),
                  alignment: _imageAlignment,
                  child: child,
                );
              },
              child: Image.asset(
                _heroImage,
                fit: BoxFit.cover,
                alignment: _imageAlignment,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: 1200,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.4),
                      radius: 1.0,
                      colors: [Color(0xFF004E5A), _C.navy],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Gradient di atas supaya logo & teks tetap terbaca
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  _C.navy.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Brand di pojok kiri atas
          Positioned(
            top: topPad + 36,
            left: 20,
            child: _buildBrandBadge(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Garis aksen di atas judul
        Container(
          width: 100,
          height: 3.5,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_C.primary, _C.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Selamat Datang',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _C.navy,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Masukkan username dan password Anda untuk melanjutkan.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            height: 1.5,
            color: _C.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(AuthProvider auth) {
    final disabled = auth.isLoading;

    return Opacity(
      opacity: disabled ? 0.85 : 1,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_C.primary, _C.primaryContainer],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: disabled ? null : _submit,
            child: Center(
              child: disabled
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Masuk',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final media = MediaQuery.of(context);
    final topPad = media.padding.top;
    final baseHero = (media.size.height * _heroFraction).clamp(220.0, 360.0);

    // Posisi atas kartu: makin besar _cardDrop, makin turun
    final cardTop = baseHero - _overlap + _cardDrop;

    // Foto dipanjangkan sampai ke belakang kartu, melewati lengkungannya,
    // supaya sudut melengkung tidak menampakkan warna putih.
    final photoHeight = cardTop + _cardRadius;

    // Kartu setinggi sisa layar (+ _extraScroll kalau mau ada ruang scroll)
    final cardMinHeight = media.size.height - cardTop + _extraScroll;

    return Scaffold(
      backgroundColor: _C.surface,
      body: Stack(
        children: [
          // Foto di belakang, ikut bergeser pelan saat form di-scroll
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final offset = _scrollController.hasClients
                    ? _scrollController.offset.clamp(0.0, double.infinity)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(0, -offset * _parallax),
                  child: child,
                );
              },
              child: _buildHero(photoHeight, topPad),
            ),
          ),

          // Kartu form: bisa di-scroll kalau isinya melebihi layar
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.trackpad,
                },
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    SizedBox(height: cardTop),
                    Container(
                      width: double.infinity,
                      constraints: BoxConstraints(minHeight: cardMinHeight),
                      padding: EdgeInsets.fromLTRB(
                        28,
                        30,
                        28,
                        20 + media.padding.bottom,
                      ),
                      decoration: BoxDecoration(
                        color: _C.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(_cardRadius),
                          topRight: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _C.navy.withValues(alpha: 0.12),
                            blurRadius: 25,
                            offset: const Offset(0, -8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeading(),
                            const SizedBox(height: 28),

                            // Username
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _C.navy,
                              ),
                              decoration: _inputDecoration(
                                label: 'Username / NIP',
                                hint: 'Contoh: 9418209NP',
                                icon: Icons.person_outline_rounded,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Username wajib diisi.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _C.navy,
                              ),
                              decoration: _inputDecoration(
                                label: 'Password',
                                hint: 'Masukkan password',
                                icon: Icons.lock_outline_rounded,
                                suffix: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 26,
                                    color: _C.slate400,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password wajib diisi.';
                                }
                                return null;
                              },
                            ),

                            // Error dari AuthProvider
                            if (auth.error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _C.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _C.error.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: _C.error,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        auth.error!,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: _C.error,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Jarak password ke tombol Masuk
                            const SizedBox(height: 34),
                            _buildSubmitButton(auth),

                            // Footer: di bawah tombol
                            const SizedBox(height: 32),
                            Text(
                              'Aplikasi Resmi Operasional BBM © 2026 PT PLN Nusantara Power',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _C.slate400,
                              ),
                            ),
                          ],
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
    );
  }
}