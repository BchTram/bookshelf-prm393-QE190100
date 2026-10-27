import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/book_repository.dart';
import '../models/book.dart';
import '../widgets/book_form.dart';
import 'detail_screen.dart';

class ListScreen extends StatefulWidget {
  final User user;
  final BookRepository repository;
  const ListScreen({super.key, required this.user, required this.repository});
  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final search = TextEditingController();
  final addController = ExpansibleController();
  String genre = 'All', status = 'All';
  bool favorites = false, loggingOut = false;
  late final Stream<List<Book>> books;
  @override
  void initState() {
    super.initState();
    books = widget.repository.watch();
  }

  @override
  void dispose() {
    search.dispose();
    addController.dispose();
    super.dispose();
  }

  void message(Object e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), duration: const Duration(seconds: 10)),
      );
    }
  }

  Future<void> logout() async {
    setState(() => loggingOut = true);
    try {
      await widget.repository.auth.signOut();
    } catch (e) {
      message(e);
    } finally {
      if (mounted) setState(() => loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('List'),
          Text(
            widget.user.email ?? '',
            maxLines: 2,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loggingOut ? null : logout,
          child: const Text('Logout'),
        ),
      ],
    ),
    body: StreamBuilder<List<Book>>(
      stream: books,
      builder: (context, snapshot) {
        final shown = visibleBooks(
          snapshot.data ?? [],
          genre: genre,
          status: status,
          favoritesOnly: favorites,
          search: search.text,
        );
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ExpansionTile(
                    controller: addController,
                    title: const Text('Add Book'),
                    maintainState: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: BookForm(
                          onSave: (fields) async {
                            await widget.repository.save(fields);
                            if (!mounted) return;
                            addController.collapse();
                            message('Book added');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Filters and search',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                filter(
                  'Genre filter',
                  genre,
                  genres,
                  (v) => setState(() => genre = v),
                ),
                filter(
                  'Status filter',
                  status,
                  statuses,
                  (v) => setState(() => status = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Favorites only'),
                  value: favorites,
                  onChanged: (v) => setState(() => favorites = v),
                ),
                TextField(
                  controller: search,
                  decoration: const InputDecoration(
                    labelText: 'Search',
                    hintText: 'Title or author',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      genre = status = 'All';
                      favorites = false;
                      search.clear();
                    }),
                    child: const Text('Clear'),
                  ),
                ),
                if (snapshot.hasError)
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else if (!snapshot.hasData)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text('Books: ${shown.length}'),
                          Text(
                            'Favorites: ${shown.where((b) => b.favorite).length}',
                          ),
                          for (final entry in statusSummary(shown))
                            Text('${entry.key}: ${entry.value}'),
                        ],
                      ),
                    ),
                  ),
                  if (shown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('No books found')),
                    ),
                  for (final b in shown)
                    Card(
                      child: ListTile(
                        title: Text(b.title),
                        subtitle: Text('${b.author}\n${b.genre} • ${b.status}'),
                        isThreeLine: true,
                        trailing: FavoriteButton(
                          key: ValueKey(b.id),
                          book: b,
                          repository: widget.repository,
                        ),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DetailScreen(
                              book: b,
                              repository: widget.repository,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
  Widget filter(
    String label,
    String current,
    List<String> values,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$current'),
      initialValue: current,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        'All',
        ...values,
      ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: (v) {
        if (v != null) change(v);
      },
    ),
  );
}

class FavoriteButton extends StatefulWidget {
  final Book book;
  final BookRepository repository;
  const FavoriteButton({
    super.key,
    required this.book,
    required this.repository,
  });
  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool busy = false;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: widget.book.favorite ? 'Remove favorite' : 'Add favorite',
    icon: Icon(
      widget.book.favorite ? Icons.star : Icons.star_border,
      color: widget.book.favorite ? Colors.amber.shade800 : null,
    ),
    onPressed: busy
        ? null
        : () async {
            setState(() => busy = true);
            try {
              await widget.repository.favorite(widget.book);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('$e')));
              }
            } finally {
              if (mounted) setState(() => busy = false);
            }
          },
  );
}
