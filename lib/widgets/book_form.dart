import 'package:flutter/material.dart';

import '../models/book.dart';
import '../utilities/validation.dart';

class BookForm extends StatefulWidget {
  final Book? initial;
  final Future<void> Function(Map<String, dynamic>) onSave;
  final VoidCallback? onCancel;
  const BookForm({
    super.key,
    this.initial,
    required this.onSave,
    this.onCancel,
  });
  @override
  State<BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<BookForm> {
  final form = GlobalKey<FormState>();
  late final TextEditingController title, author, rating, notes;
  String? genre, status, error;
  bool submitted = false, busy = false;
  @override
  void initState() {
    super.initState();
    final b = widget.initial;
    title = TextEditingController(text: b?.title);
    author = TextEditingController(text: b?.author);
    rating = TextEditingController(text: b?.rating?.toString());
    notes = TextEditingController(text: b?.notes);
    genre = b?.genre;
    status = b?.status;
  }

  @override
  void dispose() {
    for (final c in [title, author, rating, notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      submitted = true;
      error = null;
    });
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      await widget.onSave({
        'title': title.text,
        'author': author.text,
        'genre': genre!,
        'status': status!,
        'rating': rating.text.trim().isEmpty
            ? null
            : int.parse(rating.text.trim()),
        'notes': notes.text,
      });
      if (!mounted) return;
      if (widget.initial == null) {
        setState(() {
          submitted = false;
          genre = null;
          status = null;
        });
        for (final c in [title, author, rating, notes]) {
          c.clear();
        }
        form.currentState!.reset();
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    autovalidateMode: submitted
        ? AutovalidateMode.always
        : AutovalidateMode.disabled,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.initial == null ? 'Add Book' : 'Edit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        input(title, 'Title', Validation.title),
        input(author, 'Author', Validation.author),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
            key: ValueKey('genre-$genre'),
            initialValue: genre,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Genre'),
            hint: const Text('Choose genre'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Choose genre')),
              ...genres.map((g) => DropdownMenuItem(value: g, child: Text(g))),
            ],
            onChanged: busy ? null : (v) => setState(() => genre = v),
            validator: (v) =>
                genres.contains(v) ? null : 'Please choose a genre',
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<String>(
            key: ValueKey('status-$status'),
            initialValue: status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Status'),
            hint: const Text('Choose status'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Choose status')),
              ...statuses.map(
                (s) => DropdownMenuItem(value: s, child: Text(s)),
              ),
            ],
            onChanged: busy ? null : (v) => setState(() => status = v),
            validator: (v) =>
                statuses.contains(v) ? null : 'Please choose a status',
          ),
        ),
        input(rating, 'Rating', Validation.rating, numeric: true),
        input(notes, 'Notes', Validation.notes, lines: 3),
        Wrap(
          spacing: 12,
          children: [
            FilledButton(
              onPressed: busy ? null : submit,
              child: Text(
                busy
                    ? 'Saving…'
                    : widget.initial == null
                    ? 'Add Book'
                    : 'Save',
              ),
            ),
            if (widget.onCancel != null)
              TextButton(
                onPressed: busy ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
  );
  Widget input(
    TextEditingController c,
    String label,
    String? Function(String?) validator, {
    bool numeric = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: TextFormField(
      controller: c,
      enabled: !busy,
      validator: validator,
      decoration: InputDecoration(labelText: label, errorMaxLines: 3),
      maxLines: lines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
    ),
  );
}
