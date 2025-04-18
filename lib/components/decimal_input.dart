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

    // Substitui vírgulas por pontos
    String formattedText = newText.replaceAll(',', '.');

    // Regex para validar números com até 'decimalRange' casas decimais
    final regex = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');

    // Verifica se o texto formatado é válido
    if (regex.hasMatch(formattedText)) {
      // Retorna o novo valor com a vírgula substituída por ponto
      return newValue.copyWith(text: formattedText);
    }

    // Caso contrário, retorna o valor antigo
    return oldValue;
  }
}
