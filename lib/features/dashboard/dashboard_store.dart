import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../settings/settings_store.dart';

enum DashboardPeriod {
  today('Hoy', 8420, 12, 16.8, 12000),
  week('7 días', 52300, 64, 18.1, 70000),
  month('30 días', 214800, 238, 18.4, 250000),
  quarter('90 días', 648900, 702, 19.2, 750000);

  const DashboardPeriod(
    this.label,
    this.revenue,
    this.leads,
    this.conversion,
    this.goal,
  );

  final String label;
  final double revenue;
  final int leads;
  final double conversion;
  final double goal;
}

enum ActivityKind { payment, lead, deal, task }

@immutable
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.at,
  });

  final int id;
  final ActivityKind kind;
  final String title;
  final String detail;
  final DateTime at;
}

/// Métricas del dashboard con simulación en tiempo real.
///
/// Cada [tick] mueve la serie principal, añade un evento al feed y ajusta los
/// KPI. El temporizador solo corre mientras hay un dashboard visible
/// ([attach]/[detach]), la app está en primer plano y los datos en vivo están
/// activados en Configuración.
class DashboardStore extends ChangeNotifier {
  DashboardStore({
    required this._settings,
    math.Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? math.Random(),
       _clock = clock ?? DateTime.now {
    _settings.addListener(_schedule);
    _reset(DashboardPeriod.month);
    _seedFeed();
  }

  static const seriesLength = 30;
  static const sparkLength = 16;
  static const feedLength = 6;

  static const _people = [
    'Valeria Soto',
    'Marcos Ibarra',
    'Paula Reyes',
    'Hugo Navarro',
    'Lucía Fernández',
    'Tomás Cárdenas',
    'Irene Montalvo',
    'Daniela Ruiz',
  ];
  static const _companies = [
    'Grupo Aurelia',
    'Nexora Labs',
    'Veltrix Logística',
    'Solaris Energía',
    'Kairos Retail',
    'Orbita Fintech',
  ];
  static const _sources = ['Web', 'Referido', 'Evento', 'LinkedIn', 'Email'];

  final SettingsStore _settings;
  final math.Random _random;
  final DateTime Function() _clock;

  Timer? _timer;
  bool _attached = false;
  bool _foreground = true;
  int _nextEventId = 0;

  DashboardPeriod period = DashboardPeriod.month;

  /// Cuenta cada actualización; los widgets la usan para disparar destellos.
  int ticks = 0;

  double revenue = 0;
  int leads = 0;
  double conversion = 0;
  double _pipelineDrift = 0;

  List<double> series = const [];
  List<double> revenueSpark = const [];
  List<double> leadsSpark = const [];
  List<double> conversionSpark = const [];
  List<double> pipelineSpark = const [];
  final List<ActivityEvent> feed = [];

  /// `true` mientras el temporizador está corriendo.
  bool get live => _timer != null;

  DateTime get now => _clock();

  double get goalProgress => (revenue / period.goal).clamp(0, 1.5);

  /// Deriva respecto al valor real del pipeline (que vive en otro store).
  double get pipelineDrift => _pipelineDrift;

  void setPeriod(DashboardPeriod value) {
    if (value == period) return;
    _reset(value);
    ticks++;
    notifyListeners();
  }

  void attach() {
    _attached = true;
    // Se llama desde initState: no notificar mientras se construye el árbol.
    _schedule(notify: false);
  }

  void detach() {
    _attached = false;
    _timer?.cancel();
    _timer = null;
  }

  /// La app pasa a segundo plano: se pausa para no gastar batería.
  void setForeground(bool value) {
    if (_foreground == value) return;
    _foreground = value;
    _schedule();
  }

  void _schedule({bool notify = true}) {
    _timer?.cancel();
    _timer = null;
    if (_attached && _foreground && _settings.liveUpdates) {
      _timer = Timer.periodic(
        Duration(seconds: _settings.speed.seconds),
        (_) => tick(),
      );
    }
    if (notify) notifyListeners();
  }

  /// Avanza la simulación un paso. Público para poder probarlo sin esperar.
  void tick() {
    final r = _random;
    final roll = r.nextDouble();
    if (roll < 0.45) {
      final amount = (300 + r.nextInt(2400)).toDouble();
      revenue += amount;
      _push(
        ActivityKind.payment,
        'Pago recibido',
        '${_pick(_companies)} · \$${amount.round()}',
      );
    } else if (roll < 0.7) {
      leads += 1;
      _push(
        ActivityKind.lead,
        'Nuevo lead',
        '${_pick(_people)} · ${_pick(_sources)}',
      );
    } else if (roll < 0.9) {
      final value = (1500 + r.nextInt(9000)).toDouble();
      _pipelineDrift += value;
      _push(
        ActivityKind.deal,
        'Oportunidad creada',
        '${_pick(_companies)} · \$${value.round()}',
      );
    } else {
      _push(
        ActivityKind.task,
        'Tarea completada',
        'Seguimiento · ${_pick(_people)}',
      );
    }

    conversion = (conversion + (r.nextDouble() - 0.5) * 0.4).clamp(12.0, 28.0);

    final level = period.revenue / seriesLength;
    final next = (series.last + (r.nextDouble() - 0.5) * level * 0.5).clamp(
      level * 0.4,
      level * 1.9,
    );
    series = [...series.skip(1), next];
    revenueSpark = _roll(revenueSpark, revenue);
    leadsSpark = _roll(leadsSpark, leads.toDouble());
    conversionSpark = _roll(conversionSpark, conversion);
    pipelineSpark = _roll(pipelineSpark, 1000 + _pipelineDrift);

    ticks++;
    notifyListeners();
  }

  List<double> _roll(List<double> source, double value) => [
    ...source.skip(1),
    value,
  ];

  String _pick(List<String> list) => list[_random.nextInt(list.length)];

  void _push(ActivityKind kind, String title, String detail) {
    feed.insert(
      0,
      ActivityEvent(
        id: _nextEventId++,
        kind: kind,
        title: title,
        detail: detail,
        at: _clock(),
      ),
    );
    if (feed.length > feedLength) feed.removeLast();
  }

  void _seedFeed() {
    final base = _clock();
    final seed = [
      (
        ActivityKind.task,
        'Tarea completada',
        'Seguimiento · Hugo Navarro',
        140,
      ),
      (ActivityKind.deal, 'Oportunidad creada', 'Kairos Retail · \$6400', 95),
      (ActivityKind.lead, 'Nuevo lead', 'Irene Montalvo · Web', 52),
      (ActivityKind.payment, 'Pago recibido', 'Nexora Labs · \$1840', 18),
    ];
    for (final (kind, title, detail, secondsAgo) in seed) {
      feed.insert(
        0,
        ActivityEvent(
          id: _nextEventId++,
          kind: kind,
          title: title,
          detail: detail,
          at: base.subtract(Duration(seconds: secondsAgo)),
        ),
      );
    }
  }

  void _reset(DashboardPeriod value) {
    period = value;
    revenue = value.revenue;
    leads = value.leads;
    conversion = value.conversion;
    _pipelineDrift = 0;

    final seeded = math.Random(value.index * 97 + 13);
    final level = value.revenue / seriesLength;
    series = List<double>.generate(
      seriesLength,
      (i) =>
          level *
          (1 + 0.35 * math.sin(i / 3.2) + (seeded.nextDouble() - 0.5) * 0.3),
    );
    List<double> trail(double end, double spread) => List<double>.generate(
      sparkLength,
      (i) =>
          end *
          (1 -
              spread * (sparkLength - 1 - i) / sparkLength +
              (seeded.nextDouble() - 0.5) * spread * 0.4),
    );
    revenueSpark = trail(revenue, 0.18);
    leadsSpark = trail(leads.toDouble(), 0.22);
    conversionSpark = trail(conversion, 0.1);
    pipelineSpark = trail(1000, 0.2);
  }

  @override
  void dispose() {
    _settings.removeListener(_schedule);
    _timer?.cancel();
    super.dispose();
  }
}
