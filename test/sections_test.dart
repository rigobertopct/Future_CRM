import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_crm/app/crm_controller.dart';
import 'package:future_crm/features/clients/clients_store.dart';
import 'package:future_crm/features/dashboard/dashboard_page.dart';
import 'package:future_crm/features/dashboard/dashboard_store.dart';
import 'package:future_crm/features/invoices/invoices_store.dart';
import 'package:future_crm/features/opportunities/opportunities_store.dart';
import 'package:future_crm/main.dart';
import 'package:google_fonts/google_fonts.dart';

import 'memory_account_api.dart';
import 'memory_leads_api.dart';
import 'memory_opportunities_api.dart';
import 'sample_leads.dart';

Future<CrmController> _open(
  WidgetTester tester, {
  CrmSection section = CrmSection.dashboard,
  Size size = const Size(1440, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MyApp(
      leadsApi: MemoryLeadsApi(sampleLeads),
      opportunitiesApi: MemoryOpportunitiesApi(),
      session: signedInSession(),
      initialSection: section,
    ),
  );
  await tester.pumpAndSettle();
  return CrmScope.of(tester.element(find.byType(Scaffold).first));
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('every section renders on a phone without layout errors', (
    tester,
  ) async {
    for (final section in CrmSection.values) {
      await _open(tester, section: section, size: const Size(390, 844));
      expect(tester.takeException(), isNull, reason: '${section.name} @ phone');
      // Desmonta la app antes de abrir la siguiente.
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('every section renders on a wide screen without layout errors', (
    tester,
  ) async {
    for (final section in CrmSection.values) {
      await _open(tester, section: section);
      expect(tester.takeException(), isNull, reason: '${section.name} @ wide');
      await tester.pumpWidget(const SizedBox());
    }
  });

  group('Dashboard', () {
    testWidgets('starts live and updates by itself', (tester) async {
      final crm = await _open(tester);
      expect(find.text('EN VIVO'), findsOneWidget);
      expect(crm.dashboard.ticks, 0);

      await tester.pump(const Duration(seconds: 9));
      await tester.pump(const Duration(seconds: 1));

      expect(crm.dashboard.ticks, greaterThanOrEqualTo(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the pause button stops and resumes the updates', (
      tester,
    ) async {
      final crm = await _open(tester);

      await tester.tap(find.byKey(const ValueKey('live-toggle')));
      await tester.pump();
      expect(find.text('PAUSADO'), findsOneWidget);

      final ticks = crm.dashboard.ticks;
      await tester.pump(const Duration(seconds: 20));
      expect(crm.dashboard.ticks, ticks);

      await tester.tap(find.byKey(const ValueKey('live-toggle')));
      await tester.pump();
      expect(find.text('EN VIVO'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(crm.dashboard.ticks, greaterThan(ticks));
    });

    testWidgets('the period filter changes the metrics', (tester) async {
      final crm = await _open(tester);

      await tester.tap(find.byKey(const ValueKey('chip-7 días')));
      await tester.pumpAndSettle();

      expect(crm.dashboard.period, DashboardPeriod.week);
      expect(crm.dashboard.revenue, DashboardPeriod.week.revenue);
    });

    testWidgets('leaving the dashboard stops its timer', (tester) async {
      final crm = await _open(tester);
      expect(crm.dashboard.live, isTrue);

      crm.open(CrmSection.tasks);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardPage), findsNothing);
      expect(crm.dashboard.live, isFalse);
    });

    testWidgets('the hero quick actions open their section', (tester) async {
      final crm = await _open(tester, size: const Size(390, 844));
      expect(find.text('Ingresos · 30 días'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('hero-tasks')));
      await tester.pumpAndSettle();

      expect(crm.section, CrmSection.tasks);
    });

    testWidgets('tapping the pipeline funnel opens that stage', (tester) async {
      final crm = await _open(tester);

      // El ListView construye las tarjetas al acercarse: hay que desplazarse.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('funnel-proposal')),
        200,
        scrollable: find.descendant(
          of: find.byType(DashboardPage),
          matching: find.byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('funnel-proposal')));
      await tester.pumpAndSettle();

      expect(crm.section, CrmSection.opportunities);
      expect(crm.opportunities.stageFilter, OpportunityStage.proposal);
    });
  });

  group('Clients', () {
    testWidgets('segment chips filter and favorites toggle', (tester) async {
      final crm = await _open(tester, section: CrmSection.clients);
      expect(find.text('Grupo Aurelia'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('chip-Startup')));
      await tester.pumpAndSettle();
      expect(find.text('Pixel Studio'), findsOneWidget);
      expect(find.text('Grupo Aurelia'), findsNothing);

      final before = crm.clients.countFor(const FavoriteClients());
      await tester.tap(find.byKey(const ValueKey('favorite-cl-12')));
      await tester.pump();
      expect(crm.clients.countFor(const FavoriteClients()), before + 1);
    });

    testWidgets('opens the details sheet and changes the status', (
      tester,
    ) async {
      final crm = await _open(tester, section: CrmSection.clients);

      await tester.tap(find.text('Veltrix Logística'));
      await tester.pumpAndSettle();
      expect(find.text('SALUD'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('status-inactive')));
      await tester.pumpAndSettle();

      expect(
        crm.clients.all.firstWhere((c) => c.id == 'cl-3').status.label,
        'Inactivo',
      );
    });
  });

  group('Opportunities', () {
    testWidgets('stage chip filters and advance moves the card', (
      tester,
    ) async {
      final crm = await _open(tester, section: CrmSection.opportunities);

      await tester.tap(find.byKey(const ValueKey('chip-Nueva')));
      await tester.pumpAndSettle();
      expect(find.text('Portal de clientes'), findsOneWidget);
      expect(find.text('Plataforma de analítica'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('advance-op-5')));
      await tester.pumpAndSettle();

      expect(
        crm.opportunities.all.firstWhere((o) => o.id == 'op-5').stage,
        OpportunityStage.qualified,
      );
      expect(find.text('Portal de clientes'), findsNothing);
    });

    testWidgets('the top bar search filters the opportunities', (tester) async {
      await _open(tester, section: CrmSection.opportunities);

      await tester.enterText(find.byType(TextField), 'orbita');
      await tester.pumpAndSettle();

      expect(find.text('Suite de seguridad'), findsOneWidget);
      expect(find.text('Portal de clientes'), findsNothing);
    });

    testWidgets('details sheet edits and records stage notes', (tester) async {
      final crm = await _open(tester, section: CrmSection.opportunities);

      await tester.enterText(find.byType(TextField), 'portal');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Portal de clientes'));
      await tester.pumpAndSettle();
      expect(find.text('HISTORIAL DE ETAPAS'), findsOneWidget);
      expect(find.textContaining('Sin cambios de etapa'), findsOneWidget);

      // Cambiar de etapa con nota la deja en el historial.
      await tester.tap(find.byKey(const ValueKey('change-stage')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('field-note')),
        'Cliente pidió demo',
      );
      await tester.tap(find.byKey(const ValueKey('quick-form-submit')));
      await tester.pumpAndSettle();
      expect(
        crm.opportunities.all.firstWhere((o) => o.id == 'op-5').stage,
        OpportunityStage.qualified,
      );
      expect(find.text('Cliente pidió demo'), findsOneWidget);

      // Editar guarda el nuevo nombre.
      await tester.tap(find.byKey(const ValueKey('edit-opportunity')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('field-name')),
        'Portal B2B',
      );
      await tester.tap(find.byKey(const ValueKey('quick-form-submit')));
      await tester.pumpAndSettle();
      expect(
        crm.opportunities.all.firstWhere((o) => o.id == 'op-5').name,
        'Portal B2B',
      );
      expect(find.text('Cambios guardados.'), findsOneWidget);
    });

    testWidgets('creating an opportunity validates and adds it', (
      tester,
    ) async {
      final crm = await _open(tester, section: CrmSection.opportunities);
      final before = crm.opportunities.all.length;

      await tester.tap(find.byKey(const ValueKey('create-opportunity')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-form-submit')));
      await tester.pumpAndSettle();
      expect(find.text('Escribe nombre.'), findsOneWidget);
      expect(crm.opportunities.all.length, before);

      await tester.enterText(
        find.byKey(const ValueKey('field-name')),
        'Piloto IA',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-company')),
        'Acme',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field-amount')),
        '25000',
      );
      await tester.tap(find.byKey(const ValueKey('quick-form-submit')));
      await tester.pumpAndSettle();

      expect(crm.opportunities.all.length, before + 1);
      // La lista es perezosa y ordena por importe: se busca para verla.
      await tester.enterText(find.byType(TextField), 'piloto');
      await tester.pumpAndSettle();
      expect(find.text('Piloto IA'), findsOneWidget);
    });
  });

  group('Tasks', () {
    testWidgets('filter chips narrow the list and toggling completes a task', (
      tester,
    ) async {
      final crm = await _open(tester, section: CrmSection.tasks);

      await tester.tap(find.byKey(const ValueKey('chip-Vencidas')));
      await tester.pumpAndSettle();
      expect(find.text('Revisar contrato de renovación'), findsOneWidget);
      expect(find.text('Preparar demo de analítica'), findsNothing);

      final overdue = crm.tasks.countFor(crm.tasks.filter);
      await tester.tap(find.byKey(const ValueKey('toggle-tk-4')));
      await tester.pumpAndSettle();

      expect(crm.tasks.countFor(crm.tasks.filter), overdue - 1);
      expect(find.text('Revisar contrato de renovación'), findsNothing);
    });

    testWidgets('swipe deletes and the snackbar can undo it', (tester) async {
      final crm = await _open(tester, section: CrmSection.tasks);
      final pending = crm.tasks.pendingCount;

      await tester.drag(
        find.byKey(const ValueKey('dismiss-tk-1')),
        const Offset(-800, 0),
      );
      await tester.pumpAndSettle();
      expect(crm.tasks.pendingCount, pending - 1);

      await tester.tap(find.byKey(const ValueKey('undo-bar-undo')));
      await tester.pumpAndSettle();
      expect(crm.tasks.pendingCount, pending);
    });
  });

  group('Undo snackbar', () {
    testWidgets('closes by itself after ten seconds if nobody undoes', (
      tester,
    ) async {
      final crm = await _open(tester, section: CrmSection.tasks);
      final pending = crm.tasks.pendingCount;

      await tester.drag(
        find.byKey(const ValueKey('dismiss-tk-1')),
        const Offset(-800, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('undo-bar-undo')), findsOneWidget);

      await tester.pump(const Duration(seconds: 9));
      expect(
        find.byKey(const ValueKey('undo-bar-undo')),
        findsOneWidget,
        reason: 'still inside 10 s',
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('undo-bar-undo')), findsNothing);
      expect(crm.tasks.pendingCount, pending - 1, reason: 'deletion stands');
    });

    testWidgets('the check confirms and dismisses it right away', (
      tester,
    ) async {
      await _open(tester, section: CrmSection.tasks);

      await tester.drag(
        find.byKey(const ValueKey('dismiss-tk-1')),
        const Offset(-800, 0),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('¿Confirmas la eliminación de la tarea'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('undo-bar-confirm')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('undo-bar-undo')), findsNothing);
    });
  });

  group('Invoices', () {
    testWidgets('status chip filters and "Marcar pagada" updates the totals', (
      tester,
    ) async {
      final crm = await _open(tester, section: CrmSection.invoices);

      await tester.tap(find.byKey(const ValueKey('chip-Vencida')));
      await tester.pumpAndSettle();
      expect(find.text('Zenit Motors'), findsOneWidget);
      expect(find.text('Solaris Energía'), findsNothing);

      final overdue = crm.invoices.totalFor(InvoiceStatus.overdue);
      await tester.tap(find.byKey(const ValueKey('pay-in-2052')));
      await tester.pumpAndSettle();

      expect(crm.invoices.totalFor(InvoiceStatus.overdue), overdue - 1800);
    });
  });

  group('Reports', () {
    testWidgets('metric chips and range switch redraw the report', (
      tester,
    ) async {
      await _open(tester, section: CrmSection.reports);
      expect(find.textContaining('últimos 6 meses'), findsOneWidget);

      await tester.tap(find.text('12 meses'));
      await tester.pumpAndSettle();
      expect(find.textContaining('últimos 12 meses'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('chip-Conversión')));
      await tester.pumpAndSettle();
      expect(find.text('PROMEDIO DEL PERIODO'), findsOneWidget);
    });
  });

  group('Settings', () {
    testWidgets('speed and live switches drive the dashboard timer', (
      tester,
    ) async {
      final crm = await _open(tester, section: CrmSection.settings);

      await tester.tap(find.byKey(const ValueKey('speed-fast')));
      await tester.pumpAndSettle();
      expect(crm.settings.speed.seconds, 2);

      await tester.tap(find.byKey(const ValueKey('live-updates')));
      await tester.pumpAndSettle();
      expect(crm.settings.liveUpdates, isFalse);
    });

    testWidgets('reduce motion makes view changes instant', (tester) async {
      final crm = await _open(tester, section: CrmSection.settings);

      await tester.tap(find.byKey(const ValueKey('reduce-motion')));
      await tester.pumpAndSettle();
      expect(crm.settings.reduceMotion, isTrue);

      // La vista que sale conserva la duración con la que se creó, así que el
      // primer cambio tras activar el ajuste aún puede animar al salir.
      crm.open(CrmSection.tasks);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('create-task')), findsOneWidget);

      crm.open(CrmSection.clients);
      await tester.pump();
      await tester.pump();
      // Sin animación no queda la vista anterior montada.
      expect(find.byKey(const ValueKey('create-task')), findsNothing);
      expect(find.byKey(const ValueKey('create-client')), findsOneWidget);
    });

    testWidgets('editing the account updates the sidebar', (tester) async {
      await _open(tester, section: CrmSection.settings);

      await tester.tap(find.byKey(const ValueKey('open-account')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('account-first')),
        'Lucía',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('account-save')));
      await tester.pumpAndSettle();

      expect(find.text('Lucía Ibáñez'), findsWidgets);
      expect(find.text('Perfil actualizado.'), findsOneWidget);
    });
  });
}
