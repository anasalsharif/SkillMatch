import 'package:flutter/material.dart';
import 'package:skillmatch_platform/widgets/base_widgets/button.dart';
import 'package:skillmatch_platform/widgets/login_widgets/login_page.dart';
import 'package:skillmatch_platform/widgets/sign_up_widgets/organization_signup_screen.dart';
import 'package:skillmatch_platform/widgets/sign_up_widgets/signup_user_details.dart';

class ChoosePositions extends StatefulWidget {
  const ChoosePositions({super.key});

  @override
  ChoosePositionsScreen createState() => ChoosePositionsScreen();
}

class ChoosePositionsScreen extends State<ChoosePositions> {
  String selectedRole = 'Job Seeker';
  List<String> roles = ['Job Seeker', 'Freelancer', 'Organization'];

  Widget _buildRoleCard(String role, String description, IconData icon) {
    bool isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRole = role;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color:
                isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
            width: 2.0,
          ),
          color:
              isSelected
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color:
                            isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 24.0,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your role',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Select the role that best describes you to get started.',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
                const SizedBox(height: 32.0),

                _buildRoleCard(
                  'Job Seeker',
                  'Looking for job opportunities and career growth',
                  Icons.work,
                ),
                _buildRoleCard(
                  'Freelancer',
                  'Work independently on various projects',
                  Icons.computer,
                ),
                _buildRoleCard(
                  'Organization',
                  'Hire talent and manage your company',
                  Icons.business,
                ),

                const SizedBox(height: 32.0),

                BaseButton(
                  text: "Continue",
                  onPressed: () {
                    if (selectedRole == 'Organization') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrganizationSignupScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  UserDetailsScreen(userRole: selectedRole),
                        ),
                      );
                    }
                  },
                ),

                const SizedBox(height: 16.0),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16.0),
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
