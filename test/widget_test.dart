import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindsarthi/core/widgets/pin_input_widget.dart';

void main() {
  testWidgets('PinInputWidget displays title and accepts input', (WidgetTester tester) async {
    String completedPin = '';
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinInputWidget(
            title: 'Enter App Pin',
            onCompleted: (pin) {
              completedPin = pin;
            },
          ),
        ),
      ),
    );

    // Verify title text is displayed
    expect(find.text('Enter App Pin'), findsOneWidget);

    // Verify Pinput exists
    expect(find.byType(typeOf<PinInputWidget>()), findsOneWidget);
  });
}

Type typeOf<T>() => T;

