import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../const/colors.dart';

class DiaryCalendar extends StatelessWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  final Map<DateTime, bool> diaryDates;

  const DiaryCalendar({
    Key? key,
    required this.selectedDate,
    required this.onDateSelected,
    required this.diaryDates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      focusedDay: selectedDate,
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      onDaySelected: (selectedDay, _) => onDateSelected(selectedDay),

      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: LIGHT_YELLOW_COLOR, // 원의 배경색 설정
          shape: BoxShape.circle, // 원 모양
        ),

        weekendDecoration: BoxDecoration(
          color: WHITE_COLOR, // 원의 배경색 설정
          shape: BoxShape.circle, // 원 모양
        ),

        selectedDecoration: BoxDecoration(
          color: DARK_VIOLET_COLOR, // 원의 배경색 설정
          shape: BoxShape.circle, // 원 모양
        ),

        defaultDecoration: BoxDecoration(
          color: WHITE_COLOR, // 원의 배경색 설정
          shape: BoxShape.circle, // 원 모양
        ),

        markerDecoration: BoxDecoration(
          color: DARK_VIOLET_COLOR, // 원의 배경색 설정
          shape: BoxShape.circle, // 원 모양
        ),
      ),

      eventLoader: (day) => diaryDates[day] == true ? ["Diary"] : [],
      headerStyle: HeaderStyle(
        formatButtonVisible: false, // "2weeks" 버튼 숨기기
      ),
    );
  }
}
