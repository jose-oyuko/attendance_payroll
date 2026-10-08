import 'package:flutter/material.dart';

/// Password or PIN input with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    required this.controller,
    required this.label,
    super.key,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints = const <String>[AutofillHints.password],
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String> autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      enableSuggestions: false,
      autocorrect: false,
      autofillHints: widget.autofillHints,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          tooltip: _obscured ? 'Show ${widget.label}' : 'Hide ${widget.label}',
          icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      ),
    );
  }
}
