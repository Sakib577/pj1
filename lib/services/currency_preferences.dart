import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/currency_settings.dart';

/// Durable on-device currency settings. Firestore synchronizes the selected
/// code between devices; this store makes both the code and last known rates
/// available immediately, including while offline.
class CurrencyPreferences {
  CurrencyPreferences._();

  static const _lastCodeKey = 'currency.last_code';
  static const _ratesKey = 'currency.usd_rates';

  static Future<void> hydrate() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_lastCodeKey);
    final rates = _readRates(preferences.getString(_ratesKey));
    if (code != null && code.trim().isNotEmpty) {
      CurrencySettings.update(code: code, rates: rates);
    } else if (rates.isNotEmpty) {
      CurrencySettings.update(code: CurrencySettings.code, rates: rates);
    }
  }

  static Future<void> save({String? uid}) async {
    final preferences = await SharedPreferences.getInstance();
    final code = CurrencySettings.code;
    final rates = jsonEncode(CurrencySettings.usdRates);
    await preferences.setString(_lastCodeKey, code);
    await preferences.setString(_ratesKey, rates);
    if (uid != null && uid.isNotEmpty) {
      await preferences.setString(_userCodeKey(uid), code);
    }
  }

  static Future<void> loadForUser(String uid) async {
    if (uid.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString(_userCodeKey(uid));
    if (code != null && code.trim().isNotEmpty) {
      CurrencySettings.update(code: code, rates: CurrencySettings.usdRates);
    }
  }

  static String _userCodeKey(String uid) => 'currency.user.$uid.code';

  static Map<String, double> _readRates(String? raw) {
    if (raw == null || raw.isEmpty) return {'USD': 1};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          entry.key: (entry.value as num).toDouble(),
        'USD': 1,
      };
    } catch (_) {
      return {'USD': 1};
    }
  }
}
