import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

class InputPage extends StatelessWidget {
  const InputPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: ColoredBox(color: AppColors.background),
    );
  }
}
