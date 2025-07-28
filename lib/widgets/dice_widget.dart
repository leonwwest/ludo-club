import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DiceWidget extends StatelessWidget {
  final int value;
  const DiceWidget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/dice/dice_$value.svg',
      width: 64,
      height: 64,
    );
  }
}