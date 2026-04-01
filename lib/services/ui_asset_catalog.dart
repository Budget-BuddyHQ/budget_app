import 'package:flutter/services.dart';

class UiAssetCatalog {
  UiAssetCatalog._(this._imageAssets);

  final List<String> _imageAssets;

  static Future<UiAssetCatalog> load({
    String imageRoot = 'assets/images/',
  }) async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final imageAssets = manifest.listAssets()
        .where((path) => path.startsWith(imageRoot))
        .where(
          (path) =>
              path.endsWith('.png') ||
              path.endsWith('.jpg') ||
              path.endsWith('.jpeg') ||
              path.endsWith('.webp'),
        )
        .toList(growable: false);

    return UiAssetCatalog._(imageAssets);
  }

  String imageForSlot(
    String slot, {
    String fallback = 'assets/images/logo.png',
  }) {
    if (_imageAssets.isEmpty) {
      return fallback;
    }

    final keywords = _keywordsForSlot(slot);
    for (final assetPath in _imageAssets) {
      final lowerPath = assetPath.toLowerCase();
      if (keywords.any(lowerPath.contains)) {
        return assetPath;
      }
    }

    return _imageAssets.firstWhere(
      (assetPath) => assetPath == fallback,
      orElse: () => _imageAssets.first,
    );
  }

  List<String> _keywordsForSlot(String slot) {
    switch (slot) {
      case 'hero':
        return const ['hero', 'banner', 'battle', 'challenge', 'main'];
      case 'balance':
        return const ['balance', 'wallet', 'coin', 'gold', 'card'];
      case 'progress':
        return const ['progress', 'chart', 'bar', 'graph'];
      case 'home':
        return const ['home', 'house'];
      case 'budget':
        return const ['budget', 'wallet', 'coin'];
      case 'invest':
        return const ['invest', 'graph', 'chart'];
      case 'challenge':
        return const ['challenge', 'battle', 'sword'];
      case 'profile':
        return const ['profile', 'avatar', 'user'];
      default:
        return const <String>[];
    }
  }
}