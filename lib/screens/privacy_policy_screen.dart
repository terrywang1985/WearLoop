import 'package:flutter/material.dart';

import '../privacy/privacy_policy.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({
    super.key,
    this.configuration = PrivacyConfiguration.current,
  });

  final PrivacyConfiguration configuration;

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  String? _language;
  late Future<PrivacyPolicy> _policy;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final language = PrivacyPolicy.languageFor(locale);
    if (_language != language) {
      _language = language;
      _policy = PrivacyPolicy.load(locale);
    }
  }

  void _retry() => setState(() {
    _policy = PrivacyPolicy.load(Localizations.localeOf(context));
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<PrivacyPolicy>(
    future: _policy,
    builder: (context, snapshot) {
      final policy = snapshot.data;
      final theme = Theme.of(context);
      final material = MaterialLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(
          title: Text(
            policy?.title ??
                PrivacyPolicy.titleFor(Localizations.localeOf(context)),
          ),
          leading: IconButton(
            tooltip: policy?.text('back') ?? material.backButtonTooltip,
            onPressed: () => Navigator.maybePop(context),
            icon: const BackButtonIcon(),
          ),
        ),
        body: SafeArea(
          child: policy == null
              ? Center(
                  child: snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.description_outlined),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _retry,
                              child: Text(
                                material.refreshIndicatorSemanticLabel,
                              ),
                            ),
                          ],
                        )
                      : const CircularProgressIndicator(),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      key: ValueKey('privacy-${policy.languageCode}'),
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        20,
                        12,
                        20,
                        36,
                      ),
                      children: [
                        Text('WearLoop', style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text(
                          policy.text('updated'),
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 20),
                        SelectableText(
                          policy.text('summary'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                        ),
                        for (final section in policy.sections) ...[
                          const SizedBox(height: 24),
                          Text(
                            section.title,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            section.body,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.65,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          policy.text('contactLabel'),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          key: const ValueKey('privacy-contact-value'),
                          widget.configuration.email ??
                              policy.text('contactPending'),
                          textDirection: widget.configuration.email == null
                              ? null
                              : TextDirection.ltr,
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (widget.configuration.onlinePolicy
                            case final uri?) ...[
                          const SizedBox(height: 20),
                          Text(
                            policy.text('onlineLabel'),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            key: const ValueKey('privacy-online-url'),
                            uri.toString(),
                            textDirection: TextDirection.ltr,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      );
    },
  );
}
