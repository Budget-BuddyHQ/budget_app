import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import 'avatar_sprite.dart';

/// A circular profile picture that renders whatever the player actually has:
/// a remote URL, a local file path (when cloud storage is unavailable), or
/// their equipped villager skin as the fallback.
///
/// Centralised because the same avatar appears on the home hero, the profile
/// screen, and the leaderboard, and each had its own subtly different — and
/// subtly mis-centred — implementation. The photo is always centre-cropped to
/// a square, and the sprite fallback is scaled to fit rather than cropped, so
/// neither can drift off-centre inside the ring.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.fallbackSkin,
    required this.size,
    this.ringColor = const Color(0xFF85EFAC),
    this.ringWidth = 2.4,
    this.showGlow = true,
  });

  final String imageUrl;
  final AvatarSkin fallbackSkin;
  final double size;
  final Color ringColor;
  final double ringWidth;
  final bool showGlow;

  bool get _isRemote =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    // The photo fills the ring; the sprite sits inset so it isn't cropped.
    final inner = size - ringWidth * 2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF071711).withValues(alpha: 0.74),
        border: Border.all(color: ringColor, width: ringWidth),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.28),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: SizedBox(
          width: inner,
          height: inner,
          child: _buildImage(inner),
        ),
      ),
    );
  }

  Widget _buildImage(double inner) {
    if (imageUrl.isEmpty) {
      return _fallback(inner);
    }

    if (_isRemote) {
      return Image.network(
        imageUrl,
        width: inner,
        height: inner,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => _fallback(inner),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: inner * 0.3,
              height: inner * 0.3,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ringColor,
              ),
            ),
          );
        },
      );
    }

    // A local path — used when cloud storage isn't available. Not supported on
    // web, where there is no filesystem to read back from.
    if (!kIsWeb) {
      return Image.file(
        File(imageUrl),
        width: inner,
        height: inner,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (_, _, _) => _fallback(inner),
      );
    }
    return _fallback(inner);
  }

  /// The equipped skin, padded and centred so the sprite never gets clipped by
  /// the circle the way a cover-fitted photo intentionally is.
  Widget _fallback(double inner) {
    // AvatarSprite has no idea how big `inner` is, so an unsized call
    // renders a villager at its natural 104x152 sheet-cell size — bigger
    // than most avatar circles — and gets clipped by the ClipOval above.
    // FittedBox scales it down to actually fit the inset content box.
    return Padding(
      padding: EdgeInsets.all(inner * 0.14),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: AvatarSprite(skin: fallbackSkin),
        ),
      ),
    );
  }
}
