import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:future_crm/app/crm_controller.dart';
import 'package:future_crm/features/auth/account.dart';
import 'package:future_crm/features/auth/login_page.dart';
import 'package:future_crm/features/auth/session_store.dart';
import 'package:future_crm/features/shell/crm_shell.dart';
import 'package:future_crm/main.dart';
import 'package:google_fonts/google_fonts.dart';

import 'memory_account_api.dart';
import 'memory_leads_api.dart';
import 'memory_opportunities_api.dart';
import 'sample_leads.dart';

Future<void> _pumpApp(
  WidgetTester tester,
  SessionStore session, {
  CrmSection section = CrmSection.dashboard,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MyApp(
      leadsApi: MemoryLeadsApi(sampleLeads),
      opportunitiesApi: MemoryOpportunitiesApi(),
      session: session,
      initialSection: section,
    ),
  );
}

/// Desplaza la lista de Cuenta hasta mostrar entero el botón [key].
Future<void> _reveal(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  // Los campos de texto también tienen Scrollable; el primero es la lista.
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find
        .descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AccountProfile', () {
    test('builds the name from the email', () {
      final profile = AccountProfile.fromEmail('ana.cruz@example.com');
      expect(profile.fullName, 'Ana Cruz');
      expect(profile.initials, 'AC');
      expect(AccountProfile.fromEmail('juan@gmail.com').fullName, 'Juan');
      expect(AccountProfile.fromEmail('123@x.com').fullName, 'Usuario');
    });

    test('sends the actualizar_cuenta fields', () {
      expect(testProfile.toDatos(), {
        'nombre': 'Marta',
        'apellidos': 'Ibáñez',
        'email': 'marta@example.com',
        'telefono': '',
      });
    });
  });

  group('SessionStore', () {
    test('rejects an invalid email or a short password', () async {
      final session = SessionStore(signInDelay: Duration.zero);
      expect(await session.signIn('no-es-correo', '1234'), isNotNull);
      expect(await session.signIn('ana@example.com', '12'), isNotNull);
      expect(session.signedIn, isFalse);
    });

    test('the fictitious login opens a demo session', () async {
      final session = SessionStore(signInDelay: Duration.zero);
      expect(await session.signIn(' Ana.Cruz@Example.com ', '123'), isNull);
      expect(session.signedIn, isTrue);
      expect(session.demo, isTrue);
      expect(session.profile!.email, 'ana.cruz@example.com');

      session.signOut();
      expect(session.signedIn, isFalse);
    });

    test('updateProfile saves only when the API accepts it', () async {
      final ok = MemoryAccountApi();
      final session = signedInSession(api: ok);
      final changed = testProfile.copyWith(firstName: 'Lucía');
      expect(await session.updateProfile(changed), isNull);
      expect(session.profile!.firstName, 'Lucía');
      expect(ok.calls, ['actualizar_cuenta']);

      final failing = signedInSession(api: MemoryAccountApi(fail: true));
      expect(await failing.updateProfile(changed), 'No se pudo guardar');
      expect(failing.profile!.firstName, 'Marta');
      expect(failing.busy, isFalse);
    });

    test('a demo session cannot delete the shared account', () async {
      final api = MemoryAccountApi();
      final session = signedInSession(api: api, demo: true);
      expect(await session.deleteAccount(), isNotNull);
      expect(api.calls, isEmpty);
      expect(session.signedIn, isTrue);
    });

    test('deleteAccount signs out a real session', () async {
      final api = MemoryAccountApi();
      final session = signedInSession(api: api);
      expect(await session.deleteAccount(), isNull);
      expect(api.calls, ['eliminar_cuenta']);
      expect(session.signedIn, isFalse);
    });
  });

  group('Login', () {
    testWidgets('validates, signs in and lands on the app', (tester) async {
      final session = SessionStore(
        api: MemoryAccountApi(),
        signInDelay: const Duration(milliseconds: 300),
      );
      await _pumpApp(tester, session);
      await tester.pump(const Duration(milliseconds: 1600));
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(CrmShell), findsNothing);

      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Escribe tu correo.'), findsOneWidget);
      expect(find.text('Escribe tu contraseña.'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('login-email')),
        'ana.cruz@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password')),
        '123',
      );
      await tester.tap(find.byKey(const ValueKey('login-submit')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Verificando…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      expect(session.signedIn, isTrue);
      // La transición de entrada termina y el login sale del árbol.
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(CrmShell), findsOneWidget);
      expect(session.profile!.fullName, 'Ana Cruz');
    });

    testWidgets('stands still when motion is reduced', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await _pumpApp(tester, SessionStore(signInDelay: Duration.zero));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('Account page', () {
    testWidgets('signing out returns to the login', (tester) async {
      await _pumpApp(tester, signedInSession(), section: CrmSection.account);
      await tester.pumpAndSettle();

      await _reveal(tester, 'sign-out');
      await tester.tap(find.byKey(const ValueKey('sign-out')));
      // Un fotograma para arrancar la transición y otro para terminarla.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(CrmShell), findsNothing);
    });

    testWidgets('deleting needs the confirmation word', (tester) async {
      final api = MemoryAccountApi();
      await _pumpApp(
        tester,
        signedInSession(api: api),
        section: CrmSection.account,
      );
      await tester.pumpAndSettle();

      await _reveal(tester, 'delete-account');
      await tester.tap(find.byKey(const ValueKey('delete-account')));
      await tester.pumpAndSettle();

      final confirm = find.byKey(const ValueKey('delete-account-confirm'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('delete-confirm')),
        'ELIMINAR',
      );
      await tester.pump();
      await tester.tap(confirm);
      // Un fotograma para arrancar la transición y otro para terminarla.
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(api.calls, ['eliminar_cuenta']);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('a demo session cannot start the deletion', (tester) async {
      await _pumpApp(
        tester,
        signedInSession(demo: true),
        section: CrmSection.account,
      );
      await tester.pumpAndSettle();

      await _reveal(tester, 'delete-account');
      final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('delete-account')),
      );
      expect(button.onPressed, isNull);
      expect(find.textContaining('sesión de demostración'), findsOneWidget);
    });
  });
}
