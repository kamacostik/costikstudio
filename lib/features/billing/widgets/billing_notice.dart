import 'package:costikstudio/app/theme/costik_studio_theme.dart';
import 'package:flutter/material.dart';

class BillingNotice extends StatelessWidget {
  const BillingNotice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: CostikStudioTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CostikStudioTheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: CostikStudioTheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
