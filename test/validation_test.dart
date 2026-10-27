import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/utilities/validation.dart';

void main() {
  test('Exact auth validation and boundaries', () {
    expect(Validation.email(' '), 'Email is required');
    expect(Validation.email('abc@'), 'Please enter a valid email address');
    expect(Validation.email(' a+b@example.com '), null);
    expect(Validation.password(''), 'Password is required');
    expect(
      Validation.password('12345', register: true),
      'Password must be at least 6 characters',
    );
    expect(Validation.password('123456', register: true), null);
    expect(Validation.password('a'), null);
    expect(Validation.confirm('', 'abc'), 'Confirm password is required');
    expect(Validation.confirm('x', 'abc'), 'Passwords do not match');
    expect(Validation.confirm('abc', 'abc'), null);
  });
  test('Book validation exact messages including optional values', () {
    expect(Validation.title(' \t'), 'Title is required');
    expect(Validation.title('a' * 101), 'Title must be at most 100 characters');
    expect(Validation.title('a' * 100), null);
    expect(Validation.author(''), 'Author is required');
    expect(Validation.author('a' * 61), 'Author must be at most 60 characters');
    expect(Validation.author('a' * 60), null);
    for (final s in ['', '0', '5']) {
      expect(Validation.rating(s), null);
    }
    for (final s in ['-1', '6', '1.0', 'x', '1e0', '+1']) {
      expect(Validation.rating(s), 'Rating must be a whole number from 0 to 5');
    }
    expect(Validation.notes('a' * 300), null);
    expect(Validation.notes('a' * 301), 'Notes must be at most 300 characters');
  });
}
