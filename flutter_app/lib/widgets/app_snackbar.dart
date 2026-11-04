import 'package:flutter/material.dart';

import '../config/theme.dart';

class AppSnackbar {
  static void success(BuildContext context, String message) {
    _show(context, message, AppTheme.success, Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, AppTheme.error, Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, AppTheme.info, Icons.info_outline);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: color,
        ),
      );
  }
}
