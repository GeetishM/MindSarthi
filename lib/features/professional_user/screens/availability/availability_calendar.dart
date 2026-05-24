import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';

/// Availability calendar showing a weekly grid of time slots.
/// The professional can toggle slots on/off; state is persisted to
/// Appwrite in the users collection.
class AvailabilityCalendar extends ConsumerStatefulWidget {
  const AvailabilityCalendar({super.key});

  @override
  ConsumerState<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends ConsumerState<AvailabilityCalendar> {
  bool _isLoading = true;
  bool _isSaving = false;

  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _slots = [
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
  ];

  // Map<day, Set<slot>> — enabled slots
  final Map<String, Set<String>> _availability = {
    for (var d in _days) d: {},
  };

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      final databases = AppwriteService().databases;
      final doc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: user.$id,
      );

      if (doc.data['availability'] != null) {
        final raw = jsonDecode(doc.data['availability'] as String) as Map<String, dynamic>;
        for (var day in _days) {
          if (raw[day.toLowerCase()] != null) {
            _availability[day] =
                Set<String>.from(raw[day.toLowerCase()] as List);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load availability: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSlot(String day, String slot) {
    setState(() {
      if (_availability[day]!.contains(slot)) {
        _availability[day]!.remove(slot);
      } else {
        _availability[day]!.add(slot);
      }
    });
  }

  Future<void> _saveAvailability() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{};
      for (var day in _days) {
        data[day.toLowerCase()] = _availability[day]!.toList()..sort();
      }

      final databases = AppwriteService().databases;
      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: user.$id,
        data: {
          'availability': jsonEncode(data),
        },
      );

      if (mounted) AppToast.success(context, 'Availability saved');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Save failed', description: e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Set Availability',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isSaving ? null : _saveAvailability,
              child: Text(
                _isSaving ? 'Saving...' : 'Save',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Legend
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: Row(
                    children: [
                      _LegendDot(
                        color: theme.colorScheme.primary,
                        label: 'Available',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 20),
                      _LegendDot(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : theme.scaffoldBackgroundColor,
                        label: 'Unavailable',
                        isDark: isDark,
                        hasBorder: true,
                      ),
                    ],
                  ),
                ),

                // Grid
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 0,
                        horizontalMargin: 8,
                        headingRowHeight: 44,
                        dataRowMinHeight: 42,
                        dataRowMaxHeight: 42,
                        border: TableBorder.all(
                          color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(16),
                          width: 0.5,
                        ),
                        columns: [
                          DataColumn(
                            label: SizedBox(
                              width: 55,
                              child: Text(
                                'Time',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ),
                          for (var day in _days)
                            DataColumn(
                              label: SizedBox(
                                width: 44,
                                child: Center(
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                        rows: _slots.map((slot) {
                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 55,
                                  child: Text(
                                    slot,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                  ),
                                ),
                              ),
                              for (var day in _days)
                                DataCell(
                                  GestureDetector(
                                    onTap: () => _toggleSlot(day, slot),
                                    child: Center(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: _availability[day]!
                                                  .contains(slot)
                                              ? theme.colorScheme.primary
                                              : (isDark
                                                  ? theme.colorScheme.surfaceContainerHighest
                                                  : theme.scaffoldBackgroundColor),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _availability[day]!
                                                    .contains(slot)
                                                ? Colors.transparent
                                                : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant),
                                          ),
                                        ),
                                        child: _availability[day]!
                                                .contains(slot)
                                            ? const Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;
  final bool hasBorder;

  const _LegendDot({
    required this.color,
    required this.label,
    required this.isDark,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: hasBorder
                ? Border.all(
                    color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                  )
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
