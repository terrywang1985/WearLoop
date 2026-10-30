import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../store.dart';
import '../widgets/item_thumb.dart';
import 'item_detail_screen.dart';
import 'outfit_edit_screen.dart';
import 'share_screen.dart';

class OutfitDetailScreen extends StatelessWidget {
  const OutfitDetailScreen({super.key, required this.outfitId});
  final String outfitId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final outfit = store.outfitById(outfitId);
    if (outfit == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('搭配详情'))),
        body: Center(child: Text(context.tr('这套搭配已不存在'))),
      );
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = store.itemsOf(outfit);
    final worn = store.outfitWearCount(outfit.id);
    final last = store.logs
        .where((log) => log.outfitId == outfit.id)
        .firstOrNull;
    final isToday = store.todayLog?.outfitId == outfit.id;

    final overview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('我的穿搭集'),
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.primary,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.outfitName(outfit),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in outfit.tags)
              Chip(label: Text(context.tagLabel(tag))),
            if (outfit.tags.isEmpty) Chip(label: Text(context.tr('我的日常'))),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.repeat_rounded, color: scheme.primary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worn == 0
                            ? context.tr('新搭配，等你第一次出场')
                            : context.tr('已经一起出场 {count} 次', {'count': worn}),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        last == null
                            ? context.tr('喜欢的搭配，可以一穿再穿。')
                            : context.tr('上次穿着 {date}', {
                                'date': context.date(last.date),
                              }),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (outfit.note.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            outfit.note,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.7,
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: Icon(isToday ? Icons.check_circle_outline : Icons.check),
            label: Text(isToday ? context.tr('今日已穿这套') : context.tr('今天穿这套')),
            onPressed: items.isEmpty
                ? null
                : () {
                    store.logWear(
                      DateTime.now(),
                      List.of(outfit.itemIds),
                      outfitId: outfit.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr('已记录：今天穿「{name}」', {
                            'name': context.outfitName(outfit),
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
            icon: const Icon(Icons.ios_share_outlined),
            label: Text(context.tr('生成穿搭分享卡')),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShareScreen(outfitId: outfit.id),
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('搭配详情')),
        actions: [
          IconButton(
            tooltip: outfit.favorite ? context.tr('取消收藏') : context.tr('收藏搭配'),
            icon: Icon(
              outfit.favorite ? Icons.favorite : Icons.favorite_border,
              color: outfit.favorite ? scheme.primary : null,
            ),
            onPressed: () => store.toggleFavorite(outfit),
          ),
          IconButton(
            tooltip: context.tr('编辑搭配'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => OutfitEditScreen(outfit: outfit),
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('删除搭配'),
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.tr('删除这套搭配？')),
                  content: Text(context.tr('单品和已有的穿着记录会保留，搭配收藏会移除。')),
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
                store.deleteOutfit(outfit.id);
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
                  final visual = Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AspectRatio(
                        aspectRatio: 0.95,
                        child: OutfitCollage(items, gap: 10),
                      ),
                    ),
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
                    context.tr('组成这套搭配的单品'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  Text(
                    context.tr('{count} 件', {'count': items.length}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (items.isEmpty)
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(context.tr('这套搭配的单品已被移除，编辑搭配添加新的单品吧。')),
                  ),
                ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: SizedBox(
                        width: 58,
                        height: 58,
                        child: ItemThumb(item, radius: 12),
                      ),
                      title: Text(
                        context.itemName(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        context.tr('{category} · 穿过 {count} 次', {
                          'category': context.categoryLabel(item.category),
                          'count': store.wearCount(item.id),
                        }),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemDetailScreen(itemId: item.id),
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
