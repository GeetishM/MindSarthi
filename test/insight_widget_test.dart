import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight.dart';
import 'package:mindsarthi/features/personal_user/screens/3insightpage/insight_data.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Insight.isTestingMode = true;
    Insight.testInsightsList = [
      Insight(
        id: 'test_1',
        heading: 'Test Title One',
        content: 'This is test content number one.',
        author: 'Author A',
        date: 'May 20, 2026',
        category: 'Insomnia',
      ),
      Insight(
        id: 'test_2',
        heading: 'Test Title Two',
        content: 'This is test content number two.',
        author: 'Author B',
        date: 'May 21, 2026',
        category: 'Panic Attacks',
      ),
    ];
  });

  testWidgets('Insights Feed and CMS integration widget test', (WidgetTester tester) async {
    // 1. Discover feed successfully loads insights.
    await tester.pumpWidget(
      const MaterialApp(
        home: InsightPage(),
      ),
    );

    // Wait for the stream controller to yield the test list data
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Verify list displays loaded insights
    expect(find.text('Test Title One'), findsOneWidget);
    expect(find.text('Test Title Two'), findsOneWidget);
    expect(find.text('Author A'), findsOneWidget);
    expect(find.text('Author B'), findsOneWidget);

    // 2. Search bar successfully filters insights.
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    // Enter search query "One"
    await tester.enterText(searchField, 'One');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // "Test Title One" should remain, "Test Title Two" should disappear
    expect(find.text('Test Title One'), findsOneWidget);
    expect(find.text('Test Title Two'), findsNothing);

    // Clear search query
    await tester.enterText(searchField, '');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    // Both should reappear
    expect(find.text('Test Title One'), findsOneWidget);
    expect(find.text('Test Title Two'), findsOneWidget);

    // 3. Navigating to the Admin CMS and adding/editing/deleting a document updates the state.
    final cmsButton = find.byKey(const ValueKey('cms_nav_button'));
    expect(cmsButton, findsOneWidget);

    // Tap CMS entry button
    await tester.tap(cmsButton);
    await tester.pumpAndSettle();

    // Verify navigation to Insights CMS
    expect(find.text('Insights CMS'), findsOneWidget);
    expect(find.text('Test Title One'), findsOneWidget);
    expect(find.text('Test Title Two'), findsOneWidget);

    // Add a new insight
    final addButton = find.byIcon(CupertinoIcons.add_circled_solid);
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    // Fill in the CupertinoTextFields
    final fields = find.byType(CupertinoTextField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(0), 'Added Title Three');
    await tester.enterText(fields.at(1), 'Author C');
    await tester.enterText(fields.at(2), 'Insomnia');
    await tester.enterText(fields.at(3), 'This is the body content of number three.');
    await tester.pump();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify it is added in CMS list
    expect(find.text('Added Title Three'), findsOneWidget);

    // Edit an insight (edit "test_1")
    final editButton = find.byKey(const ValueKey('edit_test_1'));
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    final editFields = find.byType(CupertinoTextField);
    await tester.enterText(editFields.at(0), 'Edited Title One');
    await tester.pump();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // Verify it is updated in CMS list
    expect(find.text('Edited Title One'), findsOneWidget);
    expect(find.text('Test Title One'), findsNothing);

    // Delete an insight (delete "test_2")
    final deleteButton = find.byKey(const ValueKey('delete_test_2'));
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Verify delete Action Sheet opens, and tap Delete
    expect(find.text('Are you sure you want to permanently delete this insight? This action cannot be undone.'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    // Verify it is removed from CMS list
    expect(find.text('Test Title Two'), findsNothing);

    // Navigate back to the Discover feed
    final backButton = find.byIcon(CupertinoIcons.back);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // Verify updated state on main feed page
    expect(find.text('Edited Title One'), findsOneWidget);
    expect(find.text('Added Title Three'), findsOneWidget);
    expect(find.text('Test Title Two'), findsNothing);
  });
}
