import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/book_repository.dart';
import '../models/book.dart';
import '../widgets/book_form.dart';
import 'list_screen.dart';

class DetailScreen extends StatefulWidget {
  final Book book;
  final BookRepository repository;
  const DetailScreen({super.key, required this.book, required this.repository});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late String id;
  late final Stream<List<Book>> books;
  late final Stream<User?> authState;
  bool editing = false, deleting = false;
  String? error;
  @override
  void initState() {
    super.initState();
    id = widget.book.id;
    books = widget.repository.watch();
    authState = widget.repository.auth.authStateChanges();
  }

  Future<void> remove(Book b) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete'),
        content: Text('Delete “${b.title}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() {
      deleting = true;
      error = null;
    });
    try {
      await widget.repository.delete(b);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: authState,
    builder: (context, auth) {
      if (auth.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (auth.data?.uid != widget.book.userId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: StreamBuilder<List<Book>>(
          stream: books,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final matches = snapshot.data!.where((b) => b.id == id);
            if (matches.isEmpty) {
              return const Center(child: Text('Book no longer exists'));
            }
            final b = matches.first;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (editing)
                      BookForm(
                        initial: b,
                        onCancel: () => setState(() => editing = false),
                        onSave: (fields) async {
                          final next = await widget.repository.save(
                            fields,
                            original: b,
                          );
                          if (mounted) {
                            setState(() {
                              id = next;
                              editing = false;
                            });
                          }
                        },
                      )
                    else ...[
                      Text(
                        b.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      for (final item in [
                        ('Author', b.author),
                        ('Genre', b.genre),
                        ('Status', b.status),
                        ('Rating', b.rating?.toString() ?? ''),
                        ('Notes', b.notes),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text('${item.$1}: ${item.$2}'),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FavoriteButton(
                          book: b,
                          repository: widget.repository,
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton(
                            onPressed: deleting
                                ? null
                                : () => setState(() => editing = true),
                            child: const Text('Edit'),
                          ),
                          OutlinedButton(
                            onPressed: deleting ? null : () => remove(b),
                            child: Text(deleting ? 'Deleting…' : 'Delete'),
                          ),
                        ],
                      ),
                    ],
                    if (error != null)
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}
