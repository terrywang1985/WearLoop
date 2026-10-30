import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

import 'package:provider/provider.dart';

import '../models.dart';
import '../store.dart';
import '../widgets/brand_mark.dart';
import '../widgets/item_thumb.dart';
import 'history_screen.dart';
import 'item_detail_screen.dart';
import 'item_edit_screen.dart';
import 'log_wear_screen.dart';
import 'outfit_detail_screen.dart';
import 'settings_screen.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, this.onNavigate});
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final scheme = Theme.of(context).colorScheme;
    final now = store.now;
    final forgotten = store.forgottenItems;
    final revival = store.revivalOutfits;
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = constraints.maxWidth >= 760 ? 36.0 : 22.0;
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1192),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(padding, 26, padding, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: !desktop
                                  ? const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: BrandMark(compact: true),
                                    )
                                  : Text(
                                      context.tr('YOUR EVERYDAY WARDROBE'),
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 11,
                                        letterSpacing: 2.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            _HeaderAction(
                              icon: Icons.calendar_month_outlined,
                              tooltip: context.tr('穿着历史'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HistoryScreen(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _HeaderAction(
                              icon: Icons.tune,
                              tooltip: context.tr('设置'),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth >= 760
                                  ? 460
                                  : double.infinity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('今天穿什么？'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('从自己的衣橱，发现一点新鲜感。'),
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                border: Border.all(
                                  color: scheme.outlineVariant,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.wb_sunny_outlined,
                                    color: scheme.primary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${context.date(now)} · ${DateFormat.EEEE(context.l10n.locale.toLanguageTag()).format(now)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        LayoutBuilder(
                          builder: (_, bounds) {
                            if (bounds.maxWidth >= 760) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 7,
                                    child: _TodayCard(store: store),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 4,
                                    child: _WeekCard(store: store),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _TodayCard(store: store),
                                const SizedBox(height: 18),
                                _WeekCard(store: store),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 34),
                        _SectionHeader(
                          title: context.tr('被遗忘的衣服'),
                          eyebrow: context.tr('A SECOND CHANCE'),
                          subtitle: forgotten.isEmpty
                              ? context.tr('每一件都在被好好穿着，继续保持。')
                              : context.tr(
                                  '{count} 件已闲置超过 {days} 天，给它们一个再次出场的机会。',
                                  {
                                    'count': forgotten.length,
                                    'days': context.number(store.forgottenDays),
                                  },
                                ),
                          action: context.tr('看看衣橱'),
                          onTap: onNavigate == null
                              ? null
                              : () => onNavigate!(1),
                        ),
                        const SizedBox(height: 18),
                        if (forgotten.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(24),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.spa_outlined,
                                  color: scheme.primary,
                                  size: 30,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    store.items.isEmpty
                                        ? context.tr('从添加第一件衣服开始，慢慢建立自己的衣橱。')
                                        : context.tr('没有被遗忘的单品，好衣服都在循环出场。'),
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            height: 238,
                            child: LayoutBuilder(
                              builder: (_, bounds) {
                                final width = bounds.maxWidth >= 760
                                    ? (bounds.maxWidth - 64) / 5
                                    : 148.0;
                                return ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: forgotten.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(width: 16),
                                  itemBuilder: (_, i) => SizedBox(
                                    width: width,
                                    child: _ForgottenTile(
                                      item: forgotten[i],
                                      store: store,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        if (revival.isNotEmpty || store.outfits.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _SectionHeader(
                            title: revival.isEmpty
                                ? context.tr('衣橱里的灵感')
                                : context.tr('让它们重新出场'),
                            eyebrow: context.tr('LESS NEW. MORE YOU.'),
                            subtitle: revival.isEmpty
                                ? context.tr('喜欢的组合，值得反复穿。')
                                : context.tr('用已有的衣服，搭出久违的新鲜感。'),
                            action: context.tr('全部搭配'),
                            onTap: onNavigate == null
                                ? null
                                : () => onNavigate!(2),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 286,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  (revival.isNotEmpty ? revival : store.outfits)
                                      .length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (_, i) => _RevivalCard(
                                outfit: (revival.isNotEmpty
                                    ? revival
                                    : store.outfits)[i],
                                store: store,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 30),
                        Center(
                          child: Text(
                            context.tr('WEAR MORE. WASTE LESS.'),
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2.5,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.65,
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
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 20),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.eyebrow,
    this.subtitle,
    this.action,
    this.onTap,
  });
  final String title;
  final String eyebrow;
  final String? subtitle;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            if (action != null && onTap != null)
              Flexible(
                child: TextButton(
                  onPressed: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          action!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 15),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.7,
            ),
          ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.store});
  final WardrobeStore store;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final log = store.todayLog;
    final suggested =
        store.revivalOutfits.firstOrNull ?? store.outfits.firstOrNull;
    final items = log != null
        ? log.itemIds.map(store.itemById).whereType<ClothingItem>().toList()
        : suggested == null
        ? store.items.take(4).toList()
        : store.itemsOf(suggested);
    final actualOutfit = store.outfitById(log?.outfitId);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF2A3C2D) : const Color(0xFFE8EDDF),
        borderRadius: BorderRadius.circular(26),
      ),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final narrow = bounds.maxWidth < 480;
          final text = Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              26,
              28,
              narrow ? 26 : 0,
              narrow ? 0 : 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      log == null
                          ? Icons.auto_awesome_outlined
                          : Icons.check_circle_outline,
                      size: 15,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        log == null
                            ? context.tr('每日穿搭 · 小小仪式感')
                            : context.tr('今日穿搭 · 已记录'),
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  log == null
                      ? context.tr('好好穿衣，\n也是好好生活。')
                      : (actualOutfit == null
                            ? context.tr('今天的你，\n有自己的风格。')
                            : context.outfitName(actualOutfit)),
                  style: TextStyle(
                    fontSize: narrow ? 27 : 29,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  log == null
                      ? context.tr('记录今天的选择，\n让每一件喜欢都有迹可循。')
                      : context.tr('今天穿了 {count} 件单品，\n喜欢的衣服，又陪你度过一天。', {
                          'count': items.length,
                        }),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.8,
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => store.items.isEmpty
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ItemEditScreen(),
                          ),
                        )
                      : openLogWear(context, existing: log),
                  icon: Icon(
                    log == null ? Icons.add : Icons.edit_outlined,
                    size: 17,
                  ),
                  label: Text(
                    store.items.isEmpty
                        ? context.tr('添加第一件衣服')
                        : log == null
                        ? context.tr('记录今日穿搭')
                        : context.tr('修改今日穿搭'),
                  ),
                ),
              ],
            ),
          );
          final art = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: double.infinity,
                height: narrow ? 215 : 238,
                child: _OutfitStage(items: items),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                child: Text(
                  log == null
                      ? (suggested == null
                            ? context.tr('YOUR WARDROBE, YOUR WAY')
                            : context.tr('灵感预览 / {name}', {
                                'name': context.outfitName(suggested),
                              }))
                      : (actualOutfit == null
                            ? context.tr('TODAY’S PERSONAL EDIT')
                            : context.tr('今日选择 / {name}', {
                                'name': context.outfitName(actualOutfit),
                              })),
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [text, art],
            );
          }
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 330),
            child: Row(
              children: [
                Expanded(flex: 10, child: text),
                Expanded(flex: 9, child: art),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OutfitStage extends StatelessWidget {
  const _OutfitStage({required this.items});
  final List<ClothingItem> items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          size: 100,
        ),
      );
    }
    final top =
        items
            .where(
              (i) =>
                  i.category == Category.top ||
                  i.category == Category.outerwear ||
                  i.category == Category.dress,
            )
            .firstOrNull ??
        items.first;
    final bottom = items
        .where(
          (i) =>
              i.category == Category.bottom ||
              i.category == Category.pants ||
              i.category == Category.shorts ||
              i.category == Category.skirt,
        )
        .firstOrNull;
    final extra = items
        .where((i) => i.id != top.id && i.id != bottom?.id)
        .firstOrNull;
    return LayoutBuilder(
      builder: (_, bounds) => Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: bounds.maxWidth * 0.09,
            top: 12,
            width: bounds.maxWidth * 0.72,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface
                    .withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (bottom != null)
            Positioned(
              right: bounds.maxWidth * 0.03,
              top: 55,
              width: bounds.maxWidth * 0.56,
              height: 166,
              child: Transform.rotate(angle: 0.1, child: _stageItem(bottom)),
            ),
          Positioned(
            left: 0,
            top: 3,
            width: bounds.maxWidth * 0.72,
            height: 184,
            child: Transform.rotate(angle: -0.09, child: _stageItem(top)),
          ),
          if (extra != null)
            Positioned(
              left: bounds.maxWidth * 0.08,
              bottom: 0,
              width: bounds.maxWidth * 0.43,
              height: 99,
              child: Transform.rotate(angle: -0.08, child: _stageItem(extra)),
            ),
        ],
      ),
    );
  }

  Widget _stageItem(ClothingItem item) =>
      !hasPersonalImage(item) ? GarmentArt(item: item) : ItemThumb(item);
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.store});
  final WardrobeStore store;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = dateOnly(store.now);
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));
    final count = days.where((day) => store.logOn(day) != null).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('本周穿搭手记'),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.edit_note_outlined, size: 22, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant, fontSize: 12),
                children: [
                  TextSpan(
                    text: context.number(count),
                    style: TextStyle(
                      color: scheme.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: context.tr(' / 7 天，留下了穿搭记录')),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              day == today
                                  ? context.tr('今')
                                  : DateFormat.E(
                                      context.l10n.locale.toLanguageTag(),
                                    ).format(day),
                              style: TextStyle(
                                fontSize: 10,
                                color: day == today
                                    ? scheme.primary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            key: ValueKey('wear-day-${fmtDate(day)}'),
                            label:
                                '${context.date(day)} · ${context.tr(store.logOn(day) == null ? '未记录' : '已记录')}',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => openLogWear(
                                context,
                                day: day,
                                existing: store.logOn(day),
                              ),
                              child: Container(
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: store.logOn(day) == null
                                      ? scheme.primary.withValues(alpha: 0.04)
                                      : scheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  border: day == today
                                      ? Border.all(
                                          color: scheme.primary.withValues(
                                            alpha: 0.45,
                                          ),
                                        )
                                      : null,
                                ),
                                child: store.logOn(day) == null
                                    ? Text(
                                        context.number(day.day),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      )
                                    : Icon(
                                        Icons.check,
                                        color: scheme.onPrimary,
                                        size: 15,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 17),
            Row(
              children: [
                Icon(Icons.spa_outlined, color: scheme.primary, size: 22),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    store.streak > 0
                        ? context.tr('已经连续记录 {count} 天\n小小坚持，让喜欢继续。', {
                            'count': store.streak,
                          })
                        : context.tr('每一次记录，\n都让你更了解自己的衣橱。'),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      context.tr('翻翻穿搭日历'),
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForgottenTile extends StatelessWidget {
  const _ForgottenTile({required this.item, required this.store});
  final ClothingItem item;
  final WardrobeStore store;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ItemThumb(item, radius: 18),
                  PositionedDirectional(
                    start: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.tr('闲置 {days} 天', {
                          'days': context.number(store.idleDays(item)),
                        }),
                        style: const TextStyle(
                          color: Color(0xFF8A7656),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Text(
              context.itemName(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    '${context.categoryLabel(item.category)} · ${store.wearCount(item.id) == 0 ? context.tr('等待第一次出场') : context.tr('穿过 {count} 次', {'count': store.wearCount(item.id)})}',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }
}

class _RevivalCard extends StatelessWidget {
  const _RevivalCard({required this.outfit, required this.store});
  final Outfit outfit;
  final WardrobeStore store;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = store.todayLog;
    final chosen = today?.outfitId == outfit.id;
    return SizedBox(
      width: 258,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OutfitDetailScreen(outfitId: outfit.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: OutfitCollage(store.itemsOf(outfit), gap: 5)),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.outfitName(outfit),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (outfit.favorite)
                      Icon(Icons.favorite, size: 15, color: scheme.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    outfit.tags.map(context.tagLabel).join(' / '),
                    context.tr('{count} 件单品', {'count': outfit.itemIds.length}),
                  ].where((part) => part.isNotEmpty).join(' · '),
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(44, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      backgroundColor: chosen
                          ? scheme.primary.withValues(alpha: 0.08)
                          : null,
                      textStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(fontSize: 11),
                    ),
                    icon: Icon(chosen ? Icons.check : Icons.add, size: 14),
                    label: Text(
                      chosen ? context.tr('今天已穿这套') : context.tr('今天就穿它'),
                    ),
                    onPressed: chosen || store.itemsOf(outfit).isEmpty
                        ? null
                        : () {
                            store.logWear(
                              store.now,
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
                                action: SnackBarAction(
                                  label: context.tr('撤销'),
                                  onPressed: () {
                                    if (today == null) {
                                      final current = store.todayLog;
                                      if (current != null) {
                                        store.deleteLog(current.id);
                                      }
                                    } else {
                                      store.logWear(
                                        today.date,
                                        today.itemIds,
                                        outfitId: today.outfitId,
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
