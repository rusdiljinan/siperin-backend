import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/widgets/user_avatar.dart';

void main() {
  testWidgets('shows the standard user icon without loading a profile image', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: UserAvatar(size: 104)));

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
