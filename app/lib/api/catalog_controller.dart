import 'dart:async';

import 'package:flutter/foundation.dart';

import 'catalog_api.dart';

class CatalogController extends ChangeNotifier {
  CatalogController(this.api);
  final CatalogApi api;
  List<CatalogOption> categories = [], points = [];
  List<CatalogEntry> entries = [];
  String term = '';
  int? category;
  bool products = false,
      loading = false,
      loadingMore = false,
      initialized = false;
  String? error, moreError;
  int total = 0, page = 0, lastPage = 1, _generation = 0;
  bool _disposed = false;
  Timer? _debounce;
  bool get hasMore => page < lastPage;
  bool get filtered => term.trim().isNotEmpty || category != null;

  Future<void> refresh() {
    initialized = false;
    return load();
  }

  void filter({
    String? text,
    bool? showProducts,
    int? categoryId,
    bool changeCategory = false,
  }) {
    if (text != null) term = text;
    if (showProducts != null) products = showProducts;
    if (changeCategory) category = categoryId;
    _debounce?.cancel();
    _generation++;
    entries = [];
    total = 0;
    loading = true;
    error = moreError = null;
    notifyListeners();
    if (text != null) {
      _debounce = Timer(const Duration(milliseconds: 300), load);
    } else {
      load();
    }
  }

  Future<void> load({bool more = false}) async {
    if (_disposed || (more && (loading || loadingMore || !hasMore))) return;
    _debounce?.cancel();
    final generation = ++_generation;
    if (more) {
      loadingMore = true;
      moreError = null;
    } else {
      loading = true;
      loadingMore = false;
      error = null;
      moreError = null;
      entries = [];
    }
    notifyListeners();
    try {
      final values = await Future.wait<Object>([
        api.search(
          products: products,
          term: term,
          category: category,
          page: more ? page + 1 : 1,
        ),
        if (!initialized) api.options('categorias'),
        if (!initialized) api.options('puntos-entrega'),
      ]);
      if (_disposed || generation != _generation) return;
      final result = values.first as CatalogPageData;
      if (!initialized) {
        categories = values[1] as List<CatalogOption>;
        points = values[2] as List<CatalogOption>;
        initialized = true;
      }
      final combined = more ? [...entries, ...result.entries] : result.entries;
      entries = {for (final entry in combined) entry.id: entry}.values.toList();
      total = result.total;
      page = result.page;
      lastPage = result.lastPage;
    } catch (exception) {
      if (_disposed || generation != _generation) return;
      final message = exception is ApiFailure
          ? exception.message
          : 'No pudimos cargar la información. Inténtalo de nuevo.';
      if (more) {
        moreError = message;
      } else {
        error = message;
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = loadingMore = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _debounce?.cancel();
    super.dispose();
  }
}
