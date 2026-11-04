import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/harga_bbm_provider.dart';
import 'providers/master_data_provider.dart';
import 'providers/pemakaian_bbm_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const OperasionalBbmApp());
}

class OperasionalBbmApp extends StatelessWidget {
  const OperasionalBbmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MasterDataProvider()),
        ChangeNotifierProvider(create: (_) => HargaBbmProvider()),
        ChangeNotifierProvider(create: (_) => PemakaianBbmProvider()),
      ],
      child: MaterialApp(
        title: 'Operasional BBM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
