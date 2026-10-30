// Run explicitly; this capture tool is outside test/ and never runs in CI tests.
// flutter test tools/store_screenshots_test.dart --no-pub --concurrency=1
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:wearloop/main.dart';
import 'package:wearloop/l10n/app_localizations.dart';
import 'package:wearloop/l10n/locale_controller.dart';
import 'package:wearloop/models.dart';
import 'package:wearloop/storage/storage_contract.dart';
import 'package:wearloop/store.dart';
import 'package:wearloop/theme.dart';

const storeLocales = <String, String>{
  'zh': 'zh-CN',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
  'en': 'en-US',
  'es': 'es-ES',
  'fr': 'fr-FR',
  'de': 'de-DE',
  'vi': 'vi',
  'hi': 'hi-IN',
  'ar': 'ar',
  'bn': 'bn-BD',
  'pt': 'pt-BR',
  'ru': 'ru-RU',
  'ur': 'ur',
  'id': 'id',
};
const pageNames = ['01-today', '02-wardrobe', '03-outfits', '04-insights'];
final captureDate = DateTime(2026, 10, 29, 12);
final capturedText = <String, Map<String, List<String>>>{};

/// Capture data is isolated in memory; no database or user preferences open.
class _CaptureStorage implements WardrobeStorage {
  @override
  Future<StorageSnapshot> load() async => const StorageSnapshot(
    initialized: false,
    items: [],
    outfits: [],
    logs: [],
    forgottenDays: 30,
  );
  @override
  Future<void> saveSnapshot({
    required List<ClothingItem> items,
    required List<Outfit> outfits,
    required List<WearLog> logs,
    required int forgottenDays,
  }) async {}
  @override
  Future<String?> saveImage(Uint8List bytes, String itemId) async => null;
  @override
  Future<void> deleteImage(String? path) async {}
  @override
  Future<void> clearImages() async {}
}

Future<void> _saveBoundary(GlobalKey key, String path, double scale) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: scale);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).parent.create(recursive: true);
  await File(path).writeAsBytes(data!.buffer.asUint8List());
  image.dispose();
}

