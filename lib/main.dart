import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_shell.dart';
import 'store.dart';
import 'theme.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = WardrobeStore();
  await store.load();
  runApp(
    ChangeNotifierProvider.value(value: store, child: const WearLoopApp()),
  );
}

class WearLoopApp extends StatefulWidget {
  const WearLoopApp({super.key, this.locale});
  final Locale? locale;
  @override
  State<WearLoopApp> createState() => _WearLoopAppState();
}

class _WearLoopAppState extends State<WearLoopApp> {
  late final LocaleController _localeController;
  @override
  void initState() {
    super.initState();
    _localeController = LocaleController(initialLocale: widget.locale);
    if (widget.locale == null) _localeController.load();
  }

  @override
  void dispose() {
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: _localeController,
      child: AnimatedBuilder(
        animation: _localeController,
        builder: (context, _) => MaterialApp(
          title: 'WearLoop',
          debugShowCheckedModeBanner: false,
          locale: _localeController.locale,
          supportedLocales: supportedAppLocales,
          localeListResolutionCallback: resolveAppLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          builder: (context, child) {
            final phonePreview =
                kIsWeb &&
                (const bool.fromEnvironment('WEARLOOP_PHONE_PREVIEW') ||
                    Uri.base.queryParameters['preview'] == 'phone');
            if (!phonePreview || MediaQuery.sizeOf(context).width < 600) {
              return child!;
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight - 48;
                return ColoredBox(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF202B23)
                      : const Color(0xFFE8ECDD),
                  child: Center(
                    child: Container(
                      width: 414,
                      height: height,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(size: Size(414, height)),
                        child: child!,
                      ),
                    ),
                  ),
                );
              },
            );
          },
          home: const HomeShell(),
        ),
      ),
    );
  }
}
