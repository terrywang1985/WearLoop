import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

/// Public contact fields supplied with --dart-define for a release build.
/// Empty defaults deliberately avoid inventing a developer email or website.
class PrivacyConfiguration {
  const PrivacyConfiguration({this.supportEmail = '', this.privacyUrl = ''});

  static const current = PrivacyConfiguration(
    supportEmail: String.fromEnvironment(
      'WEARLOOP_SUPPORT_EMAIL',
      defaultValue: 'wearloop@3qk7.com',
    ),
    privacyUrl: String.fromEnvironment('WEARLOOP_PRIVACY_URL'),
  );

  final String supportEmail;
  final String privacyUrl;

  String? get email {
    final value = supportEmail.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value) ? value : null;
  }

  Uri? get onlinePolicy {
    final uri = Uri.tryParse(privacyUrl.trim());
    return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty &&
            uri.userInfo.isEmpty
        ? uri
        : null;
  }
}

class PrivacyPolicySection {
  const PrivacyPolicySection({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;
}

class PrivacyPolicy {
  const PrivacyPolicy._(this.languageCode, this.labels, this.sections);

  static final _cache = <String, PrivacyPolicy>{};

  static const titles = {
    'en': 'Privacy policy',
    'zh': '隐私政策',
    'ja': 'プライバシーポリシー',
    'ko': '개인정보 처리방침',
    'es': 'Política de privacidad',
    'fr': 'Politique de confidentialité',
    'de': 'Datenschutzerklärung',
    'vi': 'Chính sách quyền riêng tư',
    'hi': 'गोपनीयता नीति',
    'ar': 'سياسة الخصوصية',
    'bn': 'গোপনীয়তা নীতি',
    'pt': 'Política de privacidade',
    'ru': 'Политика конфиденциальности',
    'ur': 'رازداری کی پالیسی',
    'id': 'Kebijakan privasi',
  };

  static const sectionIds = [
    'local_data',
    'photos',
    'recognition',
    'sharing',
    'developer',
    'backup',
    'deletion',
    'contact',
    'online_policy',
  ];

  static String languageFor(Locale locale) {
    final language = locale.languageCode == 'in' ? 'id' : locale.languageCode;
    return titles.containsKey(language) ? language : 'en';
  }

  static String titleFor(Locale locale) => titles[languageFor(locale)]!;

  final String languageCode;
  final Map<String, String> labels;
  final List<PrivacyPolicySection> sections;

  String text(String key) => labels[key]!;
  String get title => text('title');

  static Future<PrivacyPolicy> load(
    Locale locale, {
    AssetBundle? bundle,
  }) async {
    final language = languageFor(locale);
    if (bundle == null) {
      final cached = _cache[language];
      if (cached != null) return cached;
    }
    final json = await (bundle ?? rootBundle).loadString(
      'assets/privacy/$language.json',
    );
    final policy = PrivacyPolicy.fromJson(
      Map<String, dynamic>.from(jsonDecode(json) as Map),
    );
    if (bundle == null) _cache[language] = policy;
    return policy;
  }

  factory PrivacyPolicy.fromJson(Map<String, dynamic> data) {
    final language = data['languageCode'];
    if (language is! String || !titles.containsKey(language)) {
      throw const FormatException('Invalid privacy policy language');
    }
    final labels = <String, String>{};
    for (final key in const [
      'title',
      'back',
      'updated',
      'summary',
      'contactLabel',
      'contactPending',
      'onlineLabel',
      'loading',
      'error',
      'retry',
    ]) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Missing privacy policy label: $key');
      }
      labels[key] = value;
    }
    if (data['appName'] != 'WearLoop' || data['updatedDate'] != '2026-10-29') {
      throw const FormatException('Invalid privacy policy identity or version');
    }
    final rawSections = data['sections'];
    if (rawSections is! List || rawSections.length != sectionIds.length) {
      throw const FormatException('Incomplete privacy policy sections');
    }
    final sections = <PrivacyPolicySection>[];
    for (var index = 0; index < sectionIds.length; index++) {
      final entry = rawSections[index];
      if (entry is! Map ||
          entry['id'] != sectionIds[index] ||
          entry['title'] is! String ||
          (entry['title'] as String).trim().isEmpty ||
          entry['body'] is! String ||
          (entry['body'] as String).trim().isEmpty) {
        throw FormatException('Invalid privacy policy section: $index');
      }
      sections.add(
        PrivacyPolicySection(
          id: sectionIds[index],
          title: entry['title'] as String,
          body: entry['body'] as String,
        ),
      );
    }
    return PrivacyPolicy._(
      language,
      Map.unmodifiable(labels),
      List.unmodifiable(sections),
    );
  }
}
