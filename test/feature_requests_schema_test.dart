import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature requests schema supports customer submit and admin review', () {
    final sql = File('docs/db/feature_requests.sql').readAsStringSync();

    expect(sql, contains('create table if not exists public.feature_requests'));
    expect(sql, contains('user_id uuid not null references auth.users'));
    expect(
      sql,
      contains('product_id text not null references public.products'),
    );
    expect(sql, contains('product_name text not null'));
    expect(sql, contains('title text not null'));
    expect(sql, contains('description text not null'));
    expect(sql, contains("status text not null default 'pending'"));
    expect(sql, contains('admin_note text'));
    expect(sql, contains('feature_requests_user_created_idx'));
    expect(sql, contains('feature_requests_status_created_idx'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('feature requests insert own'));
    expect(sql, contains('feature requests select own'));
    expect(sql, contains('feature requests admin manage'));
    expect(sql, contains('from public.profiles p'));
    expect(sql, contains("p.role = 'admin'"));
  });
}
