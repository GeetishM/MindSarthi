import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';

/// Availability calendar showing a weekly grid of time slots.
/// The professional can toggle slots on/off; state is persisted to
/// Firestore at `professionals/{uid}.availability`.
class AvailabilityCalendar extends StatefulWidget {
  const AvailabilityCalendar({super.key});

  @override
  State<AvailabilityCalendar> createState() => _AvailabilityCalendarState();
}

class _AvailabilityCalendarState extends State<AvailabilityCalendar> {
  final _uid = FirebaseAuth.instance.currentUser?.uid;
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
    try {
      final doc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(_uid)
          .get();

      if (doc.exists && doc.data()?['availability'] != null) {
        final raw = doc.data()!['availability'] as Map<String, dynamic>;
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
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{};
      for (var day in _days) {
        data[day.toLowerCase()] = _availability[day]!.toList()..sort();
      }

      await FirebaseFirestore.instance
          .collection('professionals')
          .doc(_uid)
          .set({'availability': data}, SetOptions(merge: true));

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Set Availability',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
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
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
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
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        label: 'Available',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 20),
                      _LegendDot(
                        color: isDark ? AppColors.darkSurface2 : AppColors.background,
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
                          color:
                              isDark ? AppColors.darkBorder : AppColors.border,
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
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
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
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.textPrimary,
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
                                      color: isDark
                                          ? AppColors.darkTextSecondary
                                          : AppColors.textSecondary,
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
                                              ? (isDark
                                                  ? AppColors.darkPrimary
                                                  : AppColors.primary)
                                              : (isDark
                                                  ? AppColors.darkSurface2
                                                  : AppColors.background),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: _availability[day]!
                                                    .contains(slot)
                                                ? Colors.transparent
                                                : (isDark
                                                    ? AppColors.darkBorder
                                                    : AppColors.border),
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
                    color: isDark ? AppColors.darkBorder : AppColors.border,
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
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
