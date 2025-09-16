import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/logic/ludo_path.dart';

void main() {
  test('LudoPath has 52 unique coordinates with expected anchors', () {
    expect(LudoPath.coords.length, 52);
    final seen = <String>{};
    for (int i = 0; i < LudoPath.coords.length; i++) {
      final g = LudoPath.coords[i];
      final key = '${g.dx},${g.dy}';
      expect(seen.contains(key), isFalse, reason: 'Duplicate at index $i: $key');
      seen.add(key);
    }

    // Check key indices exist and are distinct
    expect(LudoPath.coords[0], isNotNull);   // Red start
    expect(LudoPath.coords[13], isNotNull);  // Green start
    expect(LudoPath.coords[26], isNotNull);  // Blue start
    expect(LudoPath.coords[39], isNotNull);  // Yellow start

    expect(LudoPath.coords[12], isNotNull);  // Green entry
    expect(LudoPath.coords[25], isNotNull);  // Blue entry
    expect(LudoPath.coords[38], isNotNull);  // Yellow entry
    expect(LudoPath.coords[51], isNotNull);  // Red entry
  });
}

