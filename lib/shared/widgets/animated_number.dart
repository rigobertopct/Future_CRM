import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Número que cuenta hasta su valor y, cuando [value] cambia, recorre la
/// diferencia en lugar de saltar. La primera vez cuenta desde cero.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduced ? value : 0, end: value),
      duration: reduced ? Duration.zero : duration,
      curve: AppMotion.out,
      builder: (context, current, _) =>
          Text(format(current), style: style, maxLines: 1),
    );
  }
}
