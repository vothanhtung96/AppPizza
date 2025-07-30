import 'package:firebase_auth/firebase_auth.dart'; // Re-enabled
import 'package:flutter/material.dart';
import 'package:pizza_app_vs_010/pages/signup.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  TextEditingController mailcontroller = TextEditingController();

  String email = "";
  bool isLoading = false;

  final _formkey = GlobalKey<FormState>();

  resetPassword() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Send real password reset email using Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Password Reset Email has been sent to $email!",
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      );

      // Clear the email field after successful send
      mailcontroller.clear();
    } on FirebaseAuthException catch (e) {
      print('Password reset error: $e');
      String errorMessage = 'Failed to send reset email';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email address';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many requests. Try again later';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(errorMessage, style: TextStyle(fontSize: 16.0)),
        ),
      );
    } catch (e) {
      print('Password reset error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Failed to send reset email: ${e.toString()}",
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        child: Column(
          children: [
            SizedBox(height: 70.0),
            Container(
              alignment: Alignment.topCenter,
              child: Text(
                "Password Recovery",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: MediaQuery.of(context).size.width > 600
                      ? 36.0
                      : 30.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              "Enter your email address",
              style: TextStyle(
                color: Colors.black87,
                fontSize: MediaQuery.of(context).size.width > 600 ? 24.0 : 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "We'll send you a link to reset your password",
              style: TextStyle(color: Colors.grey[600], fontSize: 14.0),
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Form(
                key: _formkey,
                child: Padding(
                  padding: EdgeInsets.only(left: 10.0),
                  child: ListView(
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 10.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!, width: 2.0),
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.grey[50],
                        ),
                        child: TextFormField(
                          controller: mailcontroller,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Email';
                            }
                            // Check if email format is valid
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value)) {
                              return 'Please Enter Valid Email';
                            }
                            return null;
                          },
                          style: TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: "Email",
                            hintStyle: TextStyle(
                              fontSize: 18.0,
                              color: Colors.grey[500],
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 30.0,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 40.0),
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                if (_formkey.currentState!.validate()) {
                                  setState(() {
                                    email = mailcontroller.text;
                                  });
                                  resetPassword();
                                }
                              },
                        child: Container(
                          width: MediaQuery.of(context).size.width > 600
                              ? 180
                              : 140,
                          padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width > 600 ? 15 : 10,
                          ),
                          decoration: BoxDecoration(
                            color: isLoading ? Colors.grey[400] : Colors.blue[600],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    "Send Email",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 50.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              fontSize: 18.0,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(width: 5.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUp(),
                                ),
                              );
                            },
                            child: Text(
                              "Create",
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 20.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
