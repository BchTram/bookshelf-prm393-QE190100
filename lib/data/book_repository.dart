import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/book.dart';

class BookRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  BookRepository(this.db, this.auth);
  String get uid =>
      auth.currentUser?.uid ?? (throw StateError('Please log in'));
  CollectionReference<Map<String, dynamic>> get collection =>
      db.collection('books');
  Stream<List<Book>> watch() => collection
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs.map((d) => Book.fromMap(d.data())).toList());

  Future<String> save(Map<String, dynamic> fields, {Book? original}) async {
    final owner = uid;
    final id = bookId(
      owner,
      fields['title'] as String,
      fields['author'] as String,
    );
    final target = collection.doc(id);
    await db.runTransaction((tx) async {
      final existing = await tx.get(target);
      DocumentSnapshot<Map<String, dynamic>>? source;
      if (original != null) {
        source = original.id == id
            ? existing
            : await tx.get(collection.doc(original.id));
        if (!source.exists || source.data()?['userId'] != owner) {
          throw StateError('Book no longer exists or access was denied');
        }
      }
      if (existing.exists && original?.id != id) {
        throw StateError('This title and author already exist');
      }
      tx.set(target, {
        ...fields,
        'id': id,
        'userId': owner,
        'favorite': source?.data()?['favorite'] ?? false,
        'createdAt': source?.data()?['createdAt'] ?? Timestamp.now(),
      });
      if (original != null && original.id != id) {
        tx.delete(collection.doc(original.id));
      }
    });
    return id;
  }

  Future<void> favorite(Book b) async {
    if (b.userId != uid) throw StateError('Access denied');
    await collection.doc(b.id).update({'favorite': !b.favorite});
  }

  Future<void> delete(Book b) async {
    if (b.userId != uid) throw StateError('Access denied');
    await collection.doc(b.id).delete();
  }
}
