import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../widgets/item_thumb.dart';
import 'item_detail_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final theme = Theme.of(context);
    final items = store.items;
    final totalValue = items.fold<double>(
      0,
      (sum, item) => sum + (item.price ?? 0),
    );
    final byWear = items.where((item) => store.wearCount(item.id) > 0).toList()
      ..sort((a, b) => store.wearCount(b.id).compareTo(store.wearCount(a.id)));
    final priced =
        items
            .where((item) => item.price != null && store.wearCount(item.id) > 0)
            .toList()
          ..sort(
            (a, b) => store.costPerWear(a)!.compareTo(store.costPerWear(b)!),
          );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                wide ? 36 : 20,
                wide ? 36 : 24,
                wide ? 36 : 20,
                36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('WARDROBE INSIGHTS'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('衣橱洞察'),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontSize: wide ? 34 : 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('从每一次穿着里，发现更适合自己的衣橱。'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 28),
                      LayoutBuilder(
                        builder: (context, metricConstraints) {
                          final columns = metricConstraints.maxWidth >= 760
                              ? 4
                              : 2;
                          return GridView(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 14,
                                  crossAxisSpacing: 14,
                                  mainAxisExtent: wide ? 154 : 148,
                                ),
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _MetricCard(
                                label: context.tr('衣橱单品'),
                                value: context.number(items.length),
                                unit: context.tr('件'),
                                description: context.tr('属于你的日常选择'),
                                icon: Icons.checkroom_outlined,
                              ),
                              _MetricCard(
                                label: context.tr('衣橱总价值'),
                                value: context.money(totalValue),
                                description: context.tr('已填写价格的单品'),
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                              _MetricCard(
                                label: context.tr('30 天利用率'),
                                value: context.number(
                                  (store.utilization30 * 100).round(),
                                ),
                                unit: '%',
                                description: context.tr('近 30 天穿过的单品占比'),
                                icon: Icons.pie_chart_outline_rounded,
                                highlighted: true,
                              ),
                              _MetricCard(
                                label: context.tr('待重新发现'),
                                value: context.number(
                                  store.forgottenItems.length,
                                ),
                                unit: context.tr('件'),
                                description: context.tr('{days} 天及以上未穿', {
                                  'days': context.number(store.forgottenDays),
                                }),
                                icon: Icons.bedtime_outlined,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _PanelPair(
                        first: _Heatmap(store: store),
                        second: _CategoryDistribution(items: items),
                      ),
                      const SizedBox(height: 24),
                      _PanelPair(
                        first: _RankingPanel(
                          title: context.tr('反复喜欢的单品'),
                          subtitle: context.tr('最常穿 Top 5 · 每一次出场都算数'),
                          items: byWear.take(5).toList(),
                          store: store,
                          emptyIcon: Icons.favorite_border_rounded,
                          emptyTitle: context.tr('喜欢，会在穿着中留下痕迹'),
                          emptyDescription: context.tr('记录一次穿搭后，这里就会出现你的常穿单品。'),
                        ),
                        second: _RankingPanel(
                          title: context.tr('越穿，越值得'),
                          subtitle: context.tr('单次成本最低 Top 3'),
                          items: priced.take(3).toList(),
                          store: store,
                          costRanking: true,
                          emptyIcon: Icons.savings_outlined,
                          emptyTitle: context.tr('好衣服，值得多穿几次'),
                          emptyDescription: context.tr(
                            '为单品填写价格并记录穿着，即可查看单次成本。',
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          context.tr('WEAR MORE. WASTE LESS.'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: .65),
                            letterSpacing: 2.2,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    this.unit,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final String? unit;
  final String description;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final background = highlighted ? scheme.primary : scheme.surface;
    final foreground = highlighted ? scheme.onPrimary : scheme.onSurface;
    final secondary = highlighted
        ? scheme.onPrimary.withValues(alpha: .74)
        : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: highlighted
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: .65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: secondary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: secondary,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: foreground,
                    fontSize: 32,
                    height: 1,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    unit!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: secondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelPair extends StatelessWidget {
  const _PanelPair({required this.first, required this.second});
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth >= 850
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 20),
              Expanded(child: second),
            ],
          )
        : Column(children: [first, const SizedBox(height: 20), second]),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: .65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              if (trailing != null)
                Flexible(
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing!,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.store});
  final WardrobeStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = dateOnly(store.now);
    final start = today.subtract(const Duration(days: 34));
    final days = List.generate(35, (index) => start.add(Duration(days: index)));
    final recorded = days.where((day) => store.logOn(day) != null).length;
    return _Panel(
      title: context.tr('穿着日历'),
      subtitle: context.tr('最近 35 天 · 把每一天的穿着，留成习惯'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          context.tr('{count} 天记录', {'count': recorded}),
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        DateFormat.E(context.l10n.locale.toLanguageTag())
                            .format(start.add(Duration(days: column))),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var week = 0; week < 5; week++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  for (var column = 0; column < 7; column++)
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = days[week * 7 + column];
                          final log = store.logOn(day);
                          final count = log?.itemIds.length ?? 0;
                          final isToday = day == today;
                          final shade = count == 0
                              ? scheme.surfaceContainerLow
                              : Color.lerp(
                                  scheme.primary.withValues(alpha: .16),
                                  scheme.primary,
                                  (count / 6).clamp(0.0, 1.0),
                                )!;
                          final fill = Color.alphaBlend(shade, scheme.surface);
                          return Tooltip(
                            message:
                                '${context.date(day)} · ${count == 0 ? context.tr('未记录') : context.tr('{count} 件单品', {'count': count})}',
                            child: Container(
                              height: 34,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: fill,
                                borderRadius: BorderRadius.circular(8),
                                border: isToday
                                    ? Border.all(
                                        color: scheme.primary,
                                        width: 1.5,
                                      )
                                    : null,
                              ),
                              child: Text(
                                context.number(day.day),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: count == 0
                                      ? scheme.onSurfaceVariant
                                      : fill.computeLuminance() > .4
                                      ? const Color(0xFF263C30)
                                      : Colors.white,
                                  fontSize: 11,
                                  fontWeight: isToday ? FontWeight.w700 : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${context.date(start)} — ${context.date(today)}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('少'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 6),
                  for (final opacity in [0.12, 0.35, 0.65, 1.0])
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsetsDirectional.only(end: 4),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: opacity),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  Text(
                    context.tr('多'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 10,
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

const _categoryColors = [
  Color(0xFF496650),
  Color(0xFF7E9681),
  Color(0xFFB4C2A3),
  Color(0xFFC3AE91),
  Color(0xFF8C9DA4),
  Color(0xFFB48D7E),
  Color(0xFFD3CAAD),
];

class _CategoryDistribution extends StatelessWidget {
  const _CategoryDistribution({required this.items});
  final List<ClothingItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counts = {
      for (final category in Category.values)
        category: items.where((item) => item.category == category).length,
    }..removeWhere((category, count) => count == 0);
    return _Panel(
      title: context.tr('衣橱构成'),
      subtitle: context.tr('不同的单品，组成你的日常风格'),
      child: items.isEmpty
          ? _EmptyState(
              icon: Icons.checkroom_outlined,
              title: context.tr('你的衣橱，从一件开始'),
              description: context.tr('添加单品后，在这里认识你的衣橱构成。'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 340;
                final chart = SizedBox(
                  width: compact ? 144 : 160,
                  height: compact ? 144 : 160,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      counts: counts,
                      total: items.length,
                      track: theme.colorScheme.surfaceContainerLow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.number(items.length),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 34,
                          ),
                        ),
                        Text(
                          context.tr('件单品'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                final legend = Column(
                  children: [
                    for (final entry in counts.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color:
                                    _categoryColors[entry.key.index %
                                        _categoryColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                context.categoryLabel(entry.key),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              context.number(entry.value),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${context.number((entry.value / items.length * 100).round())}%',
                                textAlign: TextAlign.end,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
                return compact
                    ? Column(
                        children: [chart, const SizedBox(height: 20), legend],
                      )
                    : Row(
                        children: [
                          chart,
                          const SizedBox(width: 24),
                          Expanded(child: legend),
                        ],
                      );
              },
            ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.counts,
    required this.total,
    required this.track,
  });
  final Map<Category, int> counts;
  final int total;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 17.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
    var start = -math.pi / 2;
    final gap = counts.length > 1 ? .045 : 0.0;
    for (final entry in counts.entries) {
      final sweep = entry.value / total * math.pi * 2;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(0, sweep - gap),
        false,
        paint
          ..color = _categoryColors[entry.key.index % _categoryColors.length],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.track != track ||
      Category.values.any(
        (category) => oldDelegate.counts[category] != counts[category],
      );
}

class _RankingPanel extends StatelessWidget {
  const _RankingPanel({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.store,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyDescription,
    this.costRanking = false,
  });
  final String title;
  final String subtitle;
  final List<ClothingItem> items;
  final WardrobeStore store;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyDescription;
  final bool costRanking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Panel(
      title: title,
      subtitle: subtitle,
      child: items.isEmpty
          ? _EmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              description: emptyDescription,
            )
          : Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  if (index > 0)
                    Divider(
                      height: 20,
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: .5,
                      ),
                    ),
                  _RankingRow(
                    item: items[index],
                    index: index,
                    store: store,
                    costRanking: costRanking,
                  ),
                ],
                if (costRanking) ...[
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: .06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.eco_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr('单次成本 = 购买价格 ÷ 穿着次数'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                            ),
                          ),
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

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.item,
    required this.index,
    required this.store,
    required this.costRanking,
  });
  final ClothingItem item;
  final int index;
  final WardrobeStore store;
  final bool costRanking;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '${index + 1}'.padLeft(2, '0'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ),
            SizedBox(width: 50, height: 56, child: ItemThumb(item, radius: 12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.itemName(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.brand.isEmpty
                        ? context.categoryLabel(item.category)
                        : '${item.brand} · ${context.categoryLabel(item.category)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 105),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      costRanking
                          ? context.money(store.costPerWear(item)!)
                          : context.number(store.wearCount(item.id)),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    costRanking ? context.tr('每次穿着') : context.tr('次穿着'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 26),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 25),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.7,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
