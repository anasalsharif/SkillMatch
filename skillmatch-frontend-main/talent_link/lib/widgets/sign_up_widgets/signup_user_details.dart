import 'package:flutter/material.dart';
import 'package:skillmatch_platform/widgets/base_widgets/button.dart';
import 'package:skillmatch_platform/widgets/base_widgets/custom_date_picker.dart';
import 'package:skillmatch_platform/widgets/sign_up_widgets/signup_page.dart';
import 'package:skillmatch_platform/widgets/base_widgets/text_field.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userRole;

  const UserDetailsScreen({super.key, required this.userRole});

  @override
  UserDetailsScreenState createState() => UserDetailsScreenState();
}

class UserDetailsScreenState extends State<UserDetailsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String selectedGender = 'Male';
  List<String> genders = ['Male', 'Female'];

  TextEditingController dobController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController address2Controller = TextEditingController();
  TextEditingController cityController = TextEditingController();
  String? userdate;
  late String userCity;

  String selectedCountry = 'Palestine';
  List<String> countries = [
    'Palestine',
    'United States',
    'Canada',
    'United Kingdom',
    'Germany',
    'France',
    'Italy',
    'Spain',
    'Australia',
    'Brazil',
    'China',
    'Japan',
    'India',
    'Mexico',
    'Russia',
    'South Africa',
    'Saudi Arabia',
    'United Arab Emirates',
    'Turkey',
    'Egypt',
    'Argentina',
  ];

  int _currentStep = 0;

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              icon != null
                  ? Icon(icon, color: Theme.of(context).primaryColor)
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
        ),
        items:
            items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAddressField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isOptional = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: MyTextFieled(
        textHint: hint,
        textLable: isOptional ? "$label (Optional)" : label,
        controller: controller,
        obscureText: false,
      ),
    );
  }

  List<Step> get _steps => [
    Step(
      title: Text('Basic Info'),
      content: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: CustomDatePicker(
              controller: dobController,
              onDateSelected: (selectedDate) {
                userdate = selectedDate;
              },
            ),
          ),
          _buildDropdownField(
            label: 'Gender',
            value: selectedGender,
            items: genders,
            onChanged: (value) {
              setState(() {
                selectedGender = value!;
              });
            },
            icon: Icons.person_outline,
          ),
        ],
      ),
      isActive: _currentStep >= 0,
    ),
    Step(
      title: Text('Location'),
      content: Column(
        children: [
          _buildDropdownField(
            label: 'Country',
            value: selectedCountry,
            items: countries,
            onChanged: (value) {
              setState(() {
                selectedCountry = value!;
              });
            },
            icon: Icons.public,
          ),
          _buildAddressField(
            label: "City",
            hint: "Enter your city",
            controller: cityController,
          ),
          _buildAddressField(
            label: "Address",
            hint: "Enter your address",
            controller: addressController,
          ),
          _buildAddressField(
            label: "Address 2",
            hint: "Enter your second address",
            controller: address2Controller,
            isOptional: true,
          ),
        ],
      ),
      isActive: _currentStep >= 1,
    ),
  ];

  void onContinue() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      bool isValid = true;
      String errorMessage = '';

      // Validate date of birth
      if (userdate == null) {
        isValid = false;
        errorMessage = 'Please select your date of birth';
      }
      // Validate city
      else if (cityController.text.trim().isEmpty) {
        isValid = false;
        errorMessage = 'Please enter your city';
      }
      // Validate address
      else if (addressController.text.trim().isEmpty) {
        isValid = false;
        errorMessage = 'Please enter your address';
      }

      if (!isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        return;
      }

      // All validations passed, proceed to next screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => SignUpScreen(
                country: selectedCountry,
                date: userdate!,
                city: cityController.text,
                gender: selectedGender,
                userRole: widget.userRole,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Details'), elevation: 0),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Theme.of(context).primaryColor,
          ),
        ),
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepContinue: onContinue,
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            }
          },
          onStepTapped: (index) {
            setState(() {
              _currentStep = index;
            });
          },
          steps: _steps,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) SizedBox(width: 12),
                  Expanded(
                    child: BaseButton(
                      text:
                          _currentStep == _steps.length - 1
                              ? 'Continue'
                              : 'Next',
                      onPressed: onContinue,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
