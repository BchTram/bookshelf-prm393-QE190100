import 'package:flutter/material.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bookshelf/main.dart' as app;
import 'package:bookshelf/data/firebase_services.dart';
import 'package:bookshelf/data/book_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Real Android production session and submission screenshots', (
    tester,
  ) async {
    const email = String.fromEnvironment('GRADER_EMAIL');
    const password = String.fromEnvironment('GRADER_PASSWORD');
    expect(email, isNotEmpty);
    expect(password, isNotEmpty);
    final captureTitle =
        'QA Capture Book ${DateTime.now().millisecondsSinceEpoch % 100000}';
    final editedTitle = '$captureTitle Edited';
    await app.main();
    await tester.pumpAndSettle();
    final auth = FirebaseServices.auth;
    if (const bool.fromEnvironment('RESTORE_CHECK')) {
      expect(auth.currentUser?.email, email);
      final repository = BookRepository(FirebaseServices.firestore, auth);
      final restored = await repository.watch().first;
      expect(restored.length, greaterThanOrEqualTo(6));
      expect(
        restored.any((book) => book.title == 'Dune' && book.favorite),
        isTrue,
      );
      await tester.pumpAndSettle();
      expect(find.text('List'), findsOneWidget);
      expect(Navigator.of(tester.element(find.text('List'))).canPop(), false);
      return;
    }
    if (auth.currentUser != null) {
      await auth.signOut();
      await tester.pumpAndSettle();
    }
    await tester.pump();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          Uri.parse('http://10.0.2.2:8765/capture?name=$name'),
        );
        final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
        expect(
          response.statusCode,
          200,
          reason: 'Actual Android screenshot capture',
        );
        await response.drain<void>();
      } finally {
        client.close(force: true);
      }
    }

    Future<void> tap(Finder target) async {
      await tester.ensureVisible(target);
      await tester.tap(target);
      await tester.pumpAndSettle();
    }

    Future<void> waitFor(Finder target) async {
      final deadline = DateTime.now().add(const Duration(seconds: 40));
      while (target.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(
        target,
        findsWidgets,
        reason: 'Waiting for asynchronous Firebase/UI result',
      );
      await tester.pumpAndSettle();
    }

    Future<void> reveal(Finder target, {double delta = 300}) async {
      await tester.scrollUntilVisible(
        target,
        delta,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
    }

    Future<void> clear() async {
      await reveal(find.text('Clear'), delta: -400);
      await tap(find.text('Clear'));
    }

    Future<void> dropdown(
      int index,
      String choice, {
      bool filter = false,
    }) async {
      final label = index == 0 ? 'Genre filter' : 'Status filter';
      final target = filter
          ? find.byWidgetPredicate(
              (w) =>
                  w is DropdownButtonFormField<String> &&
                  w.key is ValueKey<String> &&
                  (w.key! as ValueKey<String>).value.startsWith('$label-'),
            )
          : find.byType(DropdownButtonFormField<String>).at(index);
      if (filter) await reveal(target, delta: -300);
      await tap(target);
      await tap(find.text(choice).last);
    }

    await capture('00_home');
    await tap(find.text('Register'));
    await tap(find.widgetWithText(FilledButton, 'Register'));
    expect(find.text('Email is required'), findsOneWidget);
    await capture('04_register_validation');
    final registrationEmail =
        'register.qe190100.${DateTime.now().millisecondsSinceEpoch}@example.com';
    await tester.enterText(find.byType(TextFormField).at(0), registrationEmail);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.enterText(find.byType(TextFormField).at(2), password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tap(find.widgetWithText(FilledButton, 'Register'));
    await waitFor(find.text('Registration successful'));
    expect(find.text('Registration successful'), findsOneWidget);
    await capture('05_register_success');
    await capture('22_empty_fresh_account');
    await auth.signOut();
    await tester.pumpAndSettle();
    await tap(find.text('Login'));
    await capture('06_login_empty');
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tap(find.widgetWithText(FilledButton, 'Login'));
    await waitFor(find.text('List'));
    expect(find.text('List'), findsOneWidget);
    expect(Navigator.of(tester.element(find.text('List'))).canPop(), false);
    await reveal(find.text('Atomic Habits'));
    await capture('07_list_after_login');
    await reveal(find.text('Summary'), delta: -300);
    await capture('14_summary');
    await reveal(find.byType(ExpansionTile), delta: -500);
    await tap(find.byType(ExpansionTile));
    await reveal(find.widgetWithText(FilledButton, 'Add Book'));
    await tap(find.widgetWithText(FilledButton, 'Add Book'));
    await reveal(find.byType(TextFormField).first, delta: -300);
    await capture('08_add_validation');
    await tester.enterText(find.byType(TextFormField).at(0), captureTitle);
    await tester.enterText(find.byType(TextFormField).at(1), 'QE190100');
    await dropdown(0, 'Fiction');
    await dropdown(1, 'Reading');
    await tester.enterText(find.byType(TextFormField).at(2), '4');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'Created in the real Android app.',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await reveal(find.widgetWithText(FilledButton, 'Add Book'));
    await tap(find.widgetWithText(FilledButton, 'Add Book'));
    await waitFor(find.text('Book added'));
    await reveal(find.text(captureTitle));
    expect(find.text('Book added'), findsOneWidget);
    await capture('09_add_success');
    await clear();
    await dropdown(0, 'Fiction', filter: true);
    await reveal(find.text('Genre filter'), delta: -300);
    await capture('10_filter_genre');
    await clear();
    await dropdown(1, 'Reading', filter: true);
    await reveal(find.text('Genre filter'), delta: -300);
    await capture('11_filter_status');
    await clear();
    await reveal(find.text('Favorites only'), delta: -300);
    await tap(find.text('Favorites only'));
    await reveal(find.text('Genre filter'), delta: -300);
    await capture('12_filter_favorites');
    await clear();
    final search = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == 'Search',
    );
    await tester.enterText(search, '  QE190100  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await reveal(find.text(captureTitle));
    await capture('13_search');
    await tester.enterText(search, captureTitle);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tap(find.text(captureTitle));
    await capture('15_detail_view');
    await tap(find.text('Edit'));
    await tester.enterText(find.byType(TextFormField).first, '');
    await reveal(find.widgetWithText(FilledButton, 'Save'));
    await tap(find.widgetWithText(FilledButton, 'Save'));
    await reveal(find.byType(TextFormField).first, delta: -300);
    await capture('16_detail_edit_validation');
    await tester.enterText(find.byType(TextFormField).at(0), editedTitle);
    await tester.enterText(find.byType(TextFormField).at(2), '5');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'Saved from Android after validation.',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await reveal(find.widgetWithText(FilledButton, 'Save'));
    await tap(find.widgetWithText(FilledButton, 'Save'));
    await waitFor(find.text(editedTitle));
    expect(find.text(editedTitle), findsOneWidget);
    await capture('17_detail_after_save');
    await capture('18_favorite_before');
    await tap(find.byTooltip('Add favorite'));
    await waitFor(find.byTooltip('Remove favorite'));
    await capture('19_favorite_after');
    await tap(find.widgetWithText(OutlinedButton, 'Delete'));
    await capture('20_delete_confirmation');
    await tap(find.widgetWithText(FilledButton, 'Delete'));
    await waitFor(find.text('List'));
    await waitFor(find.byType(Scrollable));
    await reveal(search, delta: -400);
    await tester.enterText(search, editedTitle);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await reveal(find.text('No books found'));
    expect(find.text('No books found'), findsOneWidget);
    await capture('21_delete_after');
    expect(find.text(editedTitle), findsNothing);
    await clear();
    await reveal(find.text('Summary'));
    await capture('23_final_summary');
    final repository = BookRepository(FirebaseServices.firestore, auth);
    final saved = await repository.watch().first;
    expect(saved.any((book) => book.title == editedTitle), isFalse);
    await tap(find.text('Logout'));
    await waitFor(find.text('Track your books'));
    await auth.signInWithEmailAndPassword(
      email: registrationEmail,
      password: password,
    );
    expect(await repository.watch().first, isEmpty);
    await auth.signOut();
    await auth.signInWithEmailAndPassword(email: email, password: password);
    final restored = await repository.watch().first;
    expect(restored.length, saved.length);
    expect(restored.any((book) => book.title == editedTitle), isFalse);
    await waitFor(find.text('List'));
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
