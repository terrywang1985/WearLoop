import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../legal/open_source.dart';

class OpenSourceScreen extends StatefulWidget {
  const OpenSourceScreen({
    super.key,
    this.configuration = OpenSourceConfiguration.current,
  });

  final OpenSourceConfiguration configuration;

  @override
  State<OpenSourceScreen> createState() => _OpenSourceScreenState();
}

class _OpenSourceScreenState extends State<OpenSourceScreen> {
  String? _language;
  late Future<OpenSourceCopy> _copy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final language = OpenSourceCopy.languageFor(locale);
    if (_language != language) {
      _language = language;
      _copy = OpenSourceCopy.load(locale);
    }
  }

  void _retry() => setState(() {
    _copy = OpenSourceCopy.load(Localizations.localeOf(context));
  });

  Future<void> _copySource(OpenSourceCopy copy, Uri uri) async {
    try {
      await Clipboard.setData(ClipboardData(text: uri.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.text('copied'))),
      );
    } catch (_) {
      // The selectable public address remains available if clipboard access
      // is unavailable on this platform.
    }
  }

  void _openDocument(OpenSourceCopy copy, {required bool fullLicense}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _LegalDocumentScreen(
          title: copy.text(fullLicense ? 'fullLicense' : 'notices'),
          copy: copy,
          fullLicense: fullLicense,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<OpenSourceCopy>(
    future: _copy,
    builder: (context, snapshot) {
      final copy = snapshot.data;
      final theme = Theme.of(context);
      final source = widget.configuration.publicSource;
      return Scaffold(
        appBar: AppBar(
          title: Text(OpenSourceCopy.titleFor(Localizations.localeOf(context))),
        ),
        body: SafeArea(
          child: copy == null
              ? Center(
                  child: snapshot.hasError
                      ? TextButton(
                          onPressed: _retry,
                          child: Text(MaterialLocalizations.of(context)
                              .refreshIndicatorSemanticLabel),
                        )
                      : const CircularProgressIndicator(),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      key: const ValueKey('open-source-content'),
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 40),
                      children: [
                        Text('WearLoop', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        SelectableText(
                          wearLoopCopyright,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 22),
                        SelectableText(
                          copy.text('summary'),
                          key: const ValueKey('open-source-summary'),
                          style: theme.textTheme.bodyLarge?.copyWith(height: 1.65),
                        ),
                        const SizedBox(height: 20),
                        SelectableText(
                          copy.text('warranty'),
                          key: const ValueKey('open-source-warranty'),
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.65),
                        ),
                        const SizedBox(height: 28),
                        Text(copy.text('sourceHeading'), style: theme.textTheme.titleMedium),
                        const SizedBox(height: 10),
                        if (source == null)
                          Text(copy.text('sourceUnavailable'))
                        else ...[
                          SelectableText(
                            source.toString(),
                            key: const ValueKey('open-source-url'),
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FilledButton.tonalIcon(
                              key: const ValueKey('copy-source-url'),
                              onPressed: () => _copySource(copy, source),
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              label: Text(copy.text('copySource')),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(copy.text('licenseNote'), style: theme.textTheme.bodySmall),
                        const SizedBox(height: 14),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: OutlinedButton.icon(
                            key: const ValueKey('read-agpl-license'),
                            onPressed: () => _openDocument(copy, fullLicense: true),
                            icon: const Icon(Icons.article_outlined, size: 18),
                            label: Text(copy.text('fullLicense')),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: OutlinedButton.icon(
                            key: const ValueKey('read-third-party-notices'),
                            onPressed: () => _openDocument(copy, fullLicense: false),
                            icon: const Icon(Icons.library_books_outlined, size: 18),
                            label: Text(copy.text('notices')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    },
  );
}

class _LegalDocumentScreen extends StatefulWidget {
  const _LegalDocumentScreen({
    required this.title,
    required this.copy,
    required this.fullLicense,
  });

  final String title;
  final OpenSourceCopy copy;
  final bool fullLicense;

  @override
  State<_LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<_LegalDocumentScreen> {
  late Future<String> _document;

  @override
  void initState() {
    super.initState();
    _document = _load();
  }

  Future<String> _load() async {
    if (widget.fullLicense) {
      return rootBundle.loadString('assets/legal/AGPL-3.0.txt');
    }
    final notices = await rootBundle.loadString('assets/legal/NOTICE.txt');
    final thirdParty = await rootBundle.loadString('assets/legal/THIRD_PARTY_NOTICES.txt');
    return '$notices\n\n$thirdParty';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: FutureBuilder<String>(
        future: _document,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (!snapshot.hasError) {
              return Center(child: CircularProgressIndicator(semanticsLabel: widget.copy.text('loading')));
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.copy.text('error')),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _document = _load()),
                      child: Text(widget.copy.text('retry')),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                key: const ValueKey('legal-document-scroll'),
                padding: const EdgeInsets.all(20),
                children: [
                  SelectableText(
                    snapshot.data!,
                    key: const ValueKey('legal-document-text'),
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.55),
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
