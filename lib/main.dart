import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'data/book_repository.dart';
import 'data/firebase_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? error;
  try {
    const host = String.fromEnvironment('EMULATOR_HOST');
    if (host.isNotEmpty) {
      FirebaseServices.app = await Firebase.initializeApp(
        name: 'demo-bookshelf',
        demoProjectId: 'demo-bookshelf',
      );
      await FirebaseServices.auth.useAuthEmulator(host, 9099);
      FirebaseServices.firestore.useFirestoreEmulator(host, 8080);
      FirebaseServices.firestore.settings = const Settings(
        persistenceEnabled: false,
      );
    } else {
      FirebaseServices.app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    error = e.toString();
  }
  runApp(BookShelfApp(initializationError: error));
}

class BookShelfApp extends StatelessWidget {
  final String? initializationError;
  const BookShelfApp({super.key, this.initializationError});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BookShelf',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff315e50)),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 6)),
    ),
    home: initializationError != null
        ? Scaffold(
            appBar: AppBar(title: const Text('BookShelf')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'Firebase setup required\n\n$initializationError\n\nSee README.md to configure your Firebase project.',
              ),
            ),
          )
        : const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: FirebaseServices.auth.authStateChanges(),
    builder: (context, state) {
      if (state.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (state.hasError) {
        return Scaffold(body: Center(child: Text('${state.error}')));
      }
      final user = state.data;
      return user == null
          ? const HomeScreen()
          : ListScreen(
              key: ValueKey(user.uid),
              user: user,
              repository: BookRepository(
                FirebaseServices.firestore,
                FirebaseServices.auth,
              ),
            );
    },
  );
}
