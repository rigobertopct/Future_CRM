import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../animations/animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import 'account.dart';
import 'login_backdrop.dart';
import 'session_store.dart';

/// Primera pantalla de la app. Siempre oscura, como la barra lateral.
///
/// Movimiento: un ciclo ambiental para el fondo y el anillo del logo, una
/// entrada escalonada y un "warp" al entrar. Con "reducir movimiento" todo
/// aparece fijo y la entrada es instantánea.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.session});

  final SessionStore session;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  );
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _warp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;
  String? _error;
  int _failures = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _intro.value = 1;
    } else {
      _ambient.repeat();
      _intro.forward();
    }
  }

  void _onSession() {
    if (!mounted) return;
    if (widget.session.signedIn && !AppMotion.reduced(context)) {
      _warp.forward();
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    for (final step in _steps.values) {
      step.dispose();
    }
    _ambient.dispose();
    _intro.dispose();
    _warp.dispose();
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.session.busy || widget.session.signedIn) return;
    FocusScope.of(context).unfocus();
    final valid = _form.currentState!.validate();
    if (!valid) {
      setState(() {
        _error = null;
        _failures++;
      });
      return;
    }
    setState(() => _error = null);
    final error = await widget.session.signIn(_email.text, _password.text);
    if (!mounted || error == null) return;
    setState(() {
      _error = error;
      _failures++;
    });
  }

  /// Fragmentos de la entrada ya creados. Se guardan para no añadir
  /// oyentes a [_intro] en cada build.
  final Map<(double, double), CurvedAnimation> _steps = {};

  /// Fragmento [start]–[end] de la entrada, con la curva de la app.
  Animation<double> _step(double start, double end) {
    return _steps.putIfAbsent(
      (start, end),
      () => CurvedAnimation(
        parent: _intro,
        curve: Interval(start, end.clamp(start, 1), curve: AppMotion.out),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: SidebarColors.bottom,
          body: Stack(
            children: [
              Positioned.fill(
                child: LoginBackdrop(ambient: _ambient, warp: _warp),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 900;
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 24,
                        ),
                        child: wide ? _wideLayout() : _narrowLayout(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _narrowLayout() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Reveal(
            animation: _step(0, 0.45),
            scaleFrom: 0.6,
            child: _OrbitLogo(ambient: _ambient, size: 76),
          ),
          const SizedBox(height: 20),
          _Reveal(animation: _step(0.12, 0.55), child: const _Title()),
          const SizedBox(height: 8),
          _Reveal(
            animation: _step(0.2, 0.62),
            child: const _Tagline(align: TextAlign.center),
          ),
          const SizedBox(height: 28),
          _card(),
        ],
      ),
    );
  }

  Widget _wideLayout() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1040),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Reveal(
                  animation: _step(0, 0.45),
                  scaleFrom: 0.6,
                  child: _OrbitLogo(ambient: _ambient, size: 88),
                ),
                const SizedBox(height: 28),
                _Reveal(
                  animation: _step(0.12, 0.55),
                  child: const _Title(large: true),
                ),
                const SizedBox(height: 12),
                _Reveal(
                  animation: _step(0.2, 0.62),
                  child: const _Tagline(align: TextAlign.start),
                ),
                const SizedBox(height: 28),
                for (final (i, feature) in _features.indexed)
                  _Reveal(
                    animation: _step(0.3 + i * 0.08, 0.75 + i * 0.08),
                    offset: const Offset(-24, 0),
                    child: _Feature(icon: feature.$1, label: feature.$2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 56),
          SizedBox(width: 420, child: _card()),
        ],
      ),
    );
  }

  static const _features = [
    (Icons.hub_outlined, 'Contactos, leads y clientes en una sola red'),
    (Icons.trending_up, 'Pipeline de oportunidades con historial de etapas'),
    (Icons.bolt_outlined, 'Sincronizado con la versión web en tiempo real'),
  ];

  Widget _card() {
    final session = widget.session;
    final text = Theme.of(context).textTheme;
    final locked = session.busy || session.signedIn;

    return _Reveal(
      animation: _step(0.3, 0.85),
      offset: const Offset(0, 40),
      scaleFrom: 0.96,
      child: Shake(
        trigger: _failures,
        child: _GlowCard(
          ambient: _ambient,
          child: AutofillGroup(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Iniciar sesión', style: text.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Entra con tu cuenta del CRM.',
                    style: text.bodySmall?.copyWith(color: SidebarColors.muted),
                  ),
                  const SizedBox(height: 22),
                  _Reveal(
                    animation: _step(0.45, 0.9),
                    offset: const Offset(0, 12),
                    child: TextFormField(
                      key: const ValueKey('login-email'),
                      controller: _email,
                      enabled: !locked,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.username,
                      ],
                      autocorrect: false,
                      decoration: _decoration(
                        label: 'Correo',
                        icon: Icons.alternate_email,
                      ),
                      validator: (value) => emailError(value ?? ''),
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Reveal(
                    animation: _step(0.5, 0.95),
                    offset: const Offset(0, 12),
                    child: TextFormField(
                      key: const ValueKey('login-password'),
                      controller: _password,
                      focusNode: _passwordFocus,
                      enabled: !locked,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      decoration: _decoration(
                        label: 'Contraseña',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          tooltip: _obscure
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Escribe tu contraseña.';
                        }
                        if (value!.length < SessionStore.minPasswordLength) {
                          return 'Mínimo ${SessionStore.minPasswordLength} '
                              'caracteres.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ),
                  AnimatedSize(
                    duration: AppMotion.reduced(context)
                        ? Duration.zero
                        : AppMotion.base,
                    curve: AppMotion.out,
                    child: _error == null
                        ? const SizedBox(width: double.infinity)
                        : Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Semantics(
                              liveRegion: true,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 18,
                                    color: AppPalette.dark.destructive,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: text.bodySmall?.copyWith(
                                        color: AppPalette.dark.destructive,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 22),
                  _Reveal(
                    animation: _step(0.55, 1),
                    offset: const Offset(0, 12),
                    child: _SubmitButton(
                      busy: session.busy,
                      done: session.signedIn,
                      onPressed: _submit,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Reveal(
                    animation: _step(0.65, 1),
                    child: const _DemoNotice(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: SidebarColors.bottom.withValues(alpha: 0.7),
      border: border(SidebarColors.border),
      enabledBorder: border(SidebarColors.border),
      disabledBorder: border(SidebarColors.border),
      focusedBorder: border(SidebarColors.brand, 1.6),
      floatingLabelStyle: const TextStyle(color: SidebarColors.brand),
    );
  }
}

/// Entrada de un elemento: aparece, se desplaza desde [offset] y escala
/// desde [scaleFrom]. Solo se reconstruye el transform, no el contenido.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.child,
    this.offset = const Offset(0, 16),
    this.scaleFrom = 1,
  });

  final Animation<double> animation;
  final Offset offset;
  final double scaleFrom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = animation.value;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: offset * (1 - t),
            child: Transform.scale(
              scale: scaleFrom + (1 - scaleFrom) * t,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final style =
        (large
                ? Theme.of(context).textTheme.displayMedium
                : Theme.of(context).textTheme.displaySmall)
            ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5);
    return Semantics(
      header: true,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const LinearGradient(
          colors: [SidebarColors.foreground, SidebarColors.brand],
          stops: [0.55, 1],
        ).createShader(bounds),
        child: Text('Future CRM', style: style),
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline({required this.align});

  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Tu pipeline comercial, en tiempo real.',
      textAlign: align,
      style: Theme.of(context).textTheme.bodyLarge
          ?.copyWith(color: SidebarColors.muted),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: SidebarColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: SidebarColors.brand.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(icon, size: 18, color: SidebarColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: SidebarColors.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Logo dorado con un anillo de luz que orbita y un halo que respira.
class _OrbitLogo extends StatelessWidget {
  const _OrbitLogo({required this.ambient, required this.size});

  final Animation<double> ambient;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size * 0.62,
      height: size * 0.62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF7D46A), SidebarColors.brand, Color(0xFFD9A21B)],
        ),
        borderRadius: BorderRadius.circular(size * 0.18),
      ),
      child: Text(
        'N',
        style: AppTypography.mono(
          fontSize: size * 0.3,
          fontWeight: FontWeight.w800,
          color: SidebarColors.brandForeground,
        ),
      ),
    );

    return Semantics(
      label: 'Future CRM',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: AnimatedBuilder(
          animation: ambient,
          child: mark,
          builder: (context, mark) {
            final a = ambient.value * math.pi * 2;
            final breath = 0.5 + 0.5 * math.sin(a * 6);
            return CustomPaint(
              painter: _OrbitPainter(turn: ambient.value * 8),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size * 0.18),
                    boxShadow: [
                      BoxShadow(
                        color: SidebarColors.brand.withValues(
                          alpha: 0.25 + 0.25 * breath,
                        ),
                        blurRadius: 18 + 14 * breath,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: mark,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter({required this.turn});

  /// Vueltas completadas; la parte fraccionaria es el ángulo.
  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final angle = (turn - turn.floorToDouble()) * math.pi * 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SidebarColors.foreground.withValues(alpha: 0.08),
    );
    canvas.drawArc(
      rect,
      angle,
      math.pi * 0.9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: 0,
          endAngle: math.pi * 0.9,
          colors: [
            SidebarColors.brand.withValues(alpha: 0),
            SidebarColors.brand,
          ],
          transform: GradientRotation(angle),
        ).createShader(rect),
    );
    // Satélite en la punta del arco.
    final tip = angle + math.pi * 0.9;
    canvas.drawCircle(
      center + Offset(math.cos(tip), math.sin(tip)) * radius,
      3,
      Paint()..color = SidebarColors.brand,
    );
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) => oldDelegate.turn != turn;
}

/// Tarjeta del formulario con un destello que recorre el borde.
class _GlowCard extends StatelessWidget {
  const _GlowCard({required this.ambient, required this.child});

  final Animation<double> ambient;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _BorderLightPainter(ambient: ambient),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
        decoration: BoxDecoration(
          color: const Color(0xFF191E19).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 40,
              offset: Offset(0, 16),
              spreadRadius: -16,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _BorderLightPainter extends CustomPainter {
  _BorderLightPainter({required this.ambient}) : super(repaint: ambient);

  final Animation<double> ambient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(20));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = SidebarColors.border,
    );
    final angle = ambient.value * math.pi * 2 * 3;
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..shader = SweepGradient(
          colors: [
            SidebarColors.brand.withValues(alpha: 0),
            SidebarColors.brand.withValues(alpha: 0.9),
            SidebarColors.brand.withValues(alpha: 0),
            SidebarColors.brand.withValues(alpha: 0),
          ],
          stops: const [0, 0.08, 0.18, 1],
          transform: GradientRotation(angle),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BorderLightPainter oldDelegate) =>
      oldDelegate.ambient != ambient;
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.busy,
    required this.done,
    required this.onPressed,
  });

  final bool busy;
  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final label = done
        ? 'Bienvenido'
        : busy
        ? 'Verificando…'
        : 'Entrar';
    final Widget content = Row(
      key: ValueKey(label),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: SidebarColors.brandForeground,
            ),
          )
        else if (done)
          const Icon(Icons.check_circle, size: 20)
        else
          const Icon(Icons.arrow_forward, size: 20),
        const SizedBox(width: 10),
        Text(label),
      ],
    );

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: ScaleOnPress(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius),
            gradient: const LinearGradient(
              colors: [Color(0xFFF7D46A), SidebarColors.brand],
            ),
            boxShadow: [
              BoxShadow(
                color: SidebarColors.brand.withValues(alpha: 0.35),
                blurRadius: 22,
                spreadRadius: -6,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FilledButton(
            key: const ValueKey('login-submit'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: SidebarColors.brandForeground,
              disabledForegroundColor: SidebarColors.brandForeground,
              minimumSize: const Size.fromHeight(52),
              textStyle: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            onPressed: busy || done ? null : onPressed,
            child: AnimatedSwitcher(
              duration: reduced ? Duration.zero : AppMotion.base,
              switchInCurve: AppMotion.out,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SidebarColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: SidebarColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 16,
            color: SidebarColors.brand,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Acceso de demostración: cualquier correo válido y una '
              'contraseña de ${SessionStore.minPasswordLength}+ caracteres.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: SidebarColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}
