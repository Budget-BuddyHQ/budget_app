import 'package:flutter/material.dart';

import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import 'avatar_sprite.dart';

/// One person's face, anywhere a list of people is shown.
///
/// # The report
///
/// *"I don't think you can see other profile pictures or yours in like the
/// most gold section and all other sections other than the LP board."*
///
/// Three separate faults were producing that, which is why it looked
/// inconsistent rather than broken:
///
///  1. `_buildCachedLeaderboard` built every entry **without
///     `profileImageUrl`**, so the moment the board fell back to cache — no
///     network, a query timeout, an empty response — every face on it
///     vanished at once.
///  2. The "Your saved progress" header had a **hardcoded
///     `Icon(Icons.person_rounded)`** and was never passed an image at all.
///     So a player could see their own photo on the podium and a grey
///     silhouette in their own header, on the same screen.
///  3. Everywhere else fell back to the first letter of the username.
///
/// # Why the fallback is the skin and not a letter
///
/// Most players have never uploaded a photo, so a letter fallback means the
/// board is mostly initials — and Pixelify's capitals are the *worst* thing
/// to set an isolated letter in: measured, it has 10 to 23 confusable capital
/// pairs of 325, and a monogram has no word around it to disambiguate from.
/// B, E, G and S are one shape with four labels.
///
/// Everybody has a skin. Drawing it is a real, distinct, chosen face, and it
/// is the same character they see in Finance Brawl and walking around town —
/// which makes the skin worth having in one more place.
class LeaderAvatar extends StatelessWidget {
  const LeaderAvatar({
    super.key,
    required this.size,
    this.imageUrl = '',
    this.skinId = '',
    this.username = '',
    this.borderColor,
    this.borderWidth = 2,
    this.background = const Color(0xFF2A3C45),
  });

  /// An uploaded photo. Wins when present.
  final String imageUrl;

  /// The equipped skin id, drawn when there is no photo.
  final String skinId;

  /// Last resort, for the initial.
  final String username;

  final double size;
  final Color? borderColor;
  final double borderWidth;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: borderWidth),
      ),
      child: ClipOval(child: _face(context)),
    );
  }

  Widget _face(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // A broken photo URL falls through to the skin rather than to a
        // broken-image glyph. Avatars are hotlinked and go stale.
        errorBuilder: (_, _, _) => _skinOrInitial(context),
      );
    }
    return _skinOrInitial(context);
  }

  Widget _skinOrInitial(BuildContext context) {
    final skin = skinId.isEmpty
        ? null
        : budgetBuddySkins.where((s) => s.id == skinId).firstOrNull;

    if (skin != null) {
      // Villager cells are taller than wide, so the sprite is drawn slightly
      // larger than the circle and pushed down — a head-and-shoulders crop
      // reads as a portrait where a whole tiny body reads as a game token.
      return OverflowBox(
        maxWidth: size * 1.6,
        maxHeight: size * 1.6,
        child: Transform.translate(
          offset: Offset(0, size * 0.28),
          child: AvatarSprite(skin: skin, size: size * 1.45),
        ),
      );
    }

    return Center(
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        // Deliberately not the pixel face. An isolated capital is the one
        // place its confusable capitals have nothing to disambiguate them.
        style: TextStyle(
          color: borderColor ?? Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
