import 'package:cloud_firestore/cloud_firestore.dart';

export '../utilities/book_identity.dart';

const genres = ['Fiction', 'Non-Fiction', 'Academic', 'Other'];
const statuses = ['To Read', 'Reading', 'Finished'];

class Book {
  final String id, userId, title, author, genre, status, notes;
  final int? rating;
  final bool favorite;
  final Timestamp createdAt;
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    this.rating,
    this.notes = '',
    this.favorite = false,
    required this.createdAt,
  });

  factory Book.fromMap(Map<String, dynamic> d) => Book(
    id: d['id'] as String,
    userId: d['userId'] as String,
    title: d['title'] as String,
    author: d['author'] as String,
    genre: d['genre'] as String,
    status: d['status'] as String,
    rating: d['rating'] as int?,
    notes: d['notes'] as String? ?? '',
    favorite: d['favorite'] as bool,
    createdAt: d['createdAt'] as Timestamp,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'author': author,
    'genre': genre,
    'status': status,
    'rating': rating,
    'favorite': favorite,
    'notes': notes,
    'createdAt': createdAt,
  };
}

List<Book> visibleBooks(
  List<Book> books, {
  String genre = 'All',
  String status = 'All',
  bool favoritesOnly = false,
  String search = '',
}) {
  final q = search.trim().toLowerCase();
  final result = books
      .where(
        (b) =>
            (genre == 'All' || b.genre == genre) &&
            (status == 'All' || b.status == status) &&
            (!favoritesOnly || b.favorite) &&
            (b.title.toLowerCase().contains(q) ||
                b.author.toLowerCase().contains(q)),
      )
      .toList();
  result.sort((a, b) {
    final c = a.title.toLowerCase().compareTo(b.title.toLowerCase());
    return c != 0
        ? c
        : a.author.toLowerCase().compareTo(b.author.toLowerCase());
  });
  return result;
}

List<MapEntry<String, int>> statusSummary(List<Book> books) {
  final counts = <String, int>{};
  for (final b in books) {
    counts.update(b.status, (n) => n + 1, ifAbsent: () => 1);
  }
  return counts.entries.toList()..sort((a, b) {
    final c = b.value.compareTo(a.value);
    return c != 0
        ? c
        : statuses.indexOf(a.key).compareTo(statuses.indexOf(b.key));
  });
}
