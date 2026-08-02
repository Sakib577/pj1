class CurrencySettings {
  CurrencySettings._();

  static String _code = 'USD';
  static Map<String, double> _usdRates = {'USD': 1};

  static String get code => _code;
  static Map<String, double> get usdRates => Map.unmodifiable(_usdRates);
  static double get rate => _usdRates[_code] ?? 1;

  static void update({
    required String code,
    required Map<String, double> rates,
  }) {
    // Keep the requested code even if `rates` does not contain it yet (e.g. the
    // stored currency is loaded on login before the live FX rates arrive). The
    // rate defaults to 1 so amounts still render, and gets replaced when the
    // real rates are fetched. This is what makes the user's currency survive a
    // sign-out / sign-in.
    final normalized = code.trim().toUpperCase();
    _code = normalized.isEmpty ? 'USD' : normalized;
    _usdRates = Map.unmodifiable({...rates, _code: rates[_code] ?? 1});
  }

  static double fromUsd(double usdAmount) => usdAmount * rate;
  static double toUsd(double displayedAmount) => displayedAmount / rate;

  static String get symbol =>
      const {
        'USD': r'$',
        'EUR': '€',
        'GBP': '£',
        'BDT': '৳',
        'INR': '₹',
        'JPY': '¥',
        'CNY': '¥',
        'KRW': '₩',
        'CAD': r'CA$',
        'AUD': r'A$',
        'NZD': r'NZ$',
        'CHF': 'CHF',
        'AED': 'د.إ',
        'SAR': '﷼',
        'PKR': '₨',
        'THB': '฿',
        'TRY': '₺',
        'RUB': '₽',
        'BRL': r'R$',
        'MXN': r'MX$',
        'ZAR': 'R',
        'NGN': '₦',
        'IDR': 'Rp',
        'MYR': 'RM',
        'PHP': '₱',
        'VND': '₫',
        'EGP': 'E£',
        'SEK': 'kr',
        'NOK': 'kr',
        'DKK': 'kr',
        'PLN': 'zł',
        'UAH': '₴',
      }[_code] ??
      '$_code ';
}
