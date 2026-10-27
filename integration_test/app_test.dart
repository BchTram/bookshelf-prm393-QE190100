import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bookshelf/main.dart' as app;
import 'package:bookshelf/data/book_repository.dart';
import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/data/firebase_services.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android emulator: auth, private CRUD, duplicate and atomic rename',
    (tester) async {
      const host = String.fromEnvironment('EMULATOR_HOST');
      expect(
        host,
        isNotEmpty,
        reason: 'Run only against local Firebase emulators',
      );
      await app.main();
      await tester.pumpAndSettle();
      final auth = FirebaseServices.auth;
      if (auth.currentUser != null) {
        await auth.signOut();
        await tester.pumpAndSettle();
      }
      expect(find.text('Track your books'), findsOneWidget);
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();
      expect(find.text('Email is required'), findsOneWidget);
      final email =
          'android-${DateTime.now().microsecondsSinceEpoch}@example.test';
      final password = List.generate(
        24,
        (_) => String.fromCharCode(65 + Random.secure().nextInt(26)),
      ).join();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), email);
      await tester.enterText(fields.at(1), password);
      await tester.enterText(fields.at(2), password);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      for (var i = 0; i < 30 && auth.currentUser == null; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
      expect(find.text('List'), findsOneWidget);
      expect(find.text('Registration successful'), findsOneWidget);
      expect(find.text(email), findsOneWidget);
      final repo = BookRepository(FirebaseServices.firestore, auth);
      final uid = auth.currentUser!.uid;
      final data = <String, dynamic>{
        'title': 'Dune',
        'author': 'Frank Herbert',
        'genre': 'Fiction',
        'status': 'To Read',
        'rating': null,
        'notes': '',
      };
      final first = await repo.save(data);
      await expectLater(
        repo.save({...data, 'title': 'dUNE'}),
        throwsStateError,
      );
      var b = Book.fromMap((await repo.collection.doc(first).get()).data()!);
      await repo.favorite(b);
      b = Book.fromMap((await repo.collection.doc(first).get()).data()!);
      expect(b.favorite, true);
      final renamed = await repo.save({
        ...data,
        'title': 'Dune Messiah',
        'rating': 5,
        'notes': 'Updated on Android',
      }, original: b);
      expect((await repo.collection.doc(first).get()).exists, false);
      final saved = Book.fromMap(
        (await repo.collection.doc(renamed).get()).data()!,
      );
      expect(saved.createdAt, b.createdAt);
      expect(saved.favorite, true);
      expect(saved.rating, 5);
      // Clear public form navigation: Android Back has no auth route underneath List.
      expect(Navigator.of(tester.element(find.text('List'))).canPop(), false);
      await auth.signOut();
      await tester.pumpAndSettle();
      expect(find.text('Track your books'), findsOneWidget);
      final second = await auth.createUserWithEmailAndPassword(
        email: 'second-$email',
        password: password,
      );
      expect(second.user!.uid, isNot(uid));
      expect(await repo.watch().first, isEmpty);
      await auth.signOut();
      await auth.signInWithEmailAndPassword(email: email, password: password);
      expect((await repo.watch().first).single.id, renamed);
      await repo.delete(saved);
      expect(await repo.watch().first, isEmpty);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
