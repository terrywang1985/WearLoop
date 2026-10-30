import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../l10n/app_localizations.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/brand_mark.dart';
import '../widgets/item_thumb.dart';

/// A locally rendered outfit card, ready to share as an image or plain text.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.outfitId});
  final String outfitId;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _cardKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  bool _busy = false;

  String _shareText(WardrobeStore store, Outfit outfit) {
    final items = store.itemsOf(outfit);
    return [
      context.tr('我的穿搭：{name}', {'name': context.outfitName(outfit)}),
      if (outfit.tags.isNotEmpty)
        context.tr('场景：{tags}', {
          'tags': outfit.tags.map(context.tagLabel).join(' / '),
        }),
      for (final item in items)
        '· ${context.itemName(item)}${item.brand.isNotEmpty ? ' (${item.brand})' : ''}',
      '',
      context.tr('用 WearLoop 记录穿搭 · Wear More. Waste Less.'),
    ].join('\n');
  }

  Future<void> _copyText(WardrobeStore store, Outfit outfit) async {
    try {
      await Clipboard.setData(ClipboardData(text: _shareText(store, outfit)));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('穿搭文字已复制，去分享你的灵感吧。'))));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr('暂时无法复制，请再试一次。'))));
    }
  }

  Future<void> _shareImage(WardrobeStore store, Outfit outfit) async {
    if (_busy) return;
    final buttonBox = _shareButtonKey.currentContext?.findRenderObject();
    final origin = buttonBox is RenderBox && buttonBox.hasSize
        ? buttonBox.localToGlobal(Offset.zero) & buttonBox.size
        : null;
    final text = _shareText(store, outfit);
    setState(() => _busy = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary = _cardKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        throw StateError(context.tr('分享卡片尚未准备好'));
      }
      // Bound the longest image edge to avoid excessive memory for long lists.
      final ratio = math.min(
        3.0,
        6000 / math.max(boundary.size.width, boundary.size.height),
      );
      final image = await boundary.toImage(pixelRatio: ratio);
      ByteData? data;
      try {
        data = await image.toByteData(format: ui.ImageByteFormat.png);
      } finally {
        image.dispose();
      }
      if (!mounted) return;
      if (data == null) throw StateError(context.tr('无法生成分享图片'));
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          files: [
            XFile.fromData(bytes, mimeType: 'image/png', name: 'wearloop.png'),
          ],
          fileNameOverrides: ['wearloop_outfit.png'],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('图片分享暂未完成，请重试或复制穿搭文字。'))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WardrobeStore>();
    final outfit = store.outfitById(widget.outfitId);
    final theme = Theme.of(context);
    if (outfit == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('分享搭配'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.style_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 20),
                Text(
                  context.tr('这套搭配已不在衣橱里'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('返回搭配页，选择另一份日常灵感。'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: Text(context.tr('返回')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final items = store.itemsOf(outfit);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('分享搭配'))),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('分享你的风格'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr('把喜欢，分享出去'),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('为这一套日常，留一张好看的穿搭卡片。'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 26),
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kInk.withValues(alpha: .07),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: Theme(
                      data: buildTheme(Brightness.light),
                      child: _ShareCard(outfit: outfit, items: items),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.tr('分享时将自动生成完整图片'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      label: Text(context.tr('复制文字')),
                      onPressed: _busy ? null : () => _copyText(store, outfit),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: _shareButtonKey,
                      icon: _busy
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            )
                          : const Icon(Icons.ios_share_rounded, size: 18),
                      label: Text(
                        _busy ? context.tr('生成中') : context.tr('分享图片'),
                      ),
                      onPressed: _busy
                          ? null
                          : () => _shareImage(store, outfit),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.outfit, required this.items});
  final Outfit outfit;
  final List<ClothingItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE3E7DD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandMark(compact: true),
          const SizedBox(height: 26),
          Row(
            children: [
              Container(width: 24, height: 1, color: kBrand),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  context.tr('我的穿搭手记'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: kBrand,
                    fontSize: 9,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.outfitName(outfit),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: kInk,
              fontSize: 27,
              height: 1.35,
            ),
          ),
          if (outfit.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final tag in outfit.tags)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF0E4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '# ${context.tagLabel(tag)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: kBrand,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: OutfitCollage(items, gap: 8),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                context.tr('这套搭配'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                context.tr('{count} 件单品', {'count': items.length}),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF768171),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              context.tr('先加入喜欢的单品，再让搭配完整出场。'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF768171),
              ),
            ),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(top: 7),
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD9DED3)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.itemName(item),
                      style: theme.textTheme.bodySmall?.copyWith(color: kInk),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.categoryLabel(item.category),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF768171),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFDFE5D8)),
          const SizedBox(height: 20),
          Text(
            context.tr('穿得更多，浪费更少。'),
            style: TextStyle(
              fontFamily: 'Georgia',
              fontFamilyFallback: const ['serif'],
              fontStyle: FontStyle.italic,
              color: kBrand.withValues(alpha: .85),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                context.tr('让好衣服，反复出场。'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF768171),
                  fontSize: 10,
                ),
              ),
              Text(
                '·  ${context.date(DateTime.now())}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF768171),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
