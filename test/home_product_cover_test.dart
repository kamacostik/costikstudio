import 'package:costikstudio/core/data/product_gallery_loader.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:costikstudio/features/auth/cubit/auth_cubit.dart';
import 'package:costikstudio/features/home/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home focus card shows uploaded IPTV cover image', (
    tester,
  ) async {
    final loader = ProductGalleryLoader(
      repository: _FakeGallery({
        'costik-iptv': const [
          ProductImage(
            id: 'img-1',
            productId: 'costik-iptv',
            imageUrl: 'https://example.com/iptv-cover.png',
            isCover: true,
          ),
        ],
      }),
    );

    await tester.pumpWidget(
      BlocProvider<AuthCubit>(
        create: (_) => AuthCubit(),
        child: MaterialApp(
          home: Scaffold(body: HomePage(galleryLoader: loader)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
  });
}

class _FakeGallery implements PublicProductImageRepository {
  _FakeGallery(this.imagesByProductId);

  final Map<String, List<ProductImage>> imagesByProductId;

  @override
  Future<Map<String, List<ProductImage>>> loadImagesByProductId() async {
    return imagesByProductId;
  }
}
