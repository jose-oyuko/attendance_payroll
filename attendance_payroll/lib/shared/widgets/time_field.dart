import 'package:flutter/material.dart';

/// Time-of-day input that opens a time picker.
class TimeField extends StatelessWidget {
  const TimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.validator,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onChanged;
  final FormFieldValidator<TimeOfDay>? validator;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: value ?? TimeOfDay.now(),
      helpText: label,
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = value;
    return FormField<TimeOfDay>(
      initialValue: current,
      validator: (_) => validator?.call(value),
      builder: (field) => InkWell(
        onTap: () => _pick(context),
        child: InputDecorator(
          isEmpty: current == null,
          decoration: InputDecoration(
            labelText: label,
            errorText: field.errorText,
            suffixIcon: const Icon(Icons.schedule),
          ),
          child: current == null ? null : Text(current.format(context)),
        ),
      ),
    );
  }
}
