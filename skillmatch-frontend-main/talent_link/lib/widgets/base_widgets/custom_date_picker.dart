import 'package:flutter/material.dart';
import 'package:skillmatch_platform/widgets/base_widgets/text_field.dart';

class CustomDatePicker extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onDateSelected;

  const CustomDatePicker({
    super.key,
    required this.controller,
    required this.onDateSelected,
  });

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF0C9E91), // Top bar & selected date
            hintColor: const Color(0xFF0C9E91), // Calendar highlight
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0C9E91), // Confirm button color
              onPrimary: Colors.white, // Confirm button text
              onSurface: Colors.black, // Default text
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      String formattedDate =
          "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
      controller.text = formattedDate;
      onDateSelected(formattedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: AbsorbPointer(
        child: MyTextFieled(
          textHint: "Select your date of birth",
          textLable: "Date of Birth",
          controller: controller,
          obscureText: false,
        ),
      ),
    );
  }
}
