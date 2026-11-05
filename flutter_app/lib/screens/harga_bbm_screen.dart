// Placeholder for HargaBbmScreen
// This screen will be implemented in future phases
import 'package:flutter/material.dart';

class HargaBbmListScreen extends StatelessWidget {
  const HargaBbmListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harga BBM'),
      ),
      body: const Center(
        child: Text('Fitur Harga BBM akan segera hadir'),
      ),
    );
  }
}

// Alias for compatibility
typedef HargaBbmScreen = HargaBbmListScreen;
