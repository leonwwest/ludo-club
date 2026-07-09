import 'package:ludo_club/models/ludo_models.dart';

abstract final class AssetMapper {
  static const String background = 'assets/backgrounds/club_table_v3.png';
  static const String branding = 'assets/branding/ludo_club_mark_v3.png';
  static const String dice = 'assets/dice/roll_dice_v3.png';
  static const String boardTexture = 'assets/textures/felt_grain_v3.png';

  static String avatarFor(PlayerColor color) {
    return avatarForId(
      switch (color) {
        PlayerColor.red => PlayerAvatarId.sisiliya,
        PlayerColor.green => PlayerAvatarId.flora,
        PlayerColor.yellow => PlayerAvatarId.abdul,
        PlayerColor.blue => PlayerAvatarId.kiran,
      },
    );
  }

  static String avatarForId(PlayerAvatarId avatarId) {
    return switch (avatarId) {
      PlayerAvatarId.sisiliya => 'assets/avatars/sisiliya_v3.png',
      PlayerAvatarId.flora => 'assets/avatars/flora_v3.png',
      PlayerAvatarId.abdul => 'assets/avatars/abdul_v3.png',
      PlayerAvatarId.kiran => 'assets/avatars/kiran_v3.png',
    };
  }

  static String pinFor(PlayerColor color) {
    return switch (color) {
      PlayerColor.red => 'assets/pins/pin_red_v3.png',
      PlayerColor.green => 'assets/pins/pin_green_v3.png',
      PlayerColor.yellow => 'assets/pins/pin_yellow_v3.png',
      PlayerColor.blue => 'assets/pins/pin_blue_v3.png',
    };
  }
}
