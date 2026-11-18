import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutttterrr/screens/login_screen.dart';
import 'package:flutttterrr/screens/register_screen.dart';
import 'package:flutttterrr/services/session.dart';

void main() {
  testWidgets('halaman login menampilkan form', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final session = Session();

    await tester.pumpWidget(MaterialApp(home: LoginScreen(session: session)));

    expect(find.text('INVENTRA'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });

  testWidgets('halaman register menampilkan form', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final session = Session();

    await tester.pumpWidget(
      MaterialApp(home: RegisterScreen(session: session)),
    );

    expect(find.text('Daftar Akun'), findsOneWidget);
    expect(find.text('Nama'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Konfirmasi Password'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
