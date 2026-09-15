import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('product images schema supports admin-managed galleries', () {
    final sql = File('docs/db/product_images.sql').readAsStringSync();

    expect(sql, contains("values ('product-images', 'product-images', true)"));
    expect(sql, contains('create table if not exists public.product_images'));
    expect(sql, contains('product_id text not null'));
    expect(sql, contains('image_url text not null'));
    expect(sql, contains('is_cover boolean not null default false'));
    expect(sql, contains('sort_order integer not null default 0'));
    expect(sql, contains('product_images_product_id_sort_order_idx'));
    expect(sql, contains('product_images_single_cover_idx'));
    expect(sql, contains('enable row level security'));
    expect(sql, contains('product images are readable'));
    expect(sql, contains('product images are admin manageable'));
  });
}
