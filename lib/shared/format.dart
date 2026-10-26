/// Formatos de número y fecha en español, sin depender de `intl`.
abstract final class Fmt {
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  /// `1234567` -> `1.234.567`.
  static String integer(num value) {
    final digits = value.round().abs().toString();
    final out = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write('.');
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// `$1.234` o, en modo compacto, `$1,2M` / `$340K`.
  static String money(num value, {bool compact = false}) {
    final abs = value.abs();
    if (compact && abs >= 1000000) {
      return '\$${_trim(value / 1000000)}M';
    }
    if (compact && abs >= 1000) {
      return '\$${_trim(value / 1000)}K';
    }
    return '\$${integer(value)}';
  }

  static String percent(num value, {int decimals = 1}) =>
      '${value.toStringAsFixed(decimals).replaceAll('.', ',')}%';

  static String date(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  /// Mes abreviado en minúsculas (1 = ene).
  static String month(int month) => _months[(month - 1) % 12];

  /// Etiqueta relativa a [now]: Hoy, Mañana, Ayer, En 3 d, Hace 2 d.
  static String relativeDay(DateTime d, DateTime now) {
    final days = DateTime(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Mañana';
    if (days == -1) return 'Ayer';
    return days > 0 ? 'En $days d' : 'Hace ${-days} d';
  }

  static String _trim(double v) {
    final text = v.abs() >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    return text.replaceAll('.0', '').replaceAll('.', ',');
  }
}
