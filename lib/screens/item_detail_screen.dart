import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../demo_assets.dart';
import '../store.dart';
import '../widgets/item_thumb.dart';
import 'item_edit_screen.dart';
import 'outfit_detail_screen.dart';
import 'outfit_edit_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});
  final String itemId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final item = store.itemById(itemId);
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('单品详情'))),
        body: Center(child: Text(context.tr('这件衣服已不在衣橱中'))),
      );
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = store.wearCount(item.id);
    final last = store.lastWorn(item.id);
    final cost = store.costPerWear(item);
    final idle = store.idleDays(item);
    final outfits = store.outfits
        .where((outfit) => outfit.itemIds.contains(item.id))
        .toList();

    final overview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.categoryLabel(item.category),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.itemName(item),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (!hasPersonalImage(item) && demoAssetFor(item) != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              context.tr('示例图片 · AI 生成'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (item.brand.isNotEmpty) Chip(label: Text(item.brand)),
            for (final season in item.seasons)
              Chip(label: Text(context.seasonLabel(season))),
            if (item.seasons.isEmpty) Chip(label: Text(context.tr('日常衣橱'))),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 8),
            child: Row(
              children: [
                _Stat(
                  context.tr('穿着次数'),
                  context.tr('{count} 次', {'count': count}),
                  '',
                ),
                _Stat(
                  context.tr('上次穿着'),
                  last == null
                      ? '—'
                      : context.tr('{count} 天前', {'count': idle}),
                  '',
                ),
                _Stat(
                  context.tr('单次成本'),
                  cost == null ? '—' : context.money(cost),
                  '',
                ),
              ],
            ),
          ),
        ),
        if (idle >= store.forgottenDays) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.wb_sunny_outlined, color: scheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('已经 {count} 天没穿了，给它一次新的出场机会。', {'count': idle}),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: Icon(
              store.todayLog?.itemIds.contains(item.id) == true
                  ? Icons.check_circle_outline
                  : Icons.add,
            ),
            label: Text(
              store.todayLog?.itemIds.contains(item.id) == true
                  ? context.tr('已加入今日穿搭')
                  : context.tr('今天穿了它'),
            ),
            onPressed: () {
              final today = store.todayLog;
              final ids = {...?today?.itemIds, item.id}.toList();
              final outfit = store.outfitById(today?.outfitId);
              final matchesOutfit =
                  outfit != null &&
                  outfit.itemIds.length == ids.length &&
                  outfit.itemIds.toSet().containsAll(ids);
              store.logWear(
                DateTime.now(),
                ids,
                outfitId: matchesOutfit ? outfit.id : null,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.tr('已加入今日穿搭：{name}', {
                      'name': context.itemName(item),
                    }),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.style_outlined),
            label: Text(context.tr('用它搭一套')),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => OutfitEditScreen(preselected: [item.id]),
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('单品详情')),
        actions: [
          IconButton(
            tooltip: context.tr('编辑衣服'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => ItemEditScreen(item: item),
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('删除衣服'),
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.tr('删除这件衣服？')),
                  content: Text(context.tr('相关的穿着记录和搭配中的这件也会一起移除。')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.tr('取消')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.tr('删除')),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                Navigator.pop(context);
                store.deleteItem(item.id);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 24, 32),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final visual = AspectRatio(
                    aspectRatio: 0.95,
                    child: ItemThumb(item, radius: 24),
                  );
                  if (constraints.maxWidth >= 660) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: visual),
                        const SizedBox(width: 32),
                        Expanded(child: overview),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [visual, const SizedBox(height: 24), overview],
                  );
                },
              ),
              const SizedBox(height: 32),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    context.tr('关于这件单品'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  Text(
                    context.tr('好衣服，值得反复穿'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        context.tr('品牌'),
                        item.brand.isEmpty ? context.tr('未填写') : item.brand,
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        context.tr('购入价格'),
                        item.price == null
                            ? context.tr('未填写')
                            : context.money(item.price!),
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        context.tr('购买日期'),
                        item.purchaseDate == null
                            ? context.tr('未填写')
                            : context.date(item.purchaseDate!),
                      ),
                      if (item.notes.isNotEmpty) ...[
                        const Divider(height: 32),
                        Text(
                          context.tr('我的备注'),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(item.notes),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.tr('搭配灵感 · {count} 套', {'count': outfits.length}),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              if (outfits.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.style_outlined, color: scheme.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            context.tr('还没有相关搭配。用这件单品开启一个新组合。'),
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              for (final outfit in outfits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: SizedBox(
                        width: 58,
                        height: 58,
                        child: OutfitCollage(store.itemsOf(outfit), gap: 2),
                      ),
                      title: Text(
                        context.outfitName(outfit),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        outfit.tags.isEmpty
                            ? context.tr('{count} 件单品', {
                                'count': outfit.itemIds.length,
                              })
                            : outfit.tags.map(context.tagLabel).join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              OutfitDetailScreen(outfitId: outfit.id),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.unit);
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value${unit.isEmpty ? '' : ' $unit'}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 82,
        child: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      Expanded(child: Text(value)),
    ],
  );
}
