import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:flutter/material.dart';

enum SupportPageMode { support, featureRequest }

class SupportPage extends StatelessWidget {
  const SupportPage({
    super.key,
    this.isEmbedded = false,
    this.mode = SupportPageMode.support,
  });

  final bool isEmbedded;
  final SupportPageMode mode;

  @override
  Widget build(BuildContext context) {
    final content = switch (mode) {
      SupportPageMode.support => _buildSupportContent(context),
      SupportPageMode.featureRequest => const _FeatureRequestContent(),
    };

    if (isEmbedded) {
      return content;
    }

    return SingleChildScrollView(child: ResponsiveSection(child: content));
  }

  Widget _buildSupportContent(BuildContext context) {
    return Column(
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
  }
}

class _FeatureRequestContent extends StatefulWidget {
  const _FeatureRequestContent();

  @override
  State<_FeatureRequestContent> createState() => _FeatureRequestContentState();
}

class _FeatureRequestContentState extends State<_FeatureRequestContent> {
  String _selectedProduct = 'Costik IPTV';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Fitur',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Kirim ide fitur baru agar bisa diprioritaskan sesuai aplikasi yang dipakai.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF64748B), height: 1.45),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              key: const Key('feature_request_product_dropdown'),
              initialValue: _selectedProduct,
              decoration: const InputDecoration(
                labelText: 'Pilih Aplikasi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Costik IPTV',
                  child: Text('Costik IPTV'),
                ),
                DropdownMenuItem(
                  value: 'Digital Signage',
                  child: Text('Digital Signage'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedProduct = value);
              },
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Judul Fitur',
                hintText: 'Contoh: Jadwal reboot perangkat otomatis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Detail Request',
                hintText: 'Jelaskan kebutuhan, alur kerja, dan manfaat fitur.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: null,
              icon: const Icon(Icons.send_rounded),
              label: const Text('Kirim Request'),
            ),
          ],
        ),
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
