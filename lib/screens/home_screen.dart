import 'package:flutter/material.dart';

import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('BookShelf'),
      actions: [
        TextButton(
          onPressed: () => open(context, false),
          child: const Text('Login'),
        ),
        TextButton(
          onPressed: () => open(context, true),
          child: const Text('Register'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('BookShelf', style: Theme.of(context).textTheme.headlineLarge),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Your private library. Keep the books you own and discover what to read next.',
          ),
        ),
        for (final feature in [
          (
            Icons.menu_book,
            'Track your books',
            'Keep titles, authors and notes together.',
          ),
          (
            Icons.auto_stories,
            'Sort by status',
            'Follow your progress from To Read to Finished.',
          ),
          (
            Icons.star,
            'Rate your favorites',
            'Save favorites and rate your next great read.',
          ),
        ])
          Card(
            child: ListTile(
              leading: Icon(feature.$1),
              title: Text(feature.$2),
              subtitle: Text(feature.$3),
            ),
          ),
      ],
    ),
  );
  void open(BuildContext context, bool register) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AuthScreen(register: register)),
  );
}
