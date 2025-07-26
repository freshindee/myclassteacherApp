import 'package:flutter/material.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime? initialDate;
  final Function(DateTime) onDateSelected;
  final String label;

  const CustomDatePicker({
    super.key,
    this.initialDate,
    required this.onDateSelected,
    required this.label,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  int? selectedYear;
  int? selectedMonth;
  int? selectedDay;
  List<int> years = [];
  List<int> months = List.generate(12, (index) => index + 1);
  List<int> days = [];

  @override
  void initState() {
    super.initState();
    _initializeYears();
    if (widget.initialDate != null) {
      selectedYear = widget.initialDate!.year;
      selectedMonth = widget.initialDate!.month;
      selectedDay = widget.initialDate!.day;
      _updateDays();
    } else {
      // Default to 2020 (within the valid range 2005-2020)
      selectedYear = 2020;
      selectedMonth = DateTime.now().month;
      _updateDays();
      // Set default day to 1
      selectedDay = 1;
    }
  }

  void _initializeYears() {
    years = List.generate(2020 - 2005 + 1, (index) => 2005 + index);
  }

  void _updateDays() {
    if (selectedYear != null && selectedMonth != null) {
      final daysInMonth = DateTime(selectedYear!, selectedMonth! + 1, 0).day;
      days = List.generate(daysInMonth, (index) => index + 1);
      if (selectedDay != null && selectedDay! > daysInMonth) {
        selectedDay = daysInMonth;
      } else if (selectedDay == null) {
        selectedDay = 1;
      }
    } else {
      // Default to 31 days if year or month not selected
      days = List.generate(31, (index) => index + 1);
      if (selectedDay == null) {
        selectedDay = 1;
      }
    }
    setState(() {});
  }

  void _onDateChanged() {
    if (selectedYear != null && selectedMonth != null && selectedDay != null) {
      final selectedDate = DateTime(selectedYear!, selectedMonth!, selectedDay!);
      widget.onDateSelected(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Year dropdown
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedYear,
                decoration: const InputDecoration(
                  labelText: 'Year',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                dropdownColor: Colors.white,
                items: years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(
                      year.toString(),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedYear = value;
                    _updateDays();
                  });
                  _onDateChanged();
                },
              ),
            ),
            const SizedBox(width: 4),
            // Month dropdown
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedMonth,
                decoration: const InputDecoration(
                  labelText: 'Month',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                dropdownColor: Colors.white,
                items: months.map((month) {
                  return DropdownMenuItem(
                    value: month,
                    child: Text(
                      _getMonthName(month),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMonth = value;
                    _updateDays();
                  });
                  _onDateChanged();
                },
              ),
            ),
            const SizedBox(width: 4),
            // Day dropdown
            Expanded(
              child: DropdownButtonFormField<int>(
                value: selectedDay,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                dropdownColor: Colors.white,
                items: days.map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(
                      day.toString(),
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDay = value;
                  });
                  _onDateChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1];
  }
} 