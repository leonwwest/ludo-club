import 'package:ludo_club/models/ludo_models.dart';

abstract final class AssetMapper {
  static const String background = 'assets/backgrounds/club_table_v3.webp';
  static const String setupHero = 'assets/backgrounds/setup_hero_v4.webp';
  static const String tableSkinClassic =
      'assets/backgrounds/table_skin_classic_v4.webp';
  static const String tableSkinNight =
      'assets/backgrounds/table_skin_night_v4.webp';
  static const String branding = 'assets/branding/ludo_club_mark_v3.png';
  static const String diceIdle = 'assets/dice/dice_idle_v4.png';
  static const String boardTexture = 'assets/textures/felt_grain_v3.webp';
  static const String centerMedallion = 'assets/board/center_medallion_v4.png';
  static const String safeFieldStar = 'assets/board/safe_field_star_v4.png';
  static const String moveTargetRing = 'assets/effects/move_target_ring_v4.png';
  static const String captureBurst = 'assets/effects/capture_burst_v4.png';
  static const String finishWreath = 'assets/effects/finish_wreath_v4.png';
  static const String winnerConfetti = 'assets/effects/winner_confetti_v4.png';
  static const String winnerRibbon = 'assets/effects/winner_ribbon_v4.png';
  static const String currentTurnBadge =
      'assets/badges/current_turn_badge_v4.png';
  static const String botBadge = 'assets/badges/bot_badge_v4.png';
  static const String winnerTrophyBadge =
      'assets/badges/winner_trophy_badge_v4.png';

  static String diceFace(int value) {
    return 'assets/dice/dice_face_${value.clamp(1, 6)}_v4.png';
  }

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
