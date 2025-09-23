// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:driveguard_app/core/utils/validators.dart';

void main() {
  group('Validators Test', () {
    test('Email validator should work correctly', () {
      // Valid emails
      expect(Validators.email('test@example.com'), isNull);
      expect(Validators.email('user.name@domain.co'), isNull);

      // Invalid emails
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email('test@'), isNotNull);
    });

    test('Password validator should work correctly', () {
      // Valid passwords
      expect(Validators.password('123456'), isNull);
      expect(Validators.password('password123'), isNull);

      // Invalid passwords
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('123'), isNotNull);
      expect(Validators.password(null), isNotNull);
    });

    test('Name validator should work correctly', () {
      // Valid names
      expect(Validators.name('John Doe'), isNull);
      expect(Validators.name('María García'), isNull);

      // Invalid names
      expect(Validators.name(''), isNotNull);
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name(null), isNotNull);
    });

    test('Confirm password validator should work correctly', () {
      const originalPassword = 'password123';

      // Matching passwords
      expect(Validators.confirmPassword('password123', originalPassword), isNull);

      // Non-matching passwords
      expect(Validators.confirmPassword('different', originalPassword), isNotNull);
      expect(Validators.confirmPassword('', originalPassword), isNotNull);
      expect(Validators.confirmPassword(null, originalPassword), isNotNull);
    });
  });
}
