import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_crm/app/crm_controller.dart';
import 'package:future_crm/features/leads/lead.dart';
import 'package:future_crm/features/leads/leads_page.dart';

import 'sample_leads.dart';

import 'package:future_crm/main.dart';
import 'package:google_fonts/google_fonts.dart';

import 'memory_account_api.dart';
import 'memory_leads_api.dart';
import 'memory_opportunities_api.dart';

void main() {
  test('Lead maps the CRM contact payload', () {
    final lead = Lead.fromJson({
      'id': 'abc',
      'nombre': 'Ruly',
      'apellidos': 'Vega',
      'email': 'ruly@gmail.com',
      'organizacion': 'Marrera',
      'etapa': 'abierto - se intento contactar',
      'estado_comercial': 'lead',
      'tipo': 'persona',
      'interes': 'Bajo',
      'propietario': '123',
      'descripcion': null,
      'eliminado': null,
    });

    expect(lead.fullName, 'Ruly Vega');
    expect(lead.company, 'Marrera');
    expect(lead.interest, 'bajo');
    expect(lead.description, '');
    expect(lead.toUpdateDatos()['id_contacto'], 'abc');
    expect(lead.toUpdateDatos().containsKey('etapa'), isFalse);
    expect(lead.toCreateDatos()['estado_comercial'], 'lead');
    expect(lead.toCreateDatos()['etapa'], 'abierto - se intento contactar');
  });

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Leads page lists the sample pipeline and filters by stage', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MyApp(
        leadsApi: MemoryLeadsApi(sampleLeads),
        opportunitiesApi: MemoryOpportunitiesApi(),
        session: signedInSession(),
        initialSection: CrmSection.leads,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Leads'), findsWidgets);
    expect(find.textContaining('45 en total'), findsOneWidget);
    expect(find.text('Ruly Vega'), findsOneWidget);
    expect(find.text('Jose Diaz'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('stage-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filter-notContacted')));
    await tester.pumpAndSettle();

    expect(find.text('Jose Diaz'), findsOneWidget);
    expect(find.text('Ruly Vega'), findsNothing);
    expect(find.text('1  /  1'), findsOneWidget);
  });

  testWidgets('Creating a lead adds it to the pipeline', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MyApp(
        leadsApi: MemoryLeadsApi(sampleLeads),
        opportunitiesApi: MemoryOpportunitiesApi(),
        session: signedInSession(),
        initialSection: CrmSection.leads,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create-lead')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('lead-first-name')), 'Ana');
    await tester.enterText(find.byKey(const Key('lead-last-name')), 'Cruz');
    await tester.enterText(
      find.byKey(const Key('lead-email')),
      'ana@example.com',
    );
    await tester.tap(find.byKey(const Key('lead-save')));
    await tester.pumpAndSettle();

    expect(find.text('Ana Cruz'), findsOneWidget);
    expect(find.textContaining('46 en total'), findsOneWidget);
  });

  testWidgets('phone layout stays clear of the system bars', (tester) async {
    const size = Size(390, 844);
    const statusBar = 47.0;
    const navigationBar = 34.0;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(
      top: statusBar,
      bottom: navigationBar,
    );
    tester.view.viewPadding = const FakeViewPadding(
      top: statusBar,
      bottom: navigationBar,
    );
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MyApp(
        leadsApi: MemoryLeadsApi(sampleLeads),
        opportunitiesApi: MemoryOpportunitiesApi(),
        session: signedInSession(),
        initialSection: CrmSection.leads,
      ),
    );
    await tester.pumpAndSettle();

    final menu = tester.getRect(find.byTooltip('Mostrar u ocultar el menú'));
    final title = tester.getRect(
      find.descendant(of: find.byType(LeadsPage), matching: find.text('Leads')),
    );
    final pager = tester.getRect(find.text('1  /  5'));

    expect(menu.top, greaterThanOrEqualTo(statusBar));
    expect(title.top, greaterThanOrEqualTo(statusBar));
    expect(pager.bottom, lessThanOrEqualTo(size.height - navigationBar));
  });
}
