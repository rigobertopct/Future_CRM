import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/status_chip.dart';
import 'lead.dart';

class LeadAvatar extends StatelessWidget {
  const LeadAvatar({super.key, required this.initials, this.radius = 18});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return CircleAvatar(
      radius: radius,
      backgroundColor: palette.primary.withValues(alpha: 0.14),
      child: Text(
        initials,
        style: AppTypography.mono(
          fontSize: radius * 0.62,
          fontWeight: FontWeight.w600,
          color: palette.primary,
        ),
      ),
    );
  }
}

class InterestBadge extends StatelessWidget {
  const InterestBadge({super.key, required this.interest});

  final LeadInterest? interest;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final color = switch (interest) {
      LeadInterest.high => Tones.warning(context),
      LeadInterest.medium => Tones.info(context),
      LeadInterest.low || null => palette.mutedForeground,
    };
    return _OutlineBadge(label: interest?.label ?? '—', color: color);
  }
}

/// Color de una etapa. Siempre va acompañado de [stageIcon] y del texto.
Color stageColor(BuildContext context, LeadStage stage) {
  final palette = AppPalette.of(context);
  return switch (stage) {
    LeadStage.notContacted => palette.mutedForeground,
    LeadStage.attempted => palette.accentForeground,
    LeadStage.contacted => Tones.info(context),
    LeadStage.disqualified => palette.destructive,
    LeadStage.converted => Tones.success(context),
  };
}

IconData stageIcon(LeadStage stage) => switch (stage) {
  LeadStage.notContacted => Icons.radio_button_unchecked,
  LeadStage.attempted => Icons.phone_missed_outlined,
  LeadStage.contacted => Icons.forum_outlined,
  LeadStage.disqualified => Icons.block,
  LeadStage.converted => Icons.check_circle_outline,
};

class StageBadge extends StatelessWidget {
  const StageBadge({super.key, required this.stage, this.onSelected});

  final LeadStage stage;
  final ValueChanged<LeadStage>? onSelected;

  @override
  Widget build(BuildContext context) {
    final color = stageColor(context, stage);
    final badge = _OutlineBadge(
      label: stage.label,
      color: color,
      leading: Icon(stageIcon(stage), size: 13, color: color),
      trailing: onSelected == null
          ? null
          : Icon(Icons.expand_more, size: 16, color: color),
    );
    if (onSelected == null) return badge;
    return PopupMenuButton<LeadStage>(
      tooltip: 'Cambiar etapa',
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in LeadStage.values)
          PopupMenuItem(value: item, child: Text(item.label)),
      ],
      child: badge,
    );
  }
}

class _OutlineBadge extends StatelessWidget {
  const _OutlineBadge({
    required this.label,
    required this.color,
    this.leading,
    this.trailing,
  });

  final String label;
  final Color color;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 4)],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class CountPill extends StatelessWidget {
  const CountPill({super.key, required this.count, required this.active});

  final int count;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active
            ? palette.primaryForeground.withValues(alpha: 0.18)
            : palette.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: AppTypography.mono(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? palette.primaryForeground : palette.mutedForeground,
        ),
      ),
    );
  }
}
