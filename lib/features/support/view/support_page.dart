import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/shared/widgets/responsive_section.dart';
import 'package:costikstudio/features/support/data/feature_request_repository.dart';
import 'package:flutter/material.dart';

enum SupportPageMode { support, featureRequest }

class SupportPage extends StatelessWidget {
  const SupportPage({
    super.key,
    this.isEmbedded = false,
    this.mode = SupportPageMode.support,
    FeatureRequestRepository? repository,
  }) : repository = repository ?? const SupabaseFeatureRequestRepository();

  final bool isEmbedded;
  final SupportPageMode mode;
  final FeatureRequestRepository repository;

  @override
  Widget build(BuildContext context) {
    final content = switch (mode) {
      SupportPageMode.support => _buildSupportContent(context),
      SupportPageMode.featureRequest => _FeatureRequestContent(
        repository: repository,
      ),
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
  const _FeatureRequestContent({required this.repository});

  final FeatureRequestRepository repository;

  @override
  State<_FeatureRequestContent> createState() => _FeatureRequestContentState();
}

class _FeatureRequestContentState extends State<_FeatureRequestContent> {
  ProductItem _selectedProduct = dummyProducts.first;
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    FocusScope.of(context).unfocus();

    await widget.repository.submit(
      FeatureRequestDraft(
        productId: _selectedProduct.id,
        productName: _selectedProduct.name,
        title: _titleController.text,
        description: _detailController.text,
      ),
    );

    if (!mounted) return;
    _titleController.clear();
    _detailController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request fitur berhasil dikirim.')),
    );
  }

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
            DropdownButtonFormField<ProductItem>(
              key: const Key('feature_request_product_dropdown'),
              initialValue: _selectedProduct,
              decoration: const InputDecoration(
                labelText: 'Pilih Aplikasi',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final product in dummyProducts)
                  DropdownMenuItem(value: product, child: Text(product.name)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedProduct = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('feature_request_title_field'),
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Fitur',
                hintText: 'Contoh: Jadwal reboot perangkat otomatis',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('feature_request_detail_field'),
              controller: _detailController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Detail Request',
                hintText: 'Jelaskan kebutuhan, alur kerja, dan manfaat fitur.',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitRequest,
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
