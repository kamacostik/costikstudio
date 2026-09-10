import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isEmbedded) ...[
          Text(
            'Support',
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            'Dummy support page for product help, documentation, client onboarding, and contact channels.',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: const Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 28),
        ],
        const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SupportLine(
                  icon: Icons.mail_rounded,
                  title: 'Email',
                  value: 'support@costikstudio.com',
                ),
                _SupportLine(
                  icon: Icons.chat_rounded,
                  title: 'WhatsApp',
                  value: 'Add official support number later',
                ),
                _SupportLine(
                  icon: Icons.description_rounded,
                  title: 'Docs',
                  value: 'docs.costikstudio.com',
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isEmbedded) {
      return content;
    }

    return SingleChildScrollView(
      child: ResponsiveSection(
        child: content,
      ),
    );
  }
}

class _SupportLine extends StatelessWidget {
  const _SupportLine({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
