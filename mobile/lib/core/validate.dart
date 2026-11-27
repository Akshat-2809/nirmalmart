/// Input rules — same as the website (frontend/src/lib/validate.js) and the backend
/// (backend/app/schemas/common.py). Letter classes are Unicode, so names can be typed in Marathi too.
abstract final class Validate {
  static final _notNameChars = RegExp(r"[^\p{L}\p{M} .'\-]", unicode: true);
  static final _leadingJunk = RegExp(r"^[\s.'\-]+");
  static final _spaces = RegExp(r'\s{2,}');
  static final _name = RegExp(r"^[\p{L}\p{M}][\p{L}\p{M} .'\-]*$", unicode: true);
  static final _mobile = RegExp(r'^[6-9]\d{9}$');
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _pincode = RegExp(r'^[1-9]\d{5}$');

  /// Keeps only letters (any script), spaces and . ' - ; no leading space; max 60
  static String cleanName(String v) {
    final s = v.replaceAll(_notNameChars, '').replaceFirst(_leadingJunk, '').replaceAll(_spaces, ' ');
    return s.length > 60 ? s.substring(0, 60) : s;
  }

  /// Digits only, max 10; a pasted +91 / 0 prefix is dropped
  static String cleanMobile(String v) {
    var d = v.replaceAll(RegExp(r'\D'), '');
    if (d.length > 10 && d.startsWith('91')) d = d.substring(2);
    if (d.length > 10 && d.startsWith('0')) d = d.substring(1);
    return d.length > 10 ? d.substring(0, 10) : d;
  }

  static final _notCityChars = RegExp(r"[^\p{L}\p{M} .\-]", unicode: true);
  static final _cityLeadingJunk = RegExp(r"^[\s.\-]+");
  static final _city = RegExp(r"^[\p{L}\p{M}][\p{L}\p{M} .\-]*$", unicode: true);

  /// Keeps only letters, spaces, . and - ; max 60
  static String cleanCity(String v) {
    final s = v.replaceAll(_notCityChars, '').replaceFirst(_cityLeadingJunk, '').replaceAll(_spaces, ' ');
    return s.length > 60 ? s.substring(0, 60) : s;
  }

  /// Digits only, max 6
  static String cleanPincode(String v) {
    final d = v.replaceAll(RegExp(r'\D'), '');
    return d.length > 6 ? d.substring(0, 6) : d;
  }

  static bool isCity(String v) => v.trim().length >= 2 && _city.hasMatch(v.trim());

  static bool isName(String v) => v.trim().length >= 2 && _name.hasMatch(v.trim());
  static bool isMobile(String v) => _mobile.hasMatch(v);
  static bool isEmail(String v) => _email.hasMatch(v.trim());
  static bool isPincode(String v) => _pincode.hasMatch(v);

  static const minPassword = 8;

  /// 0–4: length 8+, upper+lower case, a digit, a symbol (same scoring as the website)
  static int passwordStrength(String p) => [
        p.length >= 8,
        RegExp('[A-Z]').hasMatch(p) && RegExp('[a-z]').hasMatch(p),
        RegExp(r'\d').hasMatch(p),
        RegExp(r'[^A-Za-z0-9]').hasMatch(p),
      ].where((ok) => ok).length;
}
