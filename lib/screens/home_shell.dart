import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

import '../widgets/brand_mark.dart';
import 'outfits_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'today_screen.dart';
import 'wardrobe_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _visited = <int>{0};
  static const _labels = ['今日', '衣橱', '搭配', '统计'];
  static const _icons = [
    Icons.wb_sunny_outlined,
    Icons.checkroom_outlined,
    Icons.style_outlined,
    Icons.insights_outlined,
  ];
  void _select(int index) => setState(() {
    _index = index;
    _visited.add(index);
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final pages = [
      TodayScreen(onNavigate: _select),
      const WardrobeScreen(),
      const OutfitsScreen(),
      const StatsScreen(),
    ];
    final content = IndexedStack(
      index: _index,
      children: [
        for (var i = 0; i < pages.length; i++)
          _visited.contains(i) ? pages[i] : const SizedBox.shrink(),
      ],
    );
    return Scaffold(
      body: Row(
        children: [
          if (wide)
            Container(
              width: 224,
              decoration: BoxDecoration(
                color: scheme.surface,
                border: BorderDirectional(
                  end: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 36, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const BrandMark(),
                      const SizedBox(height: 52),
                      Text(
                        context.tr('你的日常衣橱'),
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < _labels.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: _index == i
                                ? scheme.primary.withValues(alpha: 0.09)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _select(i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _icons[i],
                                      size: 21,
                                      color: _index == i
                                          ? scheme.primary
                                          : scheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        context.tr(_labels[i]),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _index == i
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: _index == i
                                              ? scheme.primary
                                              : scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (_index == i)
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: scheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.spa_outlined,
                              color: scheme.primary,
                              size: 26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('好衣服，值得再穿。'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('Wear more.\nWaste less.'),
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 12,
                                height: 1.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.tune, size: 18),
                        label: Text(context.tr('偏好设置')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(child: content),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: NavigationBar(
                height: 74,
                selectedIndex: _index,
                onDestinationSelected: _select,
                destinations: [
                  for (var i = 0; i < _labels.length; i++)
                    NavigationDestination(
                      icon: Icon(_icons[i], size: 22),
                      label: context.tr(_labels[i]),
                    ),
                ],
              ),
            ),
    );
  }
}
