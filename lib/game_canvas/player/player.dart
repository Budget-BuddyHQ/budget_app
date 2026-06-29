import 'package:bonfire/bonfire.dart';

import '../../models_Like_Skins_and_lessons_templates/avatar_skin.dart';

class AdventurePlayer extends SimplePlayer {
  AdventurePlayer({
    required this.skin,
    required this.gold,
    required this.level,
    required super.position,
    required super.size,
  }) : super(speed: 80, animation: _playerAnimation(skin));

  final AvatarSkin skin;
  final int gold;
  final int level;

  static SimpleDirectionAnimation _playerAnimation(AvatarSkin skin) {
    return SimpleDirectionAnimation(
      idleRight: SpriteAnimation.load(
        skin.assetPath,
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 0.1,
          textureSize: Vector2(32, 32),
        ),
      ),
      runRight: SpriteAnimation.load(
        skin.assetPath,
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 0.1,
          textureSize: Vector2(32, 32),
        ),
      ),
    );
  }
}
