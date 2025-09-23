import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/constants/game_constants.dart';
import 'package:ludo_club/logic/ludo_path.dart';

void main() {
  test('LudoPath has 52 unique coordinates with expected anchors', () {
    expect(LudoPath.coords.length, 52);
    final seen = <String>{};
    for (int i = 0; i < LudoPath.coords.length; i++) {
      final g = LudoPath.coords[i];
      final key = '${g.dx},${g.dy}';
      expect(seen.contains(key), isFalse,
          reason: 'Duplicate at index $i: $key');
      seen.add(key);
    }

    // Check key indices exist and are distinct
    expect(LudoPath.coords[0], isNotNull); // Red start
    expect(LudoPath.coords[13], isNotNull); // Green start
    expect(LudoPath.coords[26], isNotNull); // Blue start
    expect(LudoPath.coords[39], isNotNull); // Yellow start

    expect(LudoPath.coords[12], isNotNull); // Green entry
    expect(LudoPath.coords[25], isNotNull); // Blue entry
    expect(LudoPath.coords[38], isNotNull); // Yellow entry
    expect(LudoPath.coords[51], isNotNull); // Red entry

    expect(LudoPath.coords[0], const Offset(6, 13));
    expect(LudoPath.coords[13], const Offset(1, 6));
    expect(LudoPath.coords[26], const Offset(8, 1));
    expect(LudoPath.coords[39], const Offset(13, 8));

    expect(LudoPath.coords[12], const Offset(0, 6));
    expect(LudoPath.coords[25], const Offset(8, 0));
    expect(LudoPath.coords[38], const Offset(14, 8));
    expect(LudoPath.coords[51], const Offset(6, 14));

    expect(
        GameConstants.safeMainPathFields,
        containsAll(<int>{
          0,
          5,
          13,
          18,
          26,
          31,
          39,
          44,
        }));
  });
}
