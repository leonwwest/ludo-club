import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_club/ui/landing_page.dart';

void main() {
  testWidgets('Landing page renders key hero content', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LudoClubLandingPage()));

    expect(find.text('Ludo Club'), findsAtLeastNWidgets(1));
    expect(find.text('Play, Compete, Enjoy.'), findsOneWidget);
    expect(find.text('Quick Play'), findsWidgets);
    expect(find.text('Custom Game'), findsWidgets);
  });
}
