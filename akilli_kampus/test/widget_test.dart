import 'package:flutter_test/flutter_test.dart';
import 'package:akilli_kampus/main.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Uygulama Baslatma Testi', (WidgetTester tester) async {
    // MyApp yerine main.dart'taki AkilliKampusApp ismini kullanıyoruz
    await tester.pumpWidget(const AkilliKampusApp()); 

    // Uygulamanın bir MaterialApp ile başlayıp başlamadığını kontrol eder
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}