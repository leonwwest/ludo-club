import 'package:ludo_club/models/ludo_models.dart';

abstract final class AssetMapper {
  static const String background = 'assets/backgrounds/club_table_v2.png';
  static const String branding = 'assets/branding/ludo_club_mark_v2.png';
  static const String dice = 'assets/dice/roll_dice_v2.png';

  static String avatarFor(PlayerColor color) {
    return switch (color) {
      PlayerColor.red => 'assets/avatars/sisiliya_v2.png',
      PlayerColor.green => 'assets/avatars/flora_v2.png',
      PlayerColor.yellow => 'assets/avatars/abdul_v2.png',
      PlayerColor.blue => 'assets/avatars/kiran_v2.png',
    };
  }

  static String pinFor(PlayerColor color) {
    return switch (color) {
      PlayerColor.red => 'assets/pins/pin_red_v2.png',
      PlayerColor.green => 'assets/pins/pin_green_v2.png',
      PlayerColor.yellow => 'assets/pins/pin_yellow_v2.png',
      PlayerColor.blue => 'assets/pins/pin_blue_v2.png',
    };
  }
}
