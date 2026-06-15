import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/offset_shadow_card.dart';


class DateRangePickerProps {
  final DateTime initialStartDate;
  final DateTime initialEndDate;

  const DateRangePickerProps({
    required this.initialStartDate,
    required this.initialEndDate,
  });
}

class DateRangePicker extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final Function(DateTime start, DateTime end) onSaved;

  const DateRangePicker({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.onSaved,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  late DateTime _tempStartDate;
  late DateTime _tempEndDate;
  late DateTime _currentMonth;
  String _selectedPreset = 'Today';

  @override
  void initState() {
    super.initState();
    _tempStartDate = widget.initialStartDate;
    _tempEndDate = widget.initialEndDate;
    _currentMonth = DateTime(_tempStartDate.year, _tempStartDate.month, 1);
    _updateSelectedPresetName();
  }

  void _updateSelectedPresetName() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    bool isSameDate(DateTime d1, DateTime d2) =>
        d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

    if (isSameDate(_tempStartDate, today) && isSameDate(_tempEndDate, today)) {
      _selectedPreset = 'Today';
    } else if (isSameDate(_tempStartDate, today.subtract(const Duration(days: 1))) &&
        isSameDate(_tempEndDate, today.subtract(const Duration(days: 1)))) {
      _selectedPreset = 'Yesterday';
    } else {
      _selectedPreset = 'Custom';
    }
  }

  void _applyPreset(String preset) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start = today;
    DateTime end = today;

    switch (preset) {
      case 'Today':
        start = today;
        end = today;
        break;
      case 'Yesterday':
        start = today.subtract(const Duration(days: 1));
        end = start;
        break;
      case 'This Week':
        // Start of week: Monday
        final weekday = today.weekday;
        start = today.subtract(Duration(days: weekday - 1));
        end = today;
        break;
      case 'Last Week':
        final weekday = today.weekday;
        end = today.subtract(Duration(days: weekday));
        start = end.subtract(const Duration(days: 6));
        break;
      case 'This Month':
        start = DateTime(today.year, today.month, 1);
        end = DateTime(today.year, today.month + 1, 0);
        break;
      case 'Last Month':
        start = DateTime(today.year, today.month - 1, 1);
        end = DateTime(today.year, today.month, 0);
        break;
      case 'This Year':
        start = DateTime(today.year, 1, 1);
        end = DateTime(today.year, 12, 31);
        break;
      default:
        return;
    }

    setState(() {
      _tempStartDate = start;
      _tempEndDate = end;
      _currentMonth = DateTime(start.year, start.month, 1);
      _selectedPreset = preset;
    });
  }

  void _onDaySelected(DateTime date) {
    setState(() {
      _selectedPreset = 'Custom';
      if (_tempStartDate == _tempEndDate) {
        // One date was selected, now select second
        if (date.isBefore(_tempStartDate)) {
          _tempStartDate = date;
        } else {
          _tempEndDate = date;
        }
      } else {
        // Reset and select single date
        _tempStartDate = date;
        _tempEndDate = date;
      }
    });
  }

  bool _isWithinRange(DateTime date) {
    return date.isAfter(_tempStartDate.subtract(const Duration(seconds: 1))) &&
        date.isBefore(_tempEndDate.add(const Duration(seconds: 1)));
  }

  bool _isStart(DateTime date) {
    return date.year == _tempStartDate.year &&
        date.month == _tempStartDate.month &&
        date.day == _tempStartDate.day;
  }

  bool _isEnd(DateTime date) {
    return date.year == _tempEndDate.year &&
        date.month == _tempEndDate.month &&
        date.day == _tempEndDate.day;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    final presets = [
      'Today',
      'Yesterday',
      'This Week',
      'Last Week',
      'This Month',
      'Last Month',
      'This Year',
      'Custom'
    ];

    // Compute month details
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final leadingEmptyDays = (firstDayOfMonth.weekday - 1) % 7; // assuming Monday start

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 420),
        child: OffsetShadowCard(
          backgroundColor: tokens.surface,
          shadowColor: tokens.border,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
            // Title Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.date_range, color: tokens.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Select Date Range',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: tokens.text,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(_tempStartDate)} - ${DateFormat('MMM d, yyyy').format(_tempEndDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: tokens.accent,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Body Content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 420;
                  final calendarWidget = Column(
                    children: [
                      // Calendar Month Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.chevron_left, color: tokens.textSubtle),
                              onPressed: () {
                                setState(() {
                                  _currentMonth = DateTime(
                                    _currentMonth.year,
                                    _currentMonth.month - 1,
                                    1,
                                  );
                                });
                              },
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_currentMonth),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: tokens.text,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.chevron_right, color: tokens.textSubtle),
                              onPressed: () {
                                setState(() {
                                  _currentMonth = DateTime(
                                    _currentMonth.year,
                                    _currentMonth.month + 1,
                                    1,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      // Weekday labels
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                              .map((day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: tokens.textSubtle,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Calendar Day Grid
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: daysInMonth + leadingEmptyDays,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 2,
                            crossAxisSpacing: 2,
                          ),
                          itemBuilder: (context, index) {
                            if (index < leadingEmptyDays) {
                              return const SizedBox.shrink();
                            }
                            final day = index - leadingEmptyDays + 1;
                            final date = DateTime(year, month, day);

                            final isStart = _isStart(date);
                            final isEnd = _isEnd(date);
                            final inRange = _isWithinRange(date);

                            BoxDecoration? boxDeco;
                            TextStyle? textStyle = TextStyle(color: tokens.text, fontSize: 12);

                            if (isStart || isEnd) {
                              boxDeco = BoxDecoration(
                                color: tokens.accent,
                                shape: BoxShape.circle,
                              );
                              textStyle = const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              );
                            } else if (inRange) {
                              boxDeco = BoxDecoration(
                                color: tokens.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(4),
                              );
                              textStyle = TextStyle(
                                color: tokens.accent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              );
                            }

                            return GestureDetector(
                              onTap: () => _onDaySelected(date),
                              child: Container(
                                decoration: boxDeco,
                                child: Center(
                                  child: Text(
                                    '$day',
                                    style: textStyle,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        // Horizontal Presets List
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: tokens.border),
                            ),
                          ),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: presets.length,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            itemBuilder: (context, index) {
                              final preset = presets[index];
                              final isSelected = _selectedPreset == preset;
                              return InkWell(
                                onTap: preset == 'Custom' ? null : () => _applyPreset(preset),
                                child: Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? tokens.accent.withValues(alpha: 0.12)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    preset,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? tokens.accent : tokens.textSubtle,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Calendar View
                        Expanded(
                          child: calendarWidget,
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Presets Sidebar (Left)
                        Container(
                          width: 130,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: tokens.border),
                            ),
                          ),
                          child: ListView.builder(
                            itemCount: presets.length,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemBuilder: (context, index) {
                              final preset = presets[index];
                              final isSelected = _selectedPreset == preset;
                              return InkWell(
                                onTap: preset == 'Custom' ? null : () => _applyPreset(preset),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  color: isSelected
                                      ? tokens.accent.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  child: Text(
                                    preset,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? tokens.accent : tokens.textSubtle,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Calendar View (Right)
                        Expanded(
                          child: calendarWidget,
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
            const Divider(height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: tokens.textSubtle),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tokens.accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onPressed: () {
                      widget.onSaved(_tempStartDate, _tempEndDate);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
