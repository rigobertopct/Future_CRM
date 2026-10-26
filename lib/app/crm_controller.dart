import 'package:flutter/material.dart';

import '../features/auth/session_store.dart';
import '../features/clients/clients_store.dart';
import '../features/dashboard/dashboard_store.dart';
import '../features/invoices/invoices_store.dart';
import '../features/leads/leads_api.dart';
import '../features/leads/leads_store.dart';
import '../features/opportunities/opportunities_api.dart';
import '../features/opportunities/opportunities_store.dart';
import '../features/settings/settings_store.dart';
import '../features/tasks/tasks_store.dart';

enum CrmSection {
  dashboard('Dashboard', Icons.space_dashboard_outlined),
  leads('Leads', Icons.people_alt_outlined),
  clients('Clientes', Icons.badge_outlined),
  opportunities('Oportunidades', Icons.trending_up),
  tasks('Tareas', Icons.task_alt),
  invoices('Facturas', Icons.receipt_long_outlined),
  reports('Reportes', Icons.bar_chart_outlined),
  account('Cuenta', Icons.account_circle_outlined),
  settings('Configuración', Icons.settings_outlined);

  const CrmSection(this.label, this.icon);

  final String label;
  final IconData icon;

  bool get isSystem =>
      this == CrmSection.settings || this == CrmSection.account;

  /// Secciones donde el buscador de la barra superior filtra una lista.
  bool get searchable => switch (this) {
    leads || clients || opportunities || tasks || invoices => true,
    dashboard || reports || account || settings => false,
  };

  String get searchHint => switch (this) {
    leads => 'Buscar leads, empresas, correos...',
    clients => 'Buscar clientes, sectores, contactos...',
    opportunities => 'Buscar oportunidades, empresas, responsables...',
    tasks => 'Buscar tareas o cuentas...',
    invoices => 'Buscar por cliente o número de factura...',
    dashboard ||
    reports ||
    account ||
    settings => 'La búsqueda no aplica a esta vista',
  };
}

class CrmController extends ChangeNotifier {
  CrmController({
    LeadsApi? leadsApi,
    OpportunitiesApi? opportunitiesApi,
    SessionStore? session,
    this.section = CrmSection.dashboard,
    SettingsStore? settingsStore,
    DashboardStore? dashboardStore,
  }) : leads = LeadsStore(api: leadsApi),
       opportunities = OpportunitiesStore(api: opportunitiesApi),
       session = session ?? SessionStore(),
       settings = settingsStore ?? SettingsStore() {
    dashboard = dashboardStore ?? DashboardStore(settings: settings);
    leads.addListener(notifyListeners);
  }

  /// Carga los datos del CRM. Se llama al iniciar sesión.
  void start() {
    leads.refresh();
    opportunities.refresh();
  }

  final LeadsStore leads;
  final SessionStore session;
  final SettingsStore settings;
  late final DashboardStore dashboard;
  final OpportunitiesStore opportunities;
  final ClientsStore clients = ClientsStore();
  final TasksStore tasks = TasksStore();
  final InvoicesStore invoices = InvoicesStore();
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);
  CrmSection section;

  void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
  }

  void open(CrmSection value) {
    if (value == section) return;
    section = value;
    notifyListeners();
  }

  /// Envía el texto del buscador a la lista de la sección activa.
  void search(String query) {
    switch (section) {
      case CrmSection.leads:
        leads.setQuery(query);
      case CrmSection.clients:
        clients.setQuery(query);
      case CrmSection.opportunities:
        opportunities.setQuery(query);
      case CrmSection.tasks:
        tasks.setQuery(query);
      case CrmSection.invoices:
        invoices.setQuery(query);
      case CrmSection.dashboard ||
          CrmSection.reports ||
          CrmSection.account ||
          CrmSection.settings:
        break;
    }
  }

  /// Quita la búsqueda de todas las secciones (al cambiar de vista).
  void clearSearch() {
    leads.setQuery('');
    clients.setQuery('');
    opportunities.setQuery('');
    tasks.setQuery('');
    invoices.setQuery('');
  }

  @override
  void dispose() {
    leads.removeListener(notifyListeners);
    leads.dispose();
    dashboard.dispose();
    opportunities.dispose();
    clients.dispose();
    tasks.dispose();
    invoices.dispose();
    settings.dispose();
    session.dispose();
    themeMode.dispose();
    super.dispose();
  }
}

class CrmScope extends InheritedWidget {
  const CrmScope({super.key, required this.controller, required super.child});

  final CrmController controller;

  static CrmController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CrmScope>();
    assert(scope != null, 'CrmScope is missing above this context');
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(CrmScope oldWidget) =>
      controller != oldWidget.controller;
}
