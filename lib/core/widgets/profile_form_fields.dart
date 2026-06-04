import 'package:flutter/material.dart';

class ProfileNumericField extends StatelessWidget {
  const ProfileNumericField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.keyboardType,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: labelText),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
    );
  }
}

class ProfileOptionField<T> extends StatelessWidget {
  const ProfileOptionField({
    super.key,
    required this.value,
    required this.labelText,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final String labelText;
  final List<T> options;
  final String Function(T value) labelBuilder;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: labelText),
      items: options
          .map(
            (option) => DropdownMenuItem<T>(
              value: option,
              child: Text(labelBuilder(option)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
