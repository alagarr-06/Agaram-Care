import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_state.dart';
import '../../core/constants/app_localizations.dart';

class AgaramLogo extends ConsumerWidget {
  const AgaramLogo({
    super.key,
    this.size = 40,
    this.showTagline = false,
    this.showText = true,
    this.layoutAxis = Axis.horizontal,
  });

  final double size;
  final bool showTagline;
  final bool showText;
  final Axis layoutAxis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations(ref.watch(selectedLocaleProvider));

    final emblem = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        'à®…',
        style: TextStyle(
          fontSize: size * 0.58,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onPrimaryContainer,
          height: 1,
        ),
      ),
    );

    if (!showText) {
      return emblem;
    }

    final textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: layoutAxis == Axis.horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          l10n.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 2),
          Text(
            l10n.tagline,
            maxLines: 2,
            softWrap: true,
            textAlign: layoutAxis == Axis.horizontal
                ? TextAlign.start
                : TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
        ],
      ],
    );

    if (layoutAxis == Axis.vertical) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          emblem,
          const SizedBox(height: 12),
          textColumn,
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        const SizedBox(width: 10),
        Flexible(child: textColumn),
      ],
    );
  }
}