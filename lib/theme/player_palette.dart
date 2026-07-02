import 'package:flutter/material.dart';
import 'package:ludo_club/constants/app_colors.dart';
import 'package:ludo_club/models/ludo_models.dart';

extension PlayerPalette on PlayerColor {
  Color get paint {
    return switch (this) {
      PlayerColor.red => AppColors.red,
      PlayerColor.green => AppColors.green,
      PlayerColor.yellow => AppColors.amber,
      PlayerColor.blue => AppColors.blue,
    };
  }

  Color get ink {
    return switch (this) {
      PlayerColor.yellow => AppColors.yellowInk,
      _ => Colors.white,
    };
  }
}
