import 'dart:math' as math;

import 'models.dart';

/// Search helpers that run on the phone, on top of the server's search (which only finds exact
/// pieces of text):
/// - [bestMatchRank] puts products whose *name* matches ahead of ones that only mention the word
/// - [smartMatch] finds products when the server finds none: Marathi typed in English letters
///   ("batli" → बाटली), other forms of a Marathi word ("डबा" → डब्यासह), and spelling mistakes
///   ("torh" → torch)
abstract final class SmartSearch {
  static final _devanagari = RegExp(r'[ऀ-ॿ]');
  static final _splitter = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

  static bool isDevanagari(String s) => _devanagari.hasMatch(s);

  static List<String> words(String s) => s.toLowerCase().split(_splitter).where((w) => w.isNotEmpty).toList();

  /// 0 = a name starts with it, 1 = a word in a name starts with it, 2 = a name contains it,
  /// 3 = only the description or tags match (the server found it there)
  static int bestMatchRank(Product p, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 3;
    final names = [p.name.toLowerCase(), if (p.nameMr != null) p.nameMr!];
    if (names.any((n) => n.startsWith(q))) return 0;
    if (names.any((n) => words(n).any((w) => w.startsWith(q)))) return 1;
    if (names.any((n) => n.contains(q))) return 2;
    return 3;
  }

  /// Server results with the best name matches first; ties keep the server's order
  static List<Product> rank(List<Product> items, String query) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, bestMatchRank(items[i], query), items[i])];
    indexed.sort((a, b) => a.$2 != b.$2 ? a.$2.compareTo(b.$2) : a.$1.compareTo(b.$1));
    return [for (final x in indexed) x.$3];
  }

  // ───────────── Marathi → rough English letters ─────────────

  static const _consonants = {
    'क': 'k', 'ख': 'kh', 'ग': 'g', 'घ': 'gh', 'ङ': 'n', 'च': 'ch', 'छ': 'chh', 'ज': 'j', 'झ': 'jh', 'ञ': 'n',
    'ट': 't', 'ठ': 'th', 'ड': 'd', 'ढ': 'dh', 'ण': 'n', 'त': 't', 'थ': 'th', 'द': 'd', 'ध': 'dh', 'न': 'n',
    'प': 'p', 'फ': 'ph', 'ब': 'b', 'भ': 'bh', 'म': 'm', 'य': 'y', 'र': 'r', 'ल': 'l', 'ळ': 'l', 'व': 'v',
    'श': 'sh', 'ष': 'sh', 'स': 's', 'ह': 'h',
  };
  static const _vowels = {
    'अ': 'a', 'आ': 'a', 'इ': 'i', 'ई': 'i', 'उ': 'u', 'ऊ': 'u', 'ए': 'e', 'ऐ': 'ai', 'ओ': 'o', 'औ': 'au',
    'ऋ': 'ru', 'ऍ': 'e', 'ऑ': 'o',
  };
  static const _signs = {
    'ा': 'a', 'ि': 'i', 'ी': 'i', 'ु': 'u', 'ू': 'u', 'े': 'e', 'ै': 'ai', 'ो': 'o', 'ौ': 'au', 'ृ': 'ru',
    'ॅ': 'e', 'ॉ': 'o',
  };
  static const _virama = '्';

  /// "बाटली" → "batali" (each consonant keeps its built-in "a" unless it ends the word)
  static String transliterate(String s) {
    final out = StringBuffer();
    final chars = s.split('');
    for (var i = 0; i < chars.length; i++) {
      final c = chars[i];
      final next = i + 1 < chars.length ? chars[i + 1] : '';
      if (_consonants.containsKey(c)) {
        out.write(_consonants[c]);
        final ends = next.isEmpty || !_devanagari.hasMatch(next);
        if (!_signs.containsKey(next) && next != _virama && next != '़' && !ends) out.write('a');
      } else if (_vowels.containsKey(c)) {
        out.write(_vowels[c]);
      } else if (_signs.containsKey(c)) {
        out.write(_signs[c]);
      } else if (c == 'ं' || c == 'ँ') {
        out.write('n');
      } else if (c == 'ः') {
        out.write('h');
      } else if (c == _virama || c == '़') {
        // joins letters / marks a sound: nothing to write
      } else if (RegExp(r'[०-९]').hasMatch(c)) {
        out.write('०१२३४५६७८९'.indexOf(c));
      } else {
        out.write(c.toLowerCase());
      }
    }
    return out.toString();
  }

  /// A spelling-proof key: "batli", "baatli" and बाटली all become "btli"; "torch" and टॉर्च "torc"
  static String key(String word) {
    var s = (isDevanagari(word) ? transliterate(word) : word).toLowerCase();
    s = s
        .replaceAll('chh', 'c')
        .replaceAll('ch', 'c')
        .replaceAll('sh', 's')
        .replaceAll('ph', 'f')
        .replaceAll(RegExp('([kgjtdb])h'), r'$1')
        .replaceAll('w', 'v')
        .replaceAll('z', 'j')
        .replaceAll('q', 'k')
        .replaceAll('x', 'ks')
        .replaceAll('ee', 'i')
        .replaceAll('oo', 'u')
        .replaceAll('a', '') // the softest vowel, often skipped or added when typing Marathi in English letters
        .replaceAll('y', 'i');
    // double letters count once ("bottle" ~ "botle")
    return s.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
  }

  /// Spelling slips between two words; a swapped pair of letters counts as one ("bottel" ~ "bottle")
  static int distance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    final d = List.generate(a.length + 1, (i) => List<int>.filled(b.length + 1, 0));
    for (var i = 0; i <= a.length; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      d[0][j] = j;
    }
    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        var v = math.min(math.min(d[i - 1][j] + 1, d[i][j - 1] + 1), d[i - 1][j - 1] + cost);
        if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) v = math.min(v, d[i - 2][j - 2] + 1);
        d[i][j] = v;
      }
    }
    return d[a.length][b.length];
  }

  static final _trailingSign = RegExp(r'[\u093E-\u094C\u0962\u0963]$');

  /// How close query word [q] is to name word [w]: 0 = same or the start of it, 1–2 = spelling slips, null = no
  static int? _closeness(String q, String w, {required bool devanagariQuery}) {
    if (devanagariQuery) {
      if (!isDevanagari(w)) return null;
      // other forms of the same word share its start once the last vowel sign is dropped: डबा ~ डब्यासह
      final stem = q.replaceFirst(_trailingSign, '');
      if (w.startsWith(q) || (stem.length >= 2 && w.startsWith(stem))) return 0;
      final qk = key(q), wk = key(w);
      return qk.length >= 4 && distance(qk, wk) <= 1 ? 1 : null;
    }
    final qk = key(q), wk = key(w);
    if (qk.isEmpty || wk.isEmpty) return null;
    if (wk == qk || (qk.length >= 3 && wk.startsWith(qk))) return 0;
    final allowed = qk.length >= 6 ? 2 : qk.length >= 3 ? 1 : 0;
    final dist = distance(qk, wk);
    return dist <= allowed ? dist : null;
  }

  /// What to show when the server finds nothing:
  /// - products + [marathiWord]: Marathi typed in English letters ("batli" → बाटली)
  /// - products + similar: other forms of a Marathi word, or near-identical spellings
  /// - only [didYouMean]: a spelling slip in English ("torh" → torch), offered rather than guessed
  static ({List<Product> products, String? marathiWord, String? didYouMean, bool similar}) smartMatch(String query, List<Product> all) {
    const none = (products: <Product>[], marathiWord: null, didYouMean: null, similar: false);
    final qWords = words(query).where((w) => w.length >= 2).toList();
    if (qWords.isEmpty || all.isEmpty) return none;
    final devanagariQuery = isDevanagari(query);

    final hits = <(int, Product)>[];
    // the closest single name word over all products, for the message
    (int, String)? bestWord;
    for (final p in all) {
      var score = 0;
      var ok = true;
      for (final q in qWords) {
        int? best;
        for (final w in [...words(p.name), ...words(p.nameMr ?? '')]) {
          final c = _closeness(q, w, devanagariQuery: devanagariQuery);
          if (c == null) continue;
          if (best == null || c < best) best = c;
          // on a tie an English word wins, so "torh" offers "torch" rather than guessing टॉर्च
          if (bestWord == null || c < bestWord.$1 || (c == bestWord.$1 && isDevanagari(bestWord.$2) && !isDevanagari(w))) {
            bestWord = (c, w);
          }
        }
        if (best == null) {
          ok = false;
          break;
        }
        score += best;
      }
      if (ok) hits.add((score, p));
    }
    if (hits.isEmpty || bestWord == null) return none;
    hits.sort((a, b) => a.$1.compareTo(b.$1));
    // only the closest ones (a looser match would be noise)
    final products = [for (final h in hits) if (h.$1 == hits.first.$1) h.$2];
    final word = bestWord.$2;
    if (devanagariQuery) return (products: products, marathiWord: null, didYouMean: null, similar: true);
    if (isDevanagari(word)) return (products: products, marathiWord: word, didYouMean: null, similar: false);
    if (bestWord.$1 > 0) return (products: const [], marathiWord: null, didYouMean: word, similar: false);
    return (products: products, marathiWord: null, didYouMean: null, similar: true);
  }
}
