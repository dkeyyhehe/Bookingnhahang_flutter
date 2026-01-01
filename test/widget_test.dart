import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baitap/app.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build app
    await tester.pumpWidget(const MyApp());

    // Kiểm tra có chữ Food Booking trên màn hình
    expect(find.text('Food Booking'), findsOneWidget);
  });
}
