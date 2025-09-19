import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_objects.dart';

class ColorUtils {
  // Brand/base colors matching pin SVGs (darker gradient stop)
  static const Color _redBase = Color(0xFFCC2936);
  static const Color _greenBase = Color(0xFF2F9E44);
  static const Color _blueBase = Color(0xFF1971C2);
  static const Color _yellowBase = Color(0xFFFAB005);

  // Convert PlayerColor enum to display Color for UI
  static Color getDisplayColor(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return _redBase;
      case PlayerColor.green:
        return _greenBase;
      case PlayerColor.yellow:
        return _yellowBase;
      case PlayerColor.blue:
        return _blueBase;
    }
  }

  // Convert PlayerColor enum to string for widgets
  static String getColorString(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return 'red';
      case PlayerColor.green:
        return 'green';
      case PlayerColor.blue:
        return 'blue';
      case PlayerColor.yellow:
        return 'yellow';
    }
  }

  // Convert PlayerColor enum to lighter shade for home areas
  static Color getHomeAreaColor(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return _redBase.withValues(alpha: 0.18);
      case PlayerColor.green:
        return _greenBase.withValues(alpha: 0.18);
      case PlayerColor.blue:
        return _blueBase.withValues(alpha: 0.18);
      case PlayerColor.yellow:
        return _yellowBase.withValues(alpha: 0.18);
    }
  }

  // Convert PlayerColor enum to primary color for paths
  static Color getPrimaryColor(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return _redBase;
      case PlayerColor.green:
        return _greenBase;
      case PlayerColor.blue:
        return _blueBase;
      case PlayerColor.yellow:
        return _yellowBase;
    }
  }
}
