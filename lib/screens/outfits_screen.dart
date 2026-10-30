import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../widgets/item_thumb.dart';
import 'item_edit_screen.dart';
import 'outfit_detail_screen.dart';
import 'outfit_edit_screen.dart';

enum _OutfitSort {
  recent('最近创建'),
  mostWorn('经常穿着');

  const _OutfitSort(this.label);
  final String label;
}

class OutfitsScreen extends StatefulWidget {
  const OutfitsScreen({super.key});

  @override
  State<OutfitsScreen> createState() => _OutfitsScreenState();
}

class _OutfitsScreenState extends State<OutfitsScreen> {
  static const _favorites = '_favorites';
  final _search = TextEditingController();
  String? _tag;
  String _query = '';
  _OutfitSort _sort = _OutfitSort.recent;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _search.clear();
    setState(() {
      _query = '';
      _tag = null;
    });
  }

  Future<void> _add() async {
    final store = context.read<WardrobeStore>();
    if (store.items.isEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const ItemEditScreen(),
        ),
      );
      if (!mounted || store.items.isEmpty) return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const OutfitEditScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final query = _query.trim().toLowerCase();
    final list = store.outfits.where((outfit) {
      if (_tag == _favorites && !outfit.favorite) return false;
      if (_tag != null && _tag != _favorites && !outfit.tags.contains(_tag)) {
        return false;
      }
      return query.isEmpty ||
          '${outfit.name} ${context.outfitName(outfit)} ${outfit.tags.map(context.tagLabel).join(' ')} ${outfit.note} ${store.itemsOf(outfit).map(context.itemName).join(' ')}'
              .toLowerCase()
              .contains(query);
    }).toList();
    switch (_sort) {
      case _OutfitSort.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case _OutfitSort.mostWorn:
        list.sort(
          (a, b) => store.outfitWearCount(b.id) - store.outfitWearCount(a.id),
        );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 700 ? 36.0 : 20.0;
            final width =
                math.min(1192.0, constraints.maxWidth) - horizontal * 2;
            final columns = width < 300
                ? 1
                : (width / 270).floor().clamp(2, 3).toInt();
            final gap = width >= 600 ? 20.0 : 12.0;
            final cardWidth = (width - gap * (columns - 1)) / columns;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1192),
                child: CustomScrollView(
                  key: const PageStorageKey('outfits_scroll'),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontal,
                        32,
                        horizontal,
                        0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: width < 500 ? width : width * 0.55,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.tr('OUTFIT COLLECTION'),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              letterSpacing: 2.5,
                                              color: colors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        context.tr('我的搭配'),
                                        style: theme.textTheme.headlineLarge
                                            ?.copyWith(
                                              fontSize: width < 400 ? 29 : 34,
                                              letterSpacing: -1,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.icon(
                                  onPressed: _add,
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text(context.tr('新建搭配')),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 44),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('{count} 套搭配，把喜欢的组合留给每一天。', {
                                'count': store.outfits.length,
                              }),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 28),
                            TextField(
                              controller: _search,
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText: context.tr('搜索搭配、场景或单品'),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 22,
                                ),
                                suffixIcon: _query.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: context.tr('清空搜索'),
                                        onPressed: () {
                                          _search.clear();
                                          setState(() => _query = '');
                                        },
                                        icon: const Icon(Icons.close, size: 18),
                                      ),
                                filled: true,
                                fillColor: colors.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 17,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _chip(
                                    context.tr('全部'),
                                    store.outfits.length,
                                    null,
                                  ),
                                  _chip(
                                    context.tr('收藏'),
                                    store.outfits
                                        .where((o) => o.favorite)
                                        .length,
                                    _favorites,
                                    icon: Icons.favorite_outline_rounded,
                                  ),
                                  for (final tag in kOutfitTags)
                                    if (store.outfits.any(
                                      (o) => o.tags.contains(tag),
                                    ))
                                      _chip(
                                        tag,
                                        store.outfits
                                            .where((o) => o.tags.contains(tag))
                                            .length,
                                        tag,
                                      ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            Row(
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: query.isNotEmpty
                                              ? context.tr('搜索结果')
                                              : _tag == _favorites
                                              ? context.tr('我的收藏')
                                              : (_tag == null
                                                    ? context.tr('全部搭配')
                                                    : context.tagLabel(_tag!)),
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        TextSpan(
                                          text:
                                              '  ${context.tr('{count} 套', {'count': list.length})}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: PopupMenuButton<_OutfitSort>(
                                    tooltip: context.tr('搭配排序'),
                                    initialValue: _sort,
                                    onSelected: (s) =>
                                        setState(() => _sort = s),
                                    itemBuilder: (_) => [
                                      for (final s in _OutfitSort.values)
                                        CheckedPopupMenuItem(
                                          value: s,
                                          checked: s == _sort,
                                          child: Text(context.tr(s.label)),
                                        ),
                                    ],
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.sort_rounded,
                                            size: 17,
                                            color: colors.onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              context.tr(_sort.label),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        colors.onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          const Icon(
                                            Icons.expand_more,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                    if (list.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            36,
                            horizontal,
                            64,
                          ),
                          child: _OutfitEmpty(
                            hasOutfits: store.outfits.isNotEmpty,
                            hasItems: store.items.isNotEmpty,
                            searching: query.isNotEmpty,
                            favorites: _tag == _favorites,
                            onAdd: _add,
                            onReset: _resetFilters,
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          0,
                          horizontal,
                          36,
                        ),
                        sliver: SliverGrid.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisSpacing: gap,
                                crossAxisSpacing: gap,
                                mainAxisExtent: (cardWidth - 20) / 1.1 + 113,
                              ),
                          itemCount: list.length,
                          itemBuilder: (_, index) {
                            final outfit = list[index];
                            return _OutfitCard(
                              outfit: outfit,
                              items: store.itemsOf(outfit),
                              worn: store.outfitWearCount(outfit.id),
                              onFavorite: () => store.toggleFavorite(outfit),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      OutfitDetailScreen(outfitId: outfit.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _chip(String label, int count, String? value, {IconData? icon}) {
    final colors = Theme.of(context).colorScheme;
    final selected = _tag == value;
    final color = selected ? colors.onPrimary : colors.onSurface;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _tag = value),
        selectedColor: colors.primary,
        backgroundColor: colors.surface,
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              context.tr(label),
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              context.number(count),
              style: TextStyle(
                fontSize: 11,
                color: selected
                    ? colors.onPrimary.withValues(alpha: 0.7)
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({
    required this.outfit,
    required this.items,
    required this.worn,
    required this.onFavorite,
    required this.onTap,
  });

  final Outfit outfit;
  final List<ClothingItem> items;
  final int worn;
  final VoidCallback onFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: OutfitCollage(items, gap: 6),
                    ),
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: Material(
                        color: colors.surface.withValues(alpha: 0.95),
                        shape: const CircleBorder(),
                        child: IconButton(
                          tooltip: outfit.favorite
                              ? context.tr('取消收藏')
                              : context.tr('收藏搭配'),
                          onPressed: onFavorite,
                          iconSize: 18,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          color: colors.primary,
                          icon: Icon(
                            outfit.favorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                          ),
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      bottom: 8,
                      start: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.tr('{count} 件单品', {'count': items.length}),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.outfitName(outfit),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    outfit.tags.isEmpty
                        ? context.tr('日常灵感')
                        : outfit.tags.map(context.tagLabel).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    worn == 0
                        ? context.tr('还未穿过，试试今天穿这套')
                        : context.tr('已经陪伴你 {count} 次', {'count': worn}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
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

class _OutfitEmpty extends StatelessWidget {
  const _OutfitEmpty({
    required this.hasOutfits,
    required this.hasItems,
    required this.searching,
    required this.favorites,
    required this.onAdd,
    required this.onReset,
  });

  final bool hasOutfits;
  final bool hasItems;
  final bool searching;
  final bool favorites;
  final VoidCallback onAdd;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final filtered = searching || hasOutfits;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              searching
                  ? Icons.search_rounded
                  : favorites
                  ? Icons.favorite_outline_rounded
                  : Icons.layers_outlined,
              size: 34,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            searching
                ? context.tr('还没找到合适的搭配')
                : favorites && hasOutfits
                ? context.tr('把喜欢的搭配留在这里')
                : hasOutfits
                ? context.tr('这个场景还没有搭配')
                : context.tr('好搭配，值得再穿一次'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            searching
                ? context.tr('试试其他名称、场景或单品关键词。')
                : favorites && hasOutfits
                ? context.tr('轻点搭配上的爱心，随时找回穿衣灵感。')
                : hasOutfits
                ? context.tr('试试其他场景，或者为它创建一套新组合。')
                : hasItems
                ? context.tr('把衣橱里的单品组合起来，存下你的日常灵感。')
                : context.tr('先收进第一件衣服，再为它找到喜欢的组合。'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: filtered ? onReset : onAdd,
            icon: Icon(filtered ? Icons.refresh_rounded : Icons.add, size: 18),
            label: Text(
              filtered
                  ? context.tr('查看全部搭配')
                  : hasItems
                  ? context.tr('创建第一套搭配')
                  : context.tr('添加第一件衣服'),
            ),
          ),
          if (hasOutfits && !favorites && !searching)
            TextButton(onPressed: onAdd, child: Text(context.tr('为这个场景创建搭配'))),
        ],
      ),
    );
  }
}
