import 'package:flutter/material.dart';

import 'app/crm_controller.dart';
import 'core/theme/app_motion.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/auth/session_store.dart';
import 'features/leads/leads_api.dart';
import 'features/opportunities/opportunities_api.dart';
import 'features/shell/crm_shell.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.leadsApi,
    this.opportunitiesApi,
    this.session,
    this.initialSection = CrmSection.dashboard,
  });

  final LeadsApi? leadsApi;
  final OpportunitiesApi? opportunitiesApi;

  /// Sesión inicial. Sin ella la app abre en el login.
  final SessionStore? session;
  final CrmSection initialSection;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final CrmController _crm = CrmController(
    leadsApi: widget.leadsApi,
    opportunitiesApi: widget.opportunitiesApi,
    session: widget.session,
    section: widget.initialSection,
  );
  late bool _signedIn = _crm.session.signedIn;

  @override
  void initState() {
    super.initState();
    _crm.session.addListener(_onSession);
    if (_signedIn) _crm.start();
  }

  /// Los datos se cargan al entrar; al salir se vuelve al dashboard.
  void _onSession() {
    final signedIn = _crm.session.signedIn;
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    if (signedIn) {
      _crm.start();
    } else {
      _crm.clearSearch();
      _crm.open(CrmSection.dashboard);
    }
  }

  @override
  void dispose() {
    _crm.session.removeListener(_onSession);
    _crm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _crm.themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Future CRM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          // "Reducir movimiento" de Configuración se suma al del sistema.
          builder: (context, app) => ListenableBuilder(
            listenable: _crm.settings,
            builder: (context, _) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  disableAnimations:
                      media.disableAnimations || _crm.settings.reduceMotion,
                ),
                child: app!,
              );
            },
          ),
          home: child,
        );
      },
      child: CrmScope(
        controller: _crm,
        child: _AuthGate(crm: _crm),
      ),
    );
  }
}

/// Muestra el login o la app. Al entrar, el login "atraviesa" la pantalla
/// (crece y se desvanece) mientras la app aparece detrás.
class _AuthGate extends StatelessWidget {
  const _AuthGate({required this.crm});

  final CrmController crm;

  static const _loginKey = ValueKey('auth-login');
  static const _appKey = ValueKey('auth-app');

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return ListenableBuilder(
      listenable: crm.session,
      builder: (context, _) {
        final signedIn = crm.session.signedIn;
        return AnimatedSwitcher(
          duration: reduced
              ? Duration.zero
              : const Duration(milliseconds: 1100),
          reverseDuration: reduced
              ? Duration.zero
              : const Duration(milliseconds: 700),
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          transitionBuilder: _transition,
          child: signedIn
              ? const KeyedSubtree(key: _appKey, child: CrmShell())
              : LoginPage(key: _loginKey, session: crm.session),
        );
      },
    );
  }

  /// Estático para que AnimatedSwitcher no rehaga las transiciones en
  /// cada build.
  static Widget _transition(Widget child, Animation<double> animation) {
    if (child.key == _loginKey) {
      // El login sale creciendo hacia el usuario.
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0, 0.6, curve: Curves.easeOut),
        ),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 1.14,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: AppMotion.exit)),
          child: child,
        ),
      );
    }
    final enter = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.35, 1, curve: AppMotion.out),
    );
    return FadeTransition(
      opacity: enter,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(enter),
        child: child,
      ),
    );
  }
}
