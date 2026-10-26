import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_effects.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_typography.dart';
import '../account/account_page.dart';
import '../auth/session_store.dart';
import '../clients/clients_page.dart';
import '../dashboard/dashboard_page.dart';
import '../invoices/invoices_page.dart';
import '../leads/leads_page.dart';
import '../opportunities/opportunities_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import '../tasks/tasks_page.dart';

class CrmShell extends StatefulWidget {
  const CrmShell({super.key});

  @override
  State<CrmShell> createState() => _CrmShellState();
}

class _CrmShellState extends State<CrmShell> {
  final _search = TextEditingController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarCollapsed = false;
  CrmSection? _shownSection;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final crm = CrmScope.of(context);
    return ListenableBuilder(
      listenable: crm,
      builder: (context, _) => _buildShell(context, crm),
    );
  }

  Widget _pageFor(CrmSection section) => switch (section) {
    CrmSection.dashboard => const DashboardPage(),
    CrmSection.leads => LeadsPage(),
    CrmSection.clients => const ClientsPage(),
    CrmSection.opportunities => const OpportunitiesPage(),
    CrmSection.tasks => const TasksPage(),
    CrmSection.invoices => const InvoicesPage(),
    CrmSection.reports => const ReportsPage(),
    CrmSection.account => const AccountPage(),
    CrmSection.settings => const SettingsPage(),
  };

  Widget _buildShell(BuildContext context, CrmController crm) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final palette = AppPalette.of(context);

    // Al cambiar de vista, el buscador empieza vacío en la nueva.
    if (_shownSection != crm.section) {
      final first = _shownSection == null;
      _shownSection = crm.section;
      if (!first) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _search.clear();
          crm.clearSearch();
        });
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.background,
      drawer: wide
          ? null
          : Drawer(
              backgroundColor: SidebarColors.bottom,
              child: _Sidebar(
                crm: crm,
                collapsed: false,
                onSelect: () => Navigator.pop(context),
              ),
            ),
      body: Row(
        children: [
          if (wide)
            _Sidebar(crm: crm, collapsed: _sidebarCollapsed, onSelect: () {}),
          Expanded(
            child: SafeArea(
              left: false,
              right: false,
              child: Column(
                children: [
                  _TopBar(
                    search: _search,
                    section: crm.section,
                    onQuery: crm.search,
                    onMenu: () {
                      if (wide) {
                        setState(() => _sidebarCollapsed = !_sidebarCollapsed);
                      } else {
                        _scaffoldKey.currentState?.openDrawer();
                      }
                    },
                    onTheme: crm.toggleTheme,
                  ),
                  Expanded(
                    child: ViewTransition(
                      index: crm.section.index,
                      child: _pageFor(crm.section),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.search,
    required this.section,
    required this.onQuery,
    required this.onMenu,
    required this.onTheme,
  });

  final TextEditingController search;
  final CrmSection section;
  final ValueChanged<String> onQuery;
  final VoidCallback onMenu;
  final VoidCallback onTheme;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: palette.background,
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Mostrar u ocultar el menú',
              onPressed: onMenu,
              icon: const Icon(Icons.menu),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TextField(
                  controller: search,
                  onChanged: onQuery,
                  enabled: section.searchable,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: section.searchHint,
                    prefixIcon: Icon(
                      Icons.search,
                      size: 18,
                      color: palette.mutedForeground,
                    ),
                    filled: true,
                    fillColor: palette.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Cambiar tema',
              onPressed: onTheme,
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.crm,
    required this.collapsed,
    required this.onSelect,
  });

  final CrmController crm;
  final bool collapsed;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final width = collapsed ? 76.0 : 248.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: width,
      decoration: const BoxDecoration(
        gradient: SidebarColors.background,
        border: Border(right: BorderSide(color: SidebarColors.border)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Brand(collapsed: collapsed),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _SectionLabel('Principal', collapsed: collapsed),
                  for (final section in CrmSection.values.where(
                    (section) => !section.isSystem,
                  ))
                    _NavTile(
                      section: section,
                      selected: crm.section == section,
                      collapsed: collapsed,
                      onTap: () {
                        crm.open(section);
                        onSelect();
                      },
                    ),
                  const SizedBox(height: 16),
                  _SectionLabel('Sistema', collapsed: collapsed),
                  for (final section in const [
                    CrmSection.account,
                    CrmSection.settings,
                  ])
                    _NavTile(
                      section: section,
                      selected: crm.section == section,
                      collapsed: collapsed,
                      onTap: () {
                        crm.open(section);
                        onSelect();
                      },
                    ),
                ],
              ),
            ),
            _UserChip(
              session: crm.session,
              collapsed: collapsed,
              onTap: () {
                crm.open(CrmSection.account);
                onSelect();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.collapsed});

  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SidebarColors.brand,
              borderRadius: BorderRadius.circular(10),
              boxShadow: AppEffects.glow(SidebarColors.brand, strength: 0.5),
            ),
            child: Text(
              'N',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: SidebarColors.brandForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Future CRM',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: SidebarColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'v1.0',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: SidebarColors.subtle),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.collapsed});

  final String label;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: SidebarColors.subtle, letterSpacing: 0.8),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.section,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final CrmSection section;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SidebarColors.activeForeground
        : SidebarColors.muted;
    const accent = SidebarColors.brand;
    final duration = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.base;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        selected: selected,
        button: true,
        child: AnimatedContainer(
          duration: duration,
          curve: AppMotion.out,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: selected
                  ? const [SidebarColors.activeStart, SidebarColors.activeEnd]
                  : [
                      SidebarColors.activeStart.withValues(alpha: 0),
                      SidebarColors.activeEnd.withValues(alpha: 0),
                    ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 0 : 12,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: collapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.12 : 1,
                      duration: duration,
                      curve: AppMotion.out,
                      child: Icon(
                        section.icon,
                        size: 18,
                        color: selected ? accent : color,
                      ),
                    ),
                    if (!collapsed) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          section.label,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: color,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserChip extends StatelessWidget {
  const _UserChip({
    required this.session,
    required this.collapsed,
    required this.onTap,
  });

  final SessionStore session;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => _chip(context),
    );
  }

  Widget _chip(BuildContext context) {
    final profile = session.profile;
    if (profile == null) return const SizedBox.shrink();
    final initials = profile.initials;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        color: SidebarColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: SidebarColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            button: true,
            label: 'Abrir cuenta de ${profile.fullName}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: SidebarColors.brand.withValues(
                      alpha: 0.18,
                    ),
                    child: Text(
                      initials,
                      style: AppTypography.mono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SidebarColors.brand,
                      ),
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: SidebarColors.foreground),
                          ),
                          Text(
                            profile.role,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: SidebarColors.subtle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
