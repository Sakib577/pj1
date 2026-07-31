import 'dart:convert';

import 'package:http/http.dart' as http;

class ExchangeRateSnapshot {
  const ExchangeRateSnapshot({required this.rates, required this.updatedAt});

  final Map<String, double> rates;
  final DateTime updatedAt;
}

class ExchangeRateService {
  static const _endpoint = 'https://open.er-api.com/v6/latest/USD';

  Future<ExchangeRateSnapshot> fetchLatestUsdRates() async {
    final response = await http.get(Uri.parse(_endpoint));
    if (response.statusCode != 200) {
      throw Exception(
        'Could not load exchange rates (${response.statusCode}).',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['result'] != 'success') {
      throw Exception('The exchange-rate service returned an error.');
    }
    final rawRates = body['rates'] as Map<String, dynamic>;
    final rates = <String, double>{
      for (final entry in rawRates.entries)
        entry.key: (entry.value as num).toDouble(),
    };
    rates['USD'] = 1;
    final updatedSeconds = body['time_last_update_unix'] as int?;
    return ExchangeRateSnapshot(
      rates: rates,
      updatedAt: updatedSeconds == null
          ? DateTime.now().toUtc()
          : DateTime.fromMillisecondsSinceEpoch(
              updatedSeconds * 1000,
              isUtc: true,
            ),
    );
  }
}
