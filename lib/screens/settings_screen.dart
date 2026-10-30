import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_info.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../legal/open_source.dart';
import '../privacy/privacy_policy.dart';
import '../store.dart';
import '../widgets/brand_mark.dart';
import 'privacy_policy_screen.dart';
import 'open_source_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String message,
  ) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(context.tr('取消')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(context.tr('确定')),
            ),
          ],
        ),
      ) ??
      false;

  void _chooseLanguage(BuildContext context) {
    final controller = AppLocaleScope.maybeOf(context);
    if (controller == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => FractionallySizedBox(
        heightFactor: .88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sheet.tr('语言'),
                      style: Theme.of(sheet).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: sheet.tr('关闭'),
                    onPressed: () => Navigator.pop(sheet),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _LanguageOption(
                    label: sheet.tr('跟随系统'),
                    selected: controller.locale == null,
                    onTap: () async {
                      await controller.setLocale(null);
                      if (sheet.mounted) Navigator.pop(sheet);
                    },
                  ),
                  for (final code in languageNames.keys)
                    _LanguageOption(
                      label: languageNames[code]!,
                      selected: controller.locale?.languageCode == code,
                      onTap: () async {
                        await controller.setLocale(Locale(code));
                        if (sheet.mounted) Navigator.pop(sheet);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final controller = AppLocaleScope.maybeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('设置'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 40),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: .35),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('好衣服，值得反复穿。'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('整理衣橱、存下搭配，把日常穿着变成喜欢的循环。'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Divider(color: colors.primary.withValues(alpha: .12)),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            context.tr('无需账号，衣橱数据保存在本机。'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel(
                eyebrow: context.tr('YOUR PREFERENCES'),
                title: context.tr('语言与显示'),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  leading: Icon(Icons.language, color: colors.primary),
                  title: Text(context.tr('语言')),
                  subtitle: Text(
                    controller?.locale == null
                        ? context.tr('跟随系统')
                        : languageNames[controller!.locale!.languageCode]!,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: controller == null
                      ? null
                      : () => _chooseLanguage(context),
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel(
                eyebrow: context.tr('YOUR ROUTINE'),
                title: context.tr('穿着偏好'),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.wb_twilight_rounded,
                            size: 21,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              context.tr('多久没穿算「被遗忘」'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        context.tr('超过 {days} 天没穿的衣服，会出现在今日页提醒，帮你重新发现它们。', {
                          'days': store.forgottenDays,
                        }),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 9,
                        runSpacing: 8,
                        children: [
                          for (final days in const [14, 30, 60, 90])
                            ChoiceChip(
                              label: Text(
                                context.tr('{days} 天', {'days': days}),
                              ),
                              selected: store.forgottenDays == days,
                              onSelected: (_) => store.setForgottenDays(days),
                              selectedColor: colors.primary,
                              labelStyle: TextStyle(
                                color: store.forgottenDays == days
                                    ? colors.onPrimary
                                    : colors.onSurface,
                                fontWeight: store.forgottenDays == days
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionLabel(
                eyebrow: context.tr('YOUR DATA'),
                title: context.tr('衣橱数据'),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  key: const ValueKey('open-source-entry'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  leading: Icon(Icons.code_outlined, color: colors.primary),
                  title: Text(OpenSourceCopy.titleFor(Localizations.localeOf(context))),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const OpenSourceScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _DataAction(
                      icon: Icons.auto_awesome_outlined,
                      title: context.tr('恢复示例数据'),
                      subtitle: context.tr('用一套示例衣橱体验所有功能'),
                      onTap: () async {
                        if (await _confirm(
                          context,
                          context.tr('恢复示例数据？'),
                          context.tr('当前所有数据会被示例数据替换。'),
                        )) {
                          store.resetDemo();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr('示例衣橱已恢复'))),
                          );
                        }
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 22),
                      child: Divider(),
                    ),
                    _DataAction(
                      icon: Icons.delete_sweep_outlined,
                      title: context.tr('清空全部数据'),
                      subtitle: context.tr('删除衣服、搭配和穿着记录，从零开始'),
                      destructive: true,
                      onTap: () async {
                        if (await _confirm(
                          context,
                          context.tr('清空全部数据？'),
                          context.tr('衣服、搭配和穿着记录都会被删除，无法恢复。'),
                        )) {
                          store.clearAll();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr('衣橱数据已清空'))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Card(
                child: ListTile(
                  key: const ValueKey('privacy-policy-entry'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  leading: Icon(
                    Icons.privacy_tip_outlined,
                    color: colors.primary,
                  ),
                  title: Text(
                    PrivacyPolicy.titleFor(Localizations.localeOf(context)),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 9,
                  ),
                  child: AboutListTile(
                    icon: Icon(
                      Icons.info_outline_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                    applicationName: 'WearLoop',
                    applicationVersion: appVersion,
                    applicationLegalese: context.tr(
                      'Wear More. Waste Less.\n数据仅保存在本机。',
                    ),
                    child: Text(
                      context.tr('关于 WearLoop'),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr('少一点遗忘，多一点喜欢。'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    checked: selected,
    inMutuallyExclusiveGroup: true,
    button: true,
    child: ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      title: Text(label),
      selected: selected,
      onTap: onTap,
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.eyebrow, required this.title});
  final String eyebrow;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.8,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 5),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _DataAction extends StatelessWidget {
  const _DataAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = destructive ? colors.error : colors.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color, size: 21),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: destructive ? colors.error : colors.onSurface),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
