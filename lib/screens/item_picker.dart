import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../l10n/app_localizations.dart';
import '../store.dart';
import '../widgets/item_thumb.dart';
import 'item_edit_screen.dart';

/// 按分类分组的多选单品网格。
class ItemPicker extends StatelessWidget {
  const ItemPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (store.items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.checkroom_outlined,
                  size: 30,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.tr('先收进一件喜欢的衣服'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('添加衣物后，就可以自由组合、记录穿搭。'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const ItemEditScreen(),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.tr('添加第一件衣服')),
              ),
            ],
          ),
        ),
      );
    }

    final groups = {
      for (final category in Category.values)
        category: store.items
            .where((item) => item.category == category)
            .toList(),
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 600 ? 24.0 : 20.0;
        final width = math.min(1120.0, constraints.maxWidth) - horizontal * 2;
        final columns = width < 260
            ? 1
            : (width / 170).floor().clamp(2, 5).toInt();
        final gap = width >= 600 ? 16.0 : 12.0;
        final cardWidth = (width - gap * (columns - 1)) / columns;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: CustomScrollView(
              slivers: [
                for (final category in Category.values)
                  if (groups[category]!.isNotEmpty) ...[
                    SliverPadding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        horizontal,
                        18,
                        horizontal,
                        12,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 19,
                                    color: colors.primary,
                                  ),
                                  Text(
                                    context.categoryLabel(category),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    context.tr('{count} 件', {
                                      'count': groups[category]!.length,
                                    }),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (groups[category]!.any(
                              (i) => selected.contains(i.id),
                            ))
                              Text(
                                context.tr('已选 {count}', {
                                  'count': groups[category]!
                                      .where((i) => selected.contains(i.id))
                                      .length,
                                }),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: horizontal),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: gap,
                          crossAxisSpacing: gap,
                          mainAxisExtent: cardWidth * 1.04 + 64,
                        ),
                        itemCount: groups[category]!.length,
                        itemBuilder: (_, index) {
                          final item = groups[category]![index];
                          final isSelected = selected.contains(item.id);
                          void toggle() {
                            final next = {...selected};
                            isSelected
                                ? next.remove(item.id)
                                : next.add(item.id);
                            onChanged(next);
                          }

                          return Semantics(
                            container: true,
                            checked: isSelected,
                            button: true,
                            label: context.tr('{name}，{category}', {
                              'name': context.itemName(item),
                              'category': context.categoryLabel(category),
                            }),
                            hint: isSelected
                                ? context.tr('取消选择这件单品')
                                : context.tr('选择这件单品'),
                            onTap: toggle,
                            child: ExcludeSemantics(
                              child: Material(
                                color: isSelected
                                    ? colors.primaryContainer.withValues(
                                        alpha: 0.25,
                                      )
                                    : colors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? colors.primary
                                        : colors.outlineVariant,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: toggle,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsetsDirectional.fromSTEB(
                                                8,
                                                8,
                                                8,
                                                0,
                                              ),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ItemThumb(item, radius: 13),
                                              PositionedDirectional(
                                                top: 7,
                                                end: 7,
                                                child: Container(
                                                  width: 25,
                                                  height: 25,
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? colors.primary
                                                        : colors.surface
                                                              .withValues(
                                                                alpha: 0.92,
                                                              ),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? colors.primary
                                                          : colors
                                                                .outlineVariant,
                                                    ),
                                                  ),
                                                  child: isSelected
                                                      ? Icon(
                                                          Icons.check_rounded,
                                                          size: 16,
                                                          color:
                                                              colors.onPrimary,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.fromSTEB(
                                              12,
                                              11,
                                              12,
                                              13,
                                            ),
                                        child: Tooltip(
                                          message: context.itemName(item),
                                          child: Text(
                                            context.itemName(item),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  height: 1.4,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        );
      },
    );
  }
}
