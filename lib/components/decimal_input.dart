import 'package:flutter/services.dart';

class DecimalInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    if (newText.isEmpty) {
      return newValue;
    }

    final regex = RegExp(r'^\d*\.?\d{0,2}$');

    if (regex.hasMatch(newText)) {
      return newValue;
    }

    return oldValue;
  }
}
