import 'package:costikstudio/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureRequestDraft {
  const FeatureRequestDraft({
    required this.productId,
    required this.productName,
    required this.title,
    required this.description,
  });

  final String productId;
  final String productName;
  final String title;
  final String description;
}

abstract class FeatureRequestRepository {
  Future<void> submit(FeatureRequestDraft draft);
}

class SupabaseFeatureRequestRepository implements FeatureRequestRepository {
  const SupabaseFeatureRequestRepository({this.client});

  final SupabaseClient? client;

  SupabaseClient get _supabase => client ?? Supabase.instance.client;

  @override
  Future<void> submit(FeatureRequestDraft draft) async {
    if (!SupabaseConfig.isConfigured) return;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Login diperlukan untuk mengirim request fitur.');
    }

    await _supabase.from('feature_requests').insert({
      'user_id': user.id,
      'product_id': draft.productId,
      'product_name': draft.productName,
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'status': 'pending',
    });
  }
}
