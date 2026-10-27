import 'unicode_fold.dart';

// Backslash is escaped so Rules can safely quote a literal RE2 pattern.
String escapeIdentity(String value) => value
    .replaceAll('%', '%25')
    .replaceAll('\\', '%5c')
    .replaceAll('/', '%2f')
    .replaceAll('|', '%7c');
String identityPart(String value) => escapeIdentity(
  String.fromCharCodes(value.runes.map((r) => unicodeSimpleFold[r] ?? r)),
);
String bookId(String uid, String title, String author) =>
    '${escapeIdentity(uid)}|${identityPart(title)}|${identityPart(author)}';
