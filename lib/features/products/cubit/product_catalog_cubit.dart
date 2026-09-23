import 'package:costikstudio/core/data/dummy_products.dart';
import 'package:costikstudio/core/data/product_gallery_loader.dart';
import 'package:costikstudio/core/models/product_item.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProductCatalogState extends Equatable {
  const ProductCatalogState({
    this.products = dummyProducts,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ProductItem> products;
  final bool isLoading;
  final String? errorMessage;

  ProductCatalogState copyWith({
    List<ProductItem>? products,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProductCatalogState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  ProductItem? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return findProductById(id);
  }

  @override
  List<Object?> get props => [products, isLoading, errorMessage];
}

class ProductCatalogCubit extends Cubit<ProductCatalogState> {
  ProductCatalogCubit({this.galleryLoader = const ProductGalleryLoader()})
    : super(const ProductCatalogState());

  final ProductGalleryLoader galleryLoader;
  bool _hasLoaded = false;

  Future<void> load({bool forceRefresh = false}) async {
    if (_hasLoaded && !forceRefresh) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final publicProducts = dummyProducts.where((p) => !p.isHidden).toList();
      final products = await galleryLoader.attachAllImages(publicProducts);
      _hasLoaded = true;
      emit(ProductCatalogState(products: products));
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}
