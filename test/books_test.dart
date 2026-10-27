import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookshelf/models/book.dart';

Book sample(
  String title,
  String author,
  String status, {
  String genre = 'Fiction',
  bool favorite = false,
}) => Book(
  id: bookId('A', title, author),
  userId: 'A',
  title: title,
  author: author,
  genre: genre,
  status: status,
  favorite: favorite,
  createdAt: Timestamp(1, 0),
);
void main() {
  final books = [
    sample('dune', 'Z', 'To Read', favorite: true),
    sample('Dune', 'A', 'Finished'),
    sample('Alpha', 'B', 'Reading', genre: 'Other'),
    sample('Beta', 'C', 'To Read', favorite: true),
    sample('Echo', 'D', 'Reading'),
  ];
  test('Sort ignores case, equal titles compare author', () {
    expect(visibleBooks(books).map((b) => '${b.title}/${b.author}'), [
      'Alpha/B',
      'Beta/C',
      'Dune/A',
      'dune/Z',
      'Echo/D',
    ]);
  });
  test('All filters combine and search trims whitespace', () {
    final shown = visibleBooks(
      books,
      genre: 'Fiction',
      status: 'To Read',
      favoritesOnly: true,
      search: ' DUN ',
    );
    expect(shown.length, 1);
    expect(shown.first.author, 'Z');
    expect(visibleBooks(books, search: ' b ').first.title, 'Alpha');
    expect(visibleBooks(books, genre: 'Academic'), isEmpty);
    expect(visibleBooks(books).length, 5);
  });
  test('Summary sorts counts descending, status priority on tie', () {
    expect(statusSummary(books).map((e) => '${e.key}:${e.value}'), [
      'To Read:2',
      'Reading:2',
      'Finished:1',
    ]);
    expect(statusSummary([]), isEmpty);
    final filtered = visibleBooks(books, favoritesOnly: true);
    expect(statusSummary(filtered).single.value, 2);
  });
  test('Identity is case insensitive and escape is injective', () {
    expect(bookId('UserA', 'DUNE', 'FRANK'), bookId('UserA', 'dune', 'frank'));
    expect(bookId('UserA', 'a|b', 'c'), isNot(bookId('UserA', 'a', 'b|c')));
    expect(bookId('UserA', 'a/b', '%2f'), isNot(bookId('UserA', 'a%2fb', '/')));
    expect(bookId('A', 'Dune', 'Frank'), isNot(bookId('a', 'Dune', 'Frank')));
    expect(identityPart('ĐƯỜNG / % | 📚'), 'đường %2f %25 %7c 📚');
  });
}
