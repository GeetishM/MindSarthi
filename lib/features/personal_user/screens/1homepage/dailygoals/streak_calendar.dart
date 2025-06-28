import 'package:flutter/material.dart';
import 'package:mindsarthi/features/personal_user/screens/1homepage/dailygoals/streak_model.dart';
import 'package:table_calendar/table_calendar.dart';


class StreakCalendar extends StatelessWidget {
  final StreakModel streakModel;
  final Function(DateTime) onDayCompleted;

  const StreakCalendar({
    Key? key,
    required this.streakModel,
    required this.onDayCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Best Streak: ${streakModel.bestStreak} days',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: DateTime.now(),
          selectedDayPredicate: (day) =>
              streakModel.completedDays.contains(DateTime(day.year, day.month, day.day)),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              bool isCompleted = streakModel.completedDays.contains(DateTime(day.year, day.month, day.day));
              return Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.greenAccent : null,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isCompleted ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            onDayCompleted(selectedDay);
          },
        ),
      ],
    );
  }
}