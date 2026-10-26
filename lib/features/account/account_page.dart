import 'package:flutter/material.dart';

import '../../animations/animations.dart';
import '../../app/crm_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/feedback.dart';
import '../../shared/widgets/page_frame.dart';
import '../../shared/widgets/status_chip.dart';
import '../../shared/widgets/surface_card.dart';
import '../auth/account.dart';
import '../auth/session_store.dart';

/// Perfil propio (`actualizar_cuenta`), sesión y borrado de la cuenta
/// (`eliminar_cuenta`).
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = CrmScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final profile = session.profile;
        if (profile == null) return const SizedBox.shrink();
        return PageFrame(
          title: 'Cuenta',
          subtitle: 'Tu perfil y tu sesión',
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            children: staggerWidgets([
              _Identity(profile: profile, demo: session.demo),
              const _SectionTitle('Datos personales'),
              _ProfileForm(session: session, profile: profile),
              const _SectionTitle('Sesión'),
              _SessionCard(session: session),
              const _SectionTitle('Zona de peligro'),
              _DangerZone(session: session),
            ]),
          ),
        );
      },
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.profile, required this.demo});

  final AccountProfile profile;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  SidebarColors.brand,
                  Color(0xFFF7D46A),
                  Color(0xFFD9A21B),
                  SidebarColors.brand,
                ],
              ),
            ),
            child: CircleAvatar(
              backgroundColor: palette.card,
              child: Text(
                profile.initials,
                style: AppTypography.mono(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: palette.foreground,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName,
                  key: const ValueKey('account-name'),
                  style: text.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.mono(
                    fontSize: 12,
                    color: palette.mutedForeground,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusChip(
                      label: profile.role,
                      color: Tones.info(context),
                      icon: Icons.badge_outlined,
                    ),
                    if (demo)
                      StatusChip(
                        label: 'Demostración',
                        color: Tones.warning(context),
                        icon: Icons.science_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({required this.session, required this.profile});

  final SessionStore session;
  final AccountProfile profile;

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.profile.firstName);
  late final _last = TextEditingController(text: widget.profile.lastName);
  late final _email = TextEditingController(text: widget.profile.email);
  late final _phone = TextEditingController(text: widget.profile.phone);

  List<TextEditingController> get _all => [_first, _last, _email, _phone];

  AccountProfile get _draft => widget.profile.copyWith(
    firstName: _first.text.trim(),
    lastName: _last.text.trim(),
    email: _email.text.trim(),
    phone: _phone.text.trim(),
  );

  bool get _dirty {
    final p = widget.profile;
    final d = _draft;
    return d.firstName != p.firstName ||
        d.lastName != p.lastName ||
        d.email != p.email ||
        d.phone != p.phone;
  }

  @override
  void initState() {
    super.initState();
    for (final controller in _all) {
      controller.addListener(_changed);
    }
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    for (final controller in _all) {
      controller.dispose();
    }
    super.dispose();
  }

  void _discard() {
    final p = widget.profile;
    _first.text = p.firstName;
    _last.text = p.lastName;
    _email.text = p.email;
    _phone.text = p.phone;
    _form.currentState?.reset();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final error = await widget.session.updateProfile(_draft);
    if (!mounted) return;
    showMessage(context, error ?? 'Perfil actualizado.');
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.session.busy;
    final dirty = _dirty;
    return SurfaceCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 14,
              children: [
                _field(
                  'account-first',
                  _first,
                  'Nombre *',
                  validator: (v) =>
                      v.trim().isEmpty ? 'Escribe tu nombre.' : null,
                ),
                _field('account-last', _last, 'Apellidos'),
                _field(
                  'account-email',
                  _email,
                  'Correo *',
                  keyboard: TextInputType.emailAddress,
                  validator: emailError,
                ),
                _field(
                  'account-phone',
                  _phone,
                  'Teléfono',
                  keyboard: TextInputType.phone,
                  validator: (v) =>
                      v.trim().isEmpty ||
                          RegExp(r'^\+?[\d\s()-]{6,}$').hasMatch(v.trim())
                      ? null
                      : 'Ese teléfono no parece válido.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (dirty)
                  TextButton(
                    onPressed: busy ? null : _discard,
                    child: const Text('Descartar'),
                  ),
                ScaleOnPress(
                  child: FilledButton.icon(
                    key: const ValueKey('account-save'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    onPressed: dirty && !busy ? _save : null,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String key,
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String value)? validator,
  }) {
    // Dos columnas cuando hay sitio; una en teléfonos.
    final width = MediaQuery.sizeOf(context).width >= 720
        ? 300.0
        : double.infinity;
    return SizedBox(
      width: width,
      child: TextFormField(
        key: ValueKey(key),
        controller: controller,
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        enabled: !widget.session.busy,
        decoration: InputDecoration(labelText: label),
        validator: validator == null ? null : (v) => validator(v ?? ''),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session});

  final SessionStore session;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final message = Row(
      children: [
        Icon(Icons.devices_outlined, color: palette.mutedForeground),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Sesión iniciada en este dispositivo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
    final button = OutlinedButton.icon(
      key: const ValueKey('sign-out'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: session.busy ? null : session.signOut,
      icon: const Icon(Icons.logout, size: 18),
      label: const Text('Cerrar sesión'),
    );
    return SurfaceCard(
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 480
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [message, const SizedBox(height: 12), button],
              )
            : Row(
                children: [
                  Expanded(child: message),
                  const SizedBox(width: 12),
                  button,
                ],
              ),
      ),
    );
  }
}

class _DangerZone extends StatelessWidget {
  const _DangerZone({required this.session});

  final SessionStore session;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await Navigator.of(context)
        .push<bool>(SlideUpRoute(builder: (context) => const _DeleteDialog()));
    if (confirmed != true || !context.mounted) return;
    final error = await session.deleteAccount();
    if (error != null && context.mounted) showMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.destructive.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.destructive.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Eliminar cuenta', style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            session.demo
                ? 'No disponible en la sesión de demostración: borraría la '
                      'cuenta de pruebas que comparten todos.'
                : 'Borra tu cuenta y cierra la sesión. No se puede deshacer.',
            style: text.bodySmall?.copyWith(color: palette.mutedForeground),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('delete-account'),
            style: FilledButton.styleFrom(
              backgroundColor: palette.destructive,
              foregroundColor: palette.destructiveForeground,
              minimumSize: const Size(48, 48),
            ),
            onPressed: session.demo || session.busy
                ? null
                : () => _delete(context),
            icon: const Icon(Icons.delete_forever_outlined, size: 18),
            label: const Text('Eliminar mi cuenta'),
          ),
        ],
      ),
    );
  }
}

/// Pide escribir la palabra de confirmación antes de borrar.
class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog();

  static const word = 'ELIMINAR';

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final ready = _controller.text.trim() == _DeleteDialog.word;
    return AlertDialog(
      title: const Text('¿Eliminar tu cuenta?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Se borrará tu cuenta del CRM y se cerrará la sesión. '
            'Esta acción no se puede deshacer.',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('delete-confirm'),
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Escribe ${_DeleteDialog.word} para confirmar',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('delete-account-confirm'),
          style: FilledButton.styleFrom(
            backgroundColor: palette.destructive,
            foregroundColor: palette.destructiveForeground,
          ),
          onPressed: ready ? () => Navigator.pop(context, true) : null,
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppPalette.of(context).mutedForeground,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
