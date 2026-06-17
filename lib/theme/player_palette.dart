import 'package:flutter/material.dart';
import 'package:ludo_club/models/ludo_models.dart';

extension PlayerPalette on PlayerColor {
  Color get paint {
    return switch (this) {
      PlayerColor.red => const Color(0xFFE74C4C),
      PlayerColor.green => const Color(0xFF159A6A),
      PlayerColor.yellow => const Color(0xFFE3A72F),
      PlayerColor.blue => const Color(0xFF2D6CDF),
    };
  }

  Color get ink {
    return switch (this) {
      PlayerColor.yellow => const Color(0xFF211A0A),
      _ => Colors.white,
    };
  }
}
