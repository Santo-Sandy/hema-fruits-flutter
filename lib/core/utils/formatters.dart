import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatters {
  static String formatTomoney(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final formatter = NumberFormat('#,##0', 'en_IN');
    return formatter.format(number);
  }

  static String formatDate(dynamic dateValue) {
    try {
      if (dateValue == null || dateValue.toString().isEmpty) {
        return 'N/A';
      }
      final dateTime = DateTime.parse(dateValue.toString()).toLocal();
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  static String formatToKg(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    if (number >= 1000) {
      final formattedNumber = NumberFormat(
        '#,##0',
        'en_IN',
      ).format(number / 1000);
      return "$formattedNumber MT";
    }
    final formatter = NumberFormat('#,##0', 'en_IN');
    return "${formatter.format(number)} kg";
  }
}

class KgInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##,##0', 'en_IN');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove commas
    String cleanText = newValue.text.replaceAll(',', '');

    // Prevent empty crash
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Parse number
    final number = int.tryParse(cleanText);
    if (number == null) return oldValue;

    // Format with commas
    final newText = _formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class CommaInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##0');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If empty, return as-is
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remove all non-digit characters
    final numericString = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Prevent leading zero spam like 00001
    final cleaned = numericString.replaceFirst(RegExp(r'^0+'), '');
    final value = cleaned.isEmpty ? '0' : cleaned;

    // Format with commas
    final formatted = _formatter.format(int.parse(value));

    // Maintain cursor position
    int selectionIndex = formatted.length;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class MaxValueInputFormatter extends TextInputFormatter {
  final int maxValue;

  MaxValueInputFormatter(this.maxValue);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final values = newValue;

    final int? value = int.tryParse(values.text.replaceAll(',', ''));

    if (value == null) {
      return oldValue; // reject invalid input
    }

    if (value > maxValue) {
      return oldValue; // ❌ block values above max
    }

    return newValue; // ✅ allow
  }
}

class FirstLetterUpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    final formatted = text[0].toUpperCase() + text.substring(1);

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
