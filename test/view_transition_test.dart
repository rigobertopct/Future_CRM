import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_crm/animations/animations.dart';
import 'package:future_crm/core/theme/app_theme.dart';

Widget _host({required int index, bool disableAnimations = false}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: ViewTransition(index: index, child: Text('vista-$index')),
    ),
  );
}

void main() {
  testWidgets('ViewTransition cross-fades to the new view and settles', (
    tester,
  ) async {
    await tester.pumpWidget(_host(index: 0));
    expect(find.text('vista-0'), findsOneWidget);

    await tester.pumpWidget(_host(index: 1));
    await tester.pump(const Duration(milliseconds: 120));
    // A mitad de la transición conviven la vista saliente y la entrante.
    expect(find.text('vista-0'), findsOneWidget);
    expect(find.text('vista-1'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('vista-0'), findsNothing);
    expect(find.text('vista-1'), findsOneWidget);
  });

  testWidgets('ViewTransition is instant when motion is reduced', (
    tester,
  ) async {
    await tester.pumpWidget(_host(index: 0, disableAnimations: true));
    await tester.pumpWidget(_host(index: 1, disableAnimations: true));
    await tester.pump();

    expect(find.text('vista-0'), findsNothing);
    expect(find.text('vista-1'), findsOneWidget);
  });

  testWidgets('ViewTransition goes backwards without errors', (tester) async {
    await tester.pumpWidget(_host(index: 3));
    await tester.pumpWidget(_host(index: 1));
    await tester.pumpAndSettle();

    expect(find.text('vista-1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
