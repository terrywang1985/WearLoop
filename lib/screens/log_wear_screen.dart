import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../l10n/app_localizations.dart';
import '../store.dart';
import '../widgets/item_thumb.dart';
import 'item_picker.dart';

Future<void> openLogWear(
  BuildContext context, {
  WearLog? existing,
  DateTime? day,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LogWearScreen(existing: existing, day: day),
    ),
  );
}

/// 记录穿搭：可以直接选一套搭配，也可以自由挑选单品。
class LogWearScreen extends StatefulWidget {
  const LogWearScreen({super.key, this.existing, this.day});
  final WearLog? existing;
  final DateTime? day;

  @override
  State<LogWearScreen> createState() => _LogWearScreenState();
}

class _LogWearScreenState extends State<LogWearScreen> {
  late DateTime _day;
  late Set<String> _selected;
  String? _outfitId;

  @override
  void initState() {
    super.initState();
    _day = widget.existing?.date ?? dateOnly(widget.day ?? DateTime.now());
    _selected = {...?widget.existing?.itemIds};
    _outfitId = widget.existing?.outfitId;
  }

  Future<void> _save(WardrobeStore store) async {
    final target = store.logOn(_day);
    if (target != null && target.id != widget.existing?.id) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr('更新这一天的穿搭？')),
          content: Text(
            context.tr('{date} 已有穿搭记录，保存后将替换当天的记录。', {
              'date': context.date(_day),
            }),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('取消')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('替换记录')),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    final original = widget.existing;
    if (original != null && original.date != _day) {
      store.deleteLog(original.id);
    }
    store.logWear(_day, _selected.toList(), outfitId: _outfitId);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete(WardrobeStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('删除这篇穿着日记？')),
        content: Text(context.tr('删除后，这一天的单品穿着次数也会相应更新。')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('删除记录')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      store.deleteLog(widget.existing!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final outfits = [...store.outfits]
      ..sort((a, b) => (b.favorite ? 1 : 0) - (a.favorite ? 1 : 0));
    final isToday = _day == dateOnly(DateTime.now());

    return DefaultTabController(
      length: 2,
      initialIndex: widget.existing != null && _outfitId == null ? 1 : 0,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.existing == null ? context.tr('记录穿搭') : context.tr('编辑穿搭'),
          ),
          actions: [
            if (widget.existing != null)
              IconButton(
                tooltip: context.tr('删除记录'),
                onPressed: () => _delete(store),
                icon: const Icon(Icons.delete_outline),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(24, 8, 24, 20),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('今天，也好好穿衣。'),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            context.tr('选一套收藏，或自由组合喜欢的单品'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                        ),
                        label: Text(
                          isToday ? context.tr('今天') : context.date(_day),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _day,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null && mounted) {
                            setState(() => _day = dateOnly(picked));
                          }
                        },
                      ),
                    ],
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(text: context.tr('从搭配中选择')),
                    Tab(text: context.tr('自由选单品')),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      outfits.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.style_outlined,
                                      size: 44,
                                      color: scheme.primary,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      context.tr('还没有保存的搭配'),
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      context.tr('切换到「自由选单品」，也能记录今天的穿搭。'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(24),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 260,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.79,
                                  ),
                              itemCount: outfits.length,
                              itemBuilder: (_, i) {
                                final outfit = outfits[i];
                                final selected = _outfitId == outfit.id;
                                return _SelectableCard(
                                  selected: selected,
                                  onTap: () => setState(() {
                                    _outfitId = selected ? null : outfit.id;
                                    _selected = selected
                                        ? {}
                                        : {...outfit.itemIds};
                                  }),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: OutfitCollage(
                                          store.itemsOf(outfit),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        context.outfitName(outfit),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        context.tr('{count} 件单品', {
                                              'count': outfit.itemIds.length,
                                            }) +
                                            (outfit.tags.isEmpty
                                                ? ''
                                                : ' · ${context.tagLabel(outfit.tags.first)}'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ItemPicker(
                        selected: _selected,
                        onChanged: (selection) => setState(() {
                          _selected = selection;
                          final outfit = store.outfitById(_outfitId);
                          if (outfit == null ||
                              outfit.itemIds
                                  .toSet()
                                  .difference(selection)
                                  .isNotEmpty ||
                              selection.length != outfit.itemIds.length) {
                            _outfitId = null;
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(24, 14, 24, 18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final summary = Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          context.tr('已选 {count} 件', {
                            'count': _selected.length,
                          }),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          context.date(_day),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                    final save = FilledButton.icon(
                      onPressed: _selected.isEmpty ? null : () => _save(store),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        context.tr('保存穿搭'),
                        textAlign: TextAlign.center,
                      ),
                    );
                    if (constraints.maxWidth < 520) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [summary, const SizedBox(height: 10), save],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: summary),
                        const SizedBox(width: 20),
                        Flexible(child: save),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(padding: const EdgeInsets.all(12), child: child),
              if (selected)
                PositionedDirectional(
                  end: 18,
                  top: 18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: scheme.primary,
                      size: 28,
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
