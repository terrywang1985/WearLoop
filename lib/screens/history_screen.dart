import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../l10n/app_localizations.dart';
import '../store.dart';
import '../widgets/item_thumb.dart';
import 'log_wear_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _addRecord(BuildContext context, WardrobeStore store) async {
    final day = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (day != null && context.mounted) {
      openLogWear(context, existing: store.logOn(day), day: day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('穿着日记'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addRecord(context, store),
        icon: const Icon(Icons.edit_calendar_outlined),
        label: Text(context.tr('补记穿搭')),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 112),
            children: [
              Text(
                context.tr('把每一天，穿成自己的样子。'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('已记录 {count} 天 · 每一次重穿，都让衣橱更有价值。', {
                  'count': store.logs.length,
                }),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              if (store.logs.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_stories_outlined,
                        size: 44,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        context.tr('第一篇穿着日记，从今天开始'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('记录穿过的单品，慢慢发现自己的穿衣习惯。'),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () => openLogWear(context),
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('记录今日穿搭')),
                      ),
                    ],
                  ),
                ),
              for (var i = 0; i < store.logs.length; i++) ...[
                if (i == 0 ||
                    store.logs[i].date.month != store.logs[i - 1].date.month ||
                    store.logs[i].date.year != store.logs[i - 1].date.year)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 14),
                    child: Text(
                      MaterialLocalizations.of(context)
                          .formatMonthYear(store.logs[i].date),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                _HistoryCard(log: store.logs[i], store: store),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.log, required this.store});
  final WearLog log;
  final WardrobeStore store;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final outfit = store.outfitById(log.outfitId);
    final items = log.itemIds
        .map(store.itemById)
        .whereType<ClothingItem>()
        .toList();
    final weekdays = [
      context.tr('周一'),
      context.tr('周二'),
      context.tr('周三'),
      context.tr('周四'),
      context.tr('周五'),
      context.tr('周六'),
      context.tr('周日'),
    ];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openLogWear(context, existing: log),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      MaterialLocalizations.of(context)
                          .formatDecimal(log.date.day),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      weekdays[log.date.weekday - 1],
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            outfit == null
                                ? context.tr('自由搭配')
                                : context.outfitName(outfit),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('{date} · {count} 件单品', {
                        'date': context.date(log.date),
                        'count': items.length,
                      }),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final slots = (constraints.maxWidth / 54).floor().clamp(
                          1,
                          6,
                        );
                        final showCount = items.length <= slots
                            ? items.length
                            : slots - 1;
                        return Row(
                          children: [
                            for (final item in items.take(showCount))
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 6,
                                ),
                                child: SizedBox(
                                  width: 48,
                                  height: 52,
                                  child: ItemThumb(item, radius: 10),
                                ),
                              ),
                            if (items.length > showCount)
                              Container(
                                width: 44,
                                height: 52,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '+${items.length - showCount}',
                                  style: theme.textTheme.labelLarge,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
