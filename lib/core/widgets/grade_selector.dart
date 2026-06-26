import 'package:flutter/material.dart';

/// Hardcoded grades 1 to 13. Use anywhere a grade dropdown is needed.
///
/// Example:
/// ```dart
/// GradeSelector(
///   value: _grade,
///   onGradeSelected: (grade) => setState(() => _grade = grade),
///   label: 'Select grade',
/// )
/// ```
class GradeSelector extends StatelessWidget {
  /// Grades 1 to 13 (as strings).
  static const List<String> grades = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13',
  ];

  /// Called when the user selects a grade. Value is "1".."13" or null if cleared.
  final void Function(String? grade)? onGradeSelected;

  /// Currently selected grade (e.g. "5"). Parent should update this in setState.
  final String? value;

  /// Optional label above the dropdown.
  final String? label;

  /// Hint when nothing is selected.
  final String hint;

  /// If true, use a more compact style.
  final bool compact;

  /// When set, used instead of [grades] for dropdown items (e.g. from cache: "Yellow Birds", "9").
  final List<String>? customGrades;

  const GradeSelector({
    super.key,
    this.onGradeSelected,
    this.value,
    this.label,
    this.hint = 'Select grade',
    this.compact = false,
    this.customGrades,
  });

  List<String> get _effectiveGrades =>
      (customGrades != null && customGrades!.isNotEmpty) ? customGrades! : grades;

  static bool _isNumericGrade(String g) =>
      g.trim().isNotEmpty && int.tryParse(g.replaceAll(RegExp(r'[^0-9]'), '')) != null;

  @override
  Widget build(BuildContext context) {
    final effective = _effectiveGrades;
    final valueInList = value != null && effective.contains(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null && label!.isNotEmpty) ...[
          Text(
            label!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          SizedBox(height: compact ? 4 : 6),
        ],
        DropdownButtonFormField<String>(
          value: valueInList ? value : null,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: compact ? 8 : 12,
            ),
          ),
          hint: Text(hint),
          items: effective
              .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(_isNumericGrade(g) ? 'Grade $g' : g),
                  ))
              .toList(),
          onChanged: onGradeSelected,
        ),
      ],
    );
  }
}
