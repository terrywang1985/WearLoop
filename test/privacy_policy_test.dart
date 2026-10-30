import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearloop/l10n/app_localizations.dart';
import 'package:wearloop/l10n/locale_controller.dart';
import 'package:wearloop/privacy/privacy_policy.dart';
import 'package:wearloop/screens/privacy_policy_screen.dart';
import 'package:wearloop/screens/settings_screen.dart';
import 'package:wearloop/storage/storage_web.dart' as preferences;
import 'package:wearloop/store.dart';
import 'package:wearloop/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all shipped policy assets have complete localized sections', () async {
    for (final locale in supportedAppLocales) {
      final policy = await PrivacyPolicy.load(locale);
      expect(policy.languageCode, locale.languageCode);
      expect(policy.title, PrivacyPolicy.titleFor(locale));
      expect(
        policy.sections.map((section) => section.id),
        orderedEquals(PrivacyPolicy.sectionIds),
      );
      expect(
        policy.sections.every((section) => section.body.isNotEmpty),
        isTrue,
      );
      expect(policy.text('updated'), contains('2026-10-29'));
    }
    expect((await PrivacyPolicy.load(const Locale('zz'))).languageCode, 'en');
    expect(PrivacyPolicy.languageFor(const Locale('in')), 'id');
  });

  test('policy parsing rejects incomplete or mislabeled data', () async {
    final source = Map<String, dynamic>.from(
      jsonDecode(await rootBundle.loadString('assets/privacy/en.json')) as Map,
    );
    final incomplete = Map<String, dynamic>.from(source)..['sections'] = [];
    expect(() => PrivacyPolicy.fromJson(incomplete), throwsFormatException);
    final wrongName = Map<String, dynamic>.from(source)..['appName'] = 'Other';
    expect(() => PrivacyPolicy.fromJson(wrongName), throwsFormatException);
  });

  test('configuration requires an explicit contact and an HTTPS link', () {
    expect(const PrivacyConfiguration().email, isNull);
    expect(const PrivacyConfiguration(supportEmail: 'invalid').email, isNull);
    expect(
      const PrivacyConfiguration(supportEmail: 'privacy@example.test').email,
      'privacy@example.test',
    );
    expect(
      const PrivacyConfiguration(privacyUrl: 'http://example.test')
          .onlinePolicy,
      isNull,
    );
    expect(
      const PrivacyConfiguration(privacyUrl: 'https://user:secret@example.test')
          .onlinePolicy,
      isNull,
    );
    expect(
      const PrivacyConfiguration(privacyUrl: 'https://example.test/privacy/')
          .onlinePolicy
          ?.host,
      'example.test',
    );
  });

  for (final locale in supportedAppLocales) {
    testWidgets('${locale.languageCode} policy is readable at 320px with RTL', (
      tester,
    ) async {
      await tester.runAsync(() => PrivacyPolicy.load(locale));
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.25)),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyPolicyScreen(
                      configuration: PrivacyConfiguration(
                        supportEmail: 'privacy@example.test',
                        privacyUrl: 'https://example.test/privacy/',
                      ),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(PrivacyPolicy.titleFor(locale)), findsOneWidget);
      final expectedDirection = ['ar', 'ur'].contains(locale.languageCode)
          ? TextDirection.rtl
          : TextDirection.ltr;
      expect(
        Directionality.of(tester.element(find.byType(ListView))),
        expectedDirection,
      );
      final scrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('privacy-online-url')),
        500,
        scrollable: scrollable,
        maxScrolls: 80,
      );
      expect(find.text('privacy@example.test'), findsOneWidget);
      expect(find.text('https://example.test/privacy/'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final policy = await PrivacyPolicy.load(locale);
      await tester.tap(find.byTooltip(policy.text('back')));
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Settings privacy entry opens offline local policy', (
    tester,
  ) async {
    await tester.runAsync(() => PrivacyPolicy.load(const Locale('zh')));
    SharedPreferences.setMockInitialValues({});
    final store = WardrobeStore(
      storageFactory: preferences.WearLoopStorage.open,
    );
    await store.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: store,
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: supportedAppLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(Brightness.light),
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('privacy-policy-entry')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('privacy-policy-entry')));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyPolicyScreen), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
    expect(find.text('保存在设备上的数据'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
