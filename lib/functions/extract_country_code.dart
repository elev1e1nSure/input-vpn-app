/// Best-effort extraction of an ISO-3166 alpha-2 country code from a free-form
/// server remark such as "🇳🇱 NL-AMS-01" or "Netherlands #2".
///
/// Returns a two-letter uppercase code, or `"UN"` (United Nations) as a
/// neutral fallback that still renders as a flag glyph when passed through
/// [countryCodeToEmoji].
String extractCountryCode(String remark) {
  if (remark.isEmpty) return 'UN';

  // 1) Look for an existing flag emoji in the remark.
  final flag = _flagFromEmoji(remark);
  if (flag != null) return flag;

  // 2) Look for a stand-alone 2-letter ISO code (e.g. "NL-AMS", "US 03").
  final isoMatch = RegExp(r'(?:^|[\s\-_\[\(/|.])([A-Z]{2})(?=$|[\s\-_\]\)/|.])')
      .firstMatch(remark.toUpperCase());
  if (isoMatch != null) {
    final code = isoMatch.group(1)!;
    if (_isoAlpha2.contains(code)) return code;
  }

  // 3) Look for a country name keyword.
  final lower = remark.toLowerCase();
  for (final entry in _nameToCode.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }

  return 'UN';
}

/// If [remark] begins with (or contains) a regional-indicator flag emoji,
/// return its ISO alpha-2 code.
String? _flagFromEmoji(String remark) {
  final runes = remark.runes.toList();
  for (var i = 0; i < runes.length - 1; i++) {
    final a = runes[i];
    final b = runes[i + 1];
    const base = 0x1F1E6; // 🇦
    if (a >= base && a <= base + 25 && b >= base && b <= base + 25) {
      final first = String.fromCharCode(a - base + 0x41);
      final second = String.fromCharCode(b - base + 0x41);
      return '$first$second';
    }
  }
  return null;
}

/// Small lookup table — extend as needed. Keys are lowercase substrings.
const _nameToCode = <String, String>{
  'netherlands': 'NL',
  'holland': 'NL',
  'amsterdam': 'NL',
  'germany': 'DE',
  'deutschland': 'DE',
  'frankfurt': 'DE',
  'united states': 'US',
  ' usa': 'US',
  'america': 'US',
  'los angeles': 'US',
  'new york': 'US',
  'united kingdom': 'GB',
  'britain': 'GB',
  'london': 'GB',
  'france': 'FR',
  'paris': 'FR',
  'japan': 'JP',
  'tokyo': 'JP',
  'singapore': 'SG',
  'hong kong': 'HK',
  'hongkong': 'HK',
  'russia': 'RU',
  'moscow': 'RU',
  'turkey': 'TR',
  'istanbul': 'TR',
  'iran': 'IR',
  'tehran': 'IR',
  'canada': 'CA',
  'toronto': 'CA',
  'australia': 'AU',
  'sydney': 'AU',
  'india': 'IN',
  'mumbai': 'IN',
  'sweden': 'SE',
  'stockholm': 'SE',
  'finland': 'FI',
  'helsinki': 'FI',
  'switzerland': 'CH',
  'zurich': 'CH',
  'italy': 'IT',
  'milan': 'IT',
  'spain': 'ES',
  'madrid': 'ES',
  'poland': 'PL',
  'warsaw': 'PL',
  'ukraine': 'UA',
  'kiev': 'UA',
  'kyiv': 'UA',
  'china': 'CN',
  'shanghai': 'CN',
  'beijing': 'CN',
  'taiwan': 'TW',
  'korea': 'KR',
  'seoul': 'KR',
  'brazil': 'BR',
  'sao paulo': 'BR',
};

/// Common ISO alpha-2 codes — used to validate a 2-letter token match so we
/// don't pick up arbitrary upper-case acronyms like "SS" or "VL".
const _isoAlpha2 = <String>{
  'AE', 'AR', 'AT', 'AU', 'AZ', 'BE', 'BG', 'BR', 'BY', 'CA', 'CH', 'CL', 'CN',
  'CO', 'CY', 'CZ', 'DE', 'DK', 'EE', 'EG', 'ES', 'FI', 'FR', 'GB', 'GE', 'GR',
  'HK', 'HR', 'HU', 'ID', 'IE', 'IL', 'IN', 'IR', 'IS', 'IT', 'JP', 'KR', 'KZ',
  'LT', 'LU', 'LV', 'MD', 'MX', 'MY', 'NL', 'NO', 'NZ', 'PH', 'PL', 'PT', 'RO',
  'RS', 'RU', 'SA', 'SE', 'SG', 'SI', 'SK', 'TH', 'TR', 'TW', 'UA', 'UK', 'US',
  'UZ', 'VN', 'ZA',
};
