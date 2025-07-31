import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_objects.dart';

class ColorUtils {
  // Convert PlayerColor enum to display Color for UI
  static Color getDisplayColor(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return Colors.red.shade700;
      case PlayerColor.green:
        return Colors.green.shade700;
      case PlayerColor.yellow:
        return Colors.yellow.shade600;
      case PlayerColor.blue:
        return Colors.blue.shade700;
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
        return Colors.red.shade100;
      case PlayerColor.green:
        return Colors.green.shade100;
      case PlayerColor.blue:
        return Colors.blue.shade100;
      case PlayerColor.yellow:
        return Colors.yellow.shade100;
    }
  }

  // Convert PlayerColor enum to primary color for paths
  static Color getPrimaryColor(PlayerColor playerColor) {
    switch (playerColor) {
      case PlayerColor.red:
        return Colors.red.shade600;
      case PlayerColor.green:
        return Colors.green.shade600;
      case PlayerColor.blue:
        return Colors.blue.shade600;
      case PlayerColor.yellow:
        return Colors.yellow.shade600;
    }
  }
} 