import 'package:attendance_payroll/core/utils/local_date.dart';
import 'package:flutter/material.dart';

/// Calendar date input that opens a date picker. Holds a [LocalDate], never a
/// `DateTime`, so no timezone can shift the day.
class DateField extends StatelessWidget {
  const DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.allowClear = false,
    this.validator,
  });

  static final DateTime _firstDate = DateTime(1950);
  static final DateTime _lastDate = DateTime(2100);

  final String label;
  final LocalDate? value;
  final ValueChanged<LocalDate?> onChanged;
  final bool allowClear;
  final FormFieldValidator<LocalDate>? validator;

  Future<void> _pick(BuildContext context) async {
    final current = value;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null
          ? now
          : DateTime(current.year, current.month, current.day),
      firstDate: _firstDate,
      lastDate: _lastDate,
      helpText: label,
    );
    if (picked != null) {
      onChanged(LocalDate.fromDateTime(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    final localizations = MaterialLocalizations.of(context);
    return FormField<LocalDate>(
      initialValue: current,
      validator: (_) => validator?.call(value),
      builder: (field) => InkWell(
        onTap: () => _pick(context),
        child: InputDecorator(
          isEmpty: current == null,
          decoration: InputDecoration(
            labelText: label,
            errorText: field.errorText,
            suffixIcon: allowClear && current != null
                ? IconButton(
                    tooltip: 'Clear $label',
                    icon: const Icon(Icons.clear),
                    onPressed: () => onChanged(null),
                  )
                : const Icon(Icons.calendar_today_outlined),
          ),
          child: current == null
              ? null
              : Text(
                  localizations.formatMediumDate(
                    DateTime(current.year, current.month, current.day),
                  ),
                ),
        ),
      ),
    );
  }
}
