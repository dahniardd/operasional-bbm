import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const String _videoAsset = 'assets/videos/logo_splash.mp4';

  // Warna latar saat video belum siap. Samakan dengan warna background videomu.
  static const Color _background = Color(0xFF0B1C30);

  VideoPlayerController? _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthProvider>();

    // Cek login dan putar video berjalan bersamaan,
    // pindah halaman setelah keduanya selesai.
    await Future.wait([
      auth.checkAuth(),
      _playVideo(),
    ]);

    if (!mounted || _navigated) {
      return;
    }
    _navigated = true;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            auth.isLoggedIn ? const MainShell() : const LoginScreen(),
      ),
    );
  }

  // Selesai saat video habis. Kalau video gagal dimuat, tetap lanjut
  // setelah jeda singkat supaya aplikasi tidak macet di splash.
  Future<void> _playVideo() async {
    try {
      final controller = VideoPlayerController.asset(_videoAsset);
      _controller = controller;

      await controller.initialize();
      if (!mounted) {
        return;
      }

      // Browser memblokir autoplay yang bersuara, jadi di web dibisukan.
      await controller.setVolume(kIsWeb ? 0 : 1);
      setState(() {});
      await controller.play();

      final done = Completer<void>();
      void listener() {
        final value = controller.value;
        final finished = value.duration > Duration.zero &&
            value.position >= value.duration;
        if ((finished || value.hasError) && !done.isCompleted) {
          done.complete();
        }
      }

      controller.addListener(listener);

      // Batas aman: durasi video + 1 detik
      await done.future.timeout(
        controller.value.duration + const Duration(seconds: 1),
        onTimeout: () {},
      );

      controller.removeListener(listener);
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: _background,
      body: SizedBox.expand(
        child: ready
            ? FittedBox(
                // cover = penuhi layar. Ganti ke BoxFit.contain kalau
                // logonya terpotong di tepi layar.
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}