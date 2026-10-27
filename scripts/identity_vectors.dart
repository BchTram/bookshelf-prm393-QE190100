import 'dart:convert';
import 'dart:io';

import 'package:bookshelf/utilities/book_identity.dart';

void main() {
  final titles = [
    'A|B',
    'A/B',
    '%2f|100%',
    'ĐƯỜNG VỀ 📚',
    'ÉCOLE',
    'İSTANBUL',
    'ΟΣ',
    'ẞ',
    'Σ',
    '𐐀',
    ' A ',
    'line\nbreak',
  ];
  final vectors = [
    for (final title in titles)
      {
        'title': title,
        'author': 'TÁC GIẢ / % | Author',
        'id': bookId('UserA', title, 'TÁC GIẢ / % | Author'),
      },
  ];
  File('rules_test/dart_identity_vectors.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(vectors));
}
