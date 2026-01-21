import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  final Map<String, String> _localizedStrings;

  AppLocalizations(this.locale, this._localizedStrings);

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('fr'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String tr(String key, {Map<String, String>? params}) {
    var value = _localizedStrings[key] ?? key;
    if (params != null && params.isNotEmpty) {
      params.forEach((paramKey, paramValue) {
        value = value.replaceAll('{$paramKey}', paramValue);
      });
    }
    return value;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (supported) => supported.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final jsonString = await rootBundle.loadString(
      'lib/l10n/app_${locale.languageCode}.arb',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final localizedStrings = <String, String>{};

    jsonMap.forEach((key, value) {
      if (key.startsWith('@')) return;
      if (value is String) {
        localizedStrings[key] = value;
      }
    });

    return AppLocalizations(locale, localizedStrings);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
