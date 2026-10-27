import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/widgets/book_form.dart';
import 'package:bookshelf/screens/auth_screen.dart';
import 'package:bookshelf/screens/home_screen.dart';
import 'package:bookshelf/models/book.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  testWidgets('Edit failure keeps entered values; Cancel never submits', (
    tester,
  ) async {
    var saves = 0, cancels = 0;
    final book = Book(
      id: 'id',
      userId: 'u',
      title: 'Dune',
      author: 'Frank',
      genre: 'Fiction',
      status: 'Reading',
      createdAt: Timestamp(1, 0),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BookForm(
              initial: book,
              onSave: (_) async {
                saves++;
                throw StateError('duplicate');
              },
              onCancel: () => cancels++,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).first, 'Changed title');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Save'));
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(find.textContaining('duplicate'), findsOneWidget);
    expect(find.text('Changed title'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    expect(cancels, 1);
    expect(saves, 1);
  });
  testWidgets('Phone width 320 has no layout overflow on Home and Register', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('Home has navigation and three feature cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    expect(find.byType(Card), findsNWidgets(3));
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm password'), findsOneWidget);
  });
  testWidgets('Register errors wait for submit and clear after valid input', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AuthScreen(register: true)),
    );
    expect(find.text('Email is required'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pump();
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Confirm password is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'a@example.com');
    await tester.pump();
    expect(find.text('Email is required'), findsNothing);
  });
  testWidgets('Add errors appear under inputs, clearing valid field', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: BookForm(onSave: (_) async {})),
        ),
      ),
    );
    expect(find.text('Title is required'), findsNothing);
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add Book'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add Book'));
    await tester.pump();
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Author is required'), findsOneWidget);
    expect(find.text('Please choose a genre'), findsOneWidget);
    expect(find.text('Please choose a status'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Dune');
    await tester.pump();
    expect(find.text('Title is required'), findsNothing);
  });
}
