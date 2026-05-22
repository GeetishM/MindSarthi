import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindsarthi/features/personal_user/screens/2consultpage/consult.dart';

void main() {
  testWidgets('ConsultPage booking flow smoke test', (WidgetTester tester) async {
    // Set a larger viewport size to accommodate the UI elements.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    // Build ConsultPage within a MaterialApp and Scaffold.
    ConsultPage.isTestingMode = true;
    ConsultPage.testTherapistsList = List<Therapist>.from(kTherapists);
    ConsultPage.testSessionsList = [
      Session(
        id: 's1',
        therapistName: 'Dr. Neha Sharma',
        status: 'Upcoming',
        dateTime: DateTime.now().add(const Duration(days: 1)),
        type: 'Video',
      ),
      Session(
        id: 's2',
        therapistName: 'Dr. John Doe',
        status: 'Completed',
        dateTime: DateTime.now().subtract(const Duration(days: 2)),
        type: 'Voice',
      ),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ConsultPage(),
        ),
      ),
    );
    await tester.pump();

    // Verify initial state: "Your Sessions" lists existing sessions.
    expect(find.text('Your Sessions'), findsOneWidget);
    expect(find.text('Dr. Neha Sharma'), findsWidgets); // Appears in sessions list and expert list
    expect(find.text('Dr. John Doe'), findsWidgets);

    // Verify filter categories are displayed.
    expect(find.text('All'), findsWidgets);
    expect(find.text('Anxiety'), findsWidgets);
    expect(find.text('Depression'), findsWidgets);

    // Find and tap the first 'Book Slot' button.
    final bookSlotButtons = find.text('Book Slot');
    expect(bookSlotButtons, findsWidgets);
    
    // Tap the first 'Book Slot' button (Dr. Neha Sharma).
    await tester.tap(bookSlotButtons.first);
    await tester.pumpAndSettle(); // Animate bottom sheet open.

    // Verify bottom sheet booking components are shown.
    expect(find.text('Select Date'), findsOneWidget);
    expect(find.text('Available Time Slots'), findsOneWidget);
    expect(find.text('Session Mode'), findsOneWidget);
    expect(find.text('Confirm Booking'), findsOneWidget);

    // Tap "Confirm Booking" button in the bottom sheet.
    await tester.tap(find.text('Confirm Booking'));
    
    // Pump for the 800ms delay in BookingSheet confirmation.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pumpAndSettle(); // Wait for navigation transition and state updates to complete.

    // Verify booking sheet is popped.
    expect(find.text('Select Date'), findsNothing);
    
    // Verify that the new session is added and visible in "Your Sessions" list.
    expect(find.text('Session booked with Dr. Neha Sharma!'), findsOneWidget);
  });
}
