import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_crm/animations/animations.dart';
import 'package:future_crm/core/theme/app_theme.dart';
import 'package:future_crm/features/leads/lead_dialogs.dart';

Widget _host(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('SkeletonList', () {
    testWidgets('shows placeholder rows with an accessible label', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const SkeletonList(rows: 3, semanticLabel: 'Cargando leads')),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.bySemanticsLabel('Cargando leads'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('does not animate when motion is reduced', (tester) async {
      await tester.pumpWidget(
        _host(const SkeletonList(rows: 2), disableAnimations: true),
      );

      // Sin animación en curso, pumpAndSettle termina de inmediato.
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('Shake', () {
    Widget shake(int trigger, {bool reduced = false}) => _host(
      Center(
        child: Shake(
          trigger: trigger,
          child: const SizedBox(key: Key('box')),
        ),
      ),
      disableAnimations: reduced,
    );

    testWidgets('moves when the trigger grows and settles back', (
      tester,
    ) async {
      await tester.pumpWidget(shake(0));
      final rest = tester.getTopLeft(find.byKey(const Key('box')));

      await tester.pumpWidget(shake(1));
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        tester.getTopLeft(find.byKey(const Key('box'))).dx,
        isNot(rest.dx),
      );

      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(const Key('box'))), rest);
    });

    testWidgets('stays still when motion is reduced', (tester) async {
      await tester.pumpWidget(shake(0, reduced: true));
      final rest = tester.getTopLeft(find.byKey(const Key('box')));

      await tester.pumpWidget(shake(1, reduced: true));
      await tester.pump(const Duration(milliseconds: 60));

      expect(tester.getTopLeft(find.byKey(const Key('box'))), rest);
    });
  });

  testWidgets('staggerWidgets caps the delay for long lists', (tester) async {
    final widgets = staggerWidgets(
      [for (var i = 0; i < 20; i++) Text('item-$i')],
      step: const Duration(milliseconds: 100),
      maxSteps: 3,
    );

    final delays = [for (final w in widgets) (w as FadeInWidget).delay];
    expect(delays.first, Duration.zero);
    expect(delays[3], const Duration(milliseconds: 300));
    expect(delays.last, const Duration(milliseconds: 300));
  });

  testWidgets('saving an invalid lead form shows the errors and stays open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showLeadForm(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lead-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nombre es obligatorio'), findsOneWidget);
    expect(find.byKey(const Key('lead-save')), findsOneWidget);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
