// ignore_for_file: library_private_types_in_public_api, avoid_print
//new api all fixed i used api.env

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:skillmatch_platform/widgets/base_widgets/button.dart';
import 'package:skillmatch_platform/widgets/base_widgets/text_field.dart';
import 'package:skillmatch_platform/widgets/sign_up_widgets/check_verification_screen.dart';

final String baseUrl = dotenv.env['BASE_URL']!;

class SignUpScreen extends StatefulWidget {
  final String country;
  final String date;
  final String city;
  final String gender;
  final String userRole;

  const SignUpScreen({
    super.key,
    required this.country,
    required this.date,
    required this.city,
    required this.gender,
    required this.userRole,
  });

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final logger = Logger();
  String? errorMessage;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool agreeToTerms = false;
  bool _obscurePassword = true;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  void registerUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      String firstName = firstNameController.text;
      String lastName = lastNameController.text;
      String email = emailController.text;
      String username = usernameController.text;
      String phone = phoneController.text;
      String password = passwordController.text;

      try {
        var url = Uri.parse('$baseUrl/auth/register');

        var response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "name": "$firstName $lastName",
            "username": username,
            "email": email,
            "phone": phone,
            "password": password,
            "role": widget.userRole,
            "date": widget.date,
            "country": widget.country,
            "city": widget.city,
            "gender": widget.gender,
          }),
        );

        if (response.statusCode == 201) {
          var data = jsonDecode(response.body);
          logger.i("Registration successful", error: response.body);

          if (data.containsKey("token")) {
            String realToken = data["token"];
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        CheckVerificationScreen(token: realToken, email: email),
              ),
            );
          } else {
            setState(() {
              errorMessage = "Token not received from server";
            });
            logger.e("Token not received in response", error: response.body);
          }
        } else {
          var data = jsonDecode(response.body);
          setState(() {
            errorMessage = data["message"] ?? "Registration failed";
          });
          logger.e("Sign-up failed", error: response.body);
        }
      } catch (e) {
        logger.e("Registration error", error: e);
        setState(() {
          errorMessage = "An error occurred. Please try again.";
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    IconData? prefixIcon,
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
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        validator: validator,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16.0),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon:
              prefixIcon != null
                  ? Icon(prefixIcon, color: Theme.of(context).primaryColor)
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                  : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Almost there!",
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    "Please fill in your account details to complete registration",
                    style: TextStyle(fontSize: 16.0, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 32.0),

                  if (errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(16.0),
                      margin: EdgeInsets.only(bottom: 24.0),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 12.0),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: "First Name",
                          hint: "Enter first name",
                          controller: firstNameController,
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16.0),
                      Expanded(
                        child: _buildTextField(
                          label: "Last Name",
                          hint: "Enter last name",
                          controller: lastNameController,
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  _buildTextField(
                    label: "Username",
                    hint: "Choose a unique username",
                    controller: usernameController,
                    prefixIcon: Icons.alternate_email,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      }
                      return null;
                    },
                  ),

                  _buildTextField(
                    label: "Email",
                    hint: "Enter your email",
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: _validateEmail,
                  ),

                  _buildTextField(
                    label: "Phone Number",
                    hint: "Enter your phone number",
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),

                  _buildTextField(
                    label: "Password",
                    hint: "Create a strong password",
                    controller: passwordController,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                    validator: _validatePassword,
                  ),

                  SizedBox(height: 24.0),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: agreeToTerms,
                            onChanged: (bool? value) {
                              setState(() {
                                agreeToTerms = value ?? false;
                              });
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Expanded(
                          child: Wrap(
                            children: [
                              Text(
                                "I agree to the ",
                                style: TextStyle(fontSize: 16.0),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // TODO: Navigate to Privacy Policy
                                },
                                child: Text(
                                  "Privacy Policy",
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Theme.of(context).primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              Text(" and ", style: TextStyle(fontSize: 16.0)),
                              GestureDetector(
                                onTap: () {
                                  // TODO: Navigate to Terms of Use
                                },
                                child: Text(
                                  "Terms of Use",
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Theme.of(context).primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32.0),

                  SizedBox(
                    width: double.infinity,
                    height: 56.0,
                    child: BaseButton(
                      text:
                          isLoading ? "Creating Account..." : "Create Account",
                      onPressed:
                          isLoading || !agreeToTerms ? () {} : registerUser,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