class FeatureGraphic extends StatelessWidget {
  const FeatureGraphic({super.key, required this.tagline});
  final String tagline;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: kPaper,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 58, vertical: 44),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WearLoop',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontFamily: 'Georgia',
                      fontSize: 58,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.7,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    tagline,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 43,
                      height: 1.34,
                      fontWeight: FontWeight.w600,
                      color: kBrand,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 38),
            Expanded(
              flex: 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 340,
                      height: 340,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE8EDDF),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 0,
                    top: 4,
                    width: 255,
                    height: 310,
                    child: Transform.rotate(
                      angle: -0.07,
                      child: Image.asset(
                        'assets/clothing/knit.webp',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    end: -12,
                    top: 94,
                    width: 184,
                    height: 300,
                    child: Transform.rotate(
                      angle: 0.06,
                      child: Image.asset(
                        'assets/clothing/jeans.webp',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 6,
                    bottom: 0,
                    width: 165,
                    height: 234,
                    child: Transform.rotate(
                      angle: -0.08,
                      child: Image.asset(
                        'assets/clothing/trench.webp',
                        fit: BoxFit.contain,
                      ),
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

Future<ByteData> _fontFile(String path) async {
  final data = await File(path).readAsBytes();
  return ByteData.sublistView(data);
}

Future<void> _loadFonts() async {
  final sdk =
      Platform.environment['WEARLOOP_FLUTTER_SDK'] ??
      '${Platform.environment['USERPROFILE']}/.codex/runtimes/flutter-3.47.8';
  final systemFonts =
      Platform.environment['WEARLOOP_SYSTEM_FONTS'] ??
      '${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts';
  final engineFonts = '$sdk/engine/src/flutter/txt/third_party/fonts';
  final families = <String, List<String>>{
    // The headless Windows engine uses these defaults for standalone RichText
    // and explicit button TextStyles which don't inherit Material typography.
    'Segoe UI': [
      '$engineFonts/Roboto-Regular.ttf',
      '$engineFonts/Roboto-Medium.ttf',
    ],
    'Arial': [
      '$engineFonts/Roboto-Regular.ttf',
      '$engineFonts/Roboto-Medium.ttf',
    ],
    'sans-serif': [
      // Keep a separate family for Hangul: several same-weight CJK faces
      // registered under one alias do not form a glyph fallback chain.
      '$systemFonts/malgun.ttf',
      '$systemFonts/malgunbd.ttf',
    ],
    'Roboto': [
      '$engineFonts/Roboto-Regular.ttf',
      '$engineFonts/Roboto-Medium.ttf',
    ],
    'Georgia': ['$systemFonts/georgia.ttf', '$systemFonts/georgiab.ttf'],
    'Noto Sans': ['$engineFonts/Roboto-Regular.ttf'],
    'Noto Sans Arabic': ['$engineFonts/NotoNaskhArabic-Regular.ttf'],
    'Noto Sans Devanagari': [
      '$systemFonts/Nirmala.ttf',
      '$systemFonts/NirmalaB.ttf',
    ],
    'Noto Sans Bengali': [
      '$systemFonts/Nirmala.ttf',
      '$systemFonts/NirmalaB.ttf',
    ],
    'Noto Sans CJK SC': [
      '$systemFonts/Noto Sans SC (TrueType).otf',
      '$systemFonts/Noto Sans SC Bold (TrueType).otf',
    ],
    'MaterialIcons': [
      '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ],
  };
  for (final family in families.entries) {
    final loader = FontLoader(family.key);
    for (final file in family.value) {
      loader.addFont(_fontFile(file));
    }
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadFonts);
  final requested = Platform.environment['WEARLOOP_CAPTURE_LANGUAGES']
      ?.split(',')
      .toSet();
  for (final entry in storeLocales.entries) {
    if (requested != null && !requested.contains(entry.key)) continue;
    testWidgets('capture ${entry.value} real Flutter app', (tester) async {
      final store = WardrobeStore(
        storageFactory: () async => _CaptureStorage(),
        clock: () => captureDate,
      );
      await store.load();
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(1080, 1920);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      final previousDisableShadows = debugDisableShadows;
      debugDisableShadows = false;
      addTearDown(() {
        debugDisableShadows = previousDisableShadows;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      });
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: ChangeNotifierProvider.value(
            value: store,
            child: WearLoopApp(locale: Locale(entry.key)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Decode bundled clothing photos in real async time before snapshotting.
      await tester.runAsync(() async {
        final context = tester.element(find.byType(MaterialApp));
        final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
        for (final asset in manifest.listAssets().where(
          (a) => a.startsWith('assets/clothing/') && a.endsWith('.webp'),
        )) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      for (var page = 0; page < pageNames.length; page++) {
        if (page > 0) {
          await tester.tap(find.byType(NavigationDestination).at(page));
          await tester.pumpAndSettle();
        }
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.value} ${pageNames[page]} must fit without errors',
        );
        final element = tester.element(find.byType(MaterialApp));
        expect(
          Localizations.localeOf(tester.element(find.byType(NavigationBar)))
              .languageCode,
          entry.key,
        );
        expect(
          Directionality.of(tester.element(find.byType(NavigationBar))),
          {'ar', 'ur'}.contains(entry.key)
              ? TextDirection.rtl
              : TextDirection.ltr,
        );
        expect(element.mounted, isTrue);
        final texts = find
            .byType(RichText)
            .evaluate()
            .map((e) {
              final span = (e.widget as RichText).text;
              expect(
                span.style?.fontFamily,
                isNotNull,
                reason:
                    '${entry.value}: ${span.toPlainText()} must inherit a real font',
              );
              expect(span.style?.fontFamily, isNot('Ahem'));
              return span.toPlainText();
            })
            .toSet()
            .toList();
        (capturedText[entry.value] ??= {})[pageNames[page]] = texts;
        await tester.runAsync(() async {
          await _saveBoundary(
            boundaryKey,
            'docs/google-play/screenshots/${entry.value}/${pageNames[page]}.png',
            2,
          );
        });
      }
      final copies = jsonDecode(
        (await tester.runAsync(
          () =>
              File('docs/google-play/listings/screenshot-copy.json')
                  .readAsString(),
        ))!,
      ) as Map<String, dynamic>;
      final tagline =
          (copies[entry.value] as Map<String, dynamic>)['tagline'] as String;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1024, 500);
      final featureKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: featureKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: Locale(entry.key),
            supportedLocales: supportedAppLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: buildTheme(Brightness.light),
            home: FeatureGraphic(tagline: tagline),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${entry.value} feature graphic',
      );
      (capturedText[entry.value] ??= {})['feature-graphic'] = [
        'WearLoop',
        tagline,
      ];
      await tester.runAsync(
        () => _saveBoundary(
          featureKey,
          'docs/google-play/graphics/${entry.value}/feature-graphic.png',
          1,
        ),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      debugDisableShadows = previousDisableShadows;
    });
  }
  tearDownAll(() async {
    final metadata = {
      'captureDate': '2026-10-29T12:00:00',
      'dimensions': {'width': 1080, 'height': 1920},
      'logicalViewport': {'width': 540, 'height': 960, 'pixelRatio': 2},
      'theme': 'light',
      'source': 'Unmodified WearLoop HomeShell widgets with isolated seeded demo storage',
      'method': 'Flutter TestWidgetsFlutterBinding + RenderRepaintBoundary PNG',
      'platformChrome': 'None; app content only',
      'locales': storeLocales,
      'pages': pageNames,
      'fontNote': 'Real text fonts loaded for capture; Ahem test glyphs are not used. Host fonts are external and not bundled into the production app.',
    };
    final directory = Directory('docs/google-play/screenshots');
    await directory.create(recursive: true);
    await File('${directory.path}/capture-metadata.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(metadata)}\n',
    );
    await File('${directory.path}/rendered-text.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(capturedText)}\n',
    );
  });
}
