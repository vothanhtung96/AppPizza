import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pizza_app_vs_010/pages/bottomnav.dart';
import 'package:pizza_app_vs_010/pages/login.dart';
import 'package:pizza_app_vs_010/service/database.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:pizza_app_vs_010/widget/widget_support.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = "", password = "", name = "";

  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  registration() async {
    if (_formkey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text(
              "Đăng ký thành công",
              style: TextStyle(fontSize: 20.0),
            ),
          ),
        );

        String userId = userCredential.user!.uid;
        Map<String, dynamic> addUserInfo = {
          "Name": namecontroller.text,
          "Email": mailcontroller.text,
          "Wallet": "0",
          "Id": userId,
        };
        await DatabaseMethods().addUserDetail(addUserInfo, userId);
        await SharedPreferenceHelper().saveUserName(namecontroller.text);
        await SharedPreferenceHelper().saveUserEmail(mailcontroller.text);
        await SharedPreferenceHelper().saveUserWallet('0');
        await SharedPreferenceHelper().saveUserId(userId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottomNav()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Đăng ký thất bại';
        if (e.code == 'weak-password') {
          errorMessage = 'Mật khẩu quá yếu';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Tài khoản đã tồn tại';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Định dạng email không hợp lệ';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(errorMessage, style: TextStyle(fontSize: 18.0)),
          ),
        );
      } catch (e) {
        print('Registration error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Đăng ký thất bại: ${e.toString()}",
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isTablet = screenWidth > 600;

    return Scaffold(
      body: SingleChildScrollView(
        // Thêm SingleChildScrollView để cho phép cuộn
        child: Stack(
          children: [
            Container(
              width: screenWidth,
              height: screenHeight * (isTablet ? 0.35 : 0.3), // Tỷ lệ linh hoạt
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFff5c30), Color(0xFFe74b1a)],
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.only(
                top: screenHeight * (isTablet ? 0.3 : 0.25),
              ),
              width: screenWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isTablet ? 50 : 40),
                  topRight: Radius.circular(isTablet ? 50 : 40),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(
                horizontal: isTablet ? 40.0 : 20.0,
                vertical: isTablet ? 60.0 : 50.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Giới hạn kích thước cột
                children: [
                  Center(
                    child: Image.asset(
                      "images/logo.png",
                      width:
                          screenWidth *
                          (isTablet ? 0.5 : 0.7), // Tỷ lệ linh hoạt
                      fit: BoxFit.contain, // Đảm bảo logo không tràn
                    ),
                  ),
                  SizedBox(height: isTablet ? 40.0 : 30.0),
                  Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 25.0 : 20.0,
                        vertical: isTablet ? 20.0 : 15.0,
                      ),
                      width: screenWidth,
                      constraints: BoxConstraints(
                        minHeight:
                            screenHeight * 0.5, // Giới hạn chiều cao tối thiểu
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isTablet ? 25 : 20),
                      ),
                      child: Form(
                        key: _formkey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Giới hạn kích thước
                          children: [
                            Text(
                              "Đăng ký",
                              style: AppWidget.HeadlineTextFeildStyle(),
                            ),
                            SizedBox(height: isTablet ? 30.0 : 20.0),
                            TextFormField(
                              controller: namecontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập Tên';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Tên',
                                hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                prefixIcon: Icon(Icons.person_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            SizedBox(height: isTablet ? 20.0 : 15.0),
                            TextFormField(
                              controller: mailcontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập Email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Vui lòng nhập Email hợp lệ';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Email',
                                hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                prefixIcon: Icon(Icons.email_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            SizedBox(height: isTablet ? 20.0 : 15.0),
                            TextFormField(
                              controller: passwordcontroller,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Vui lòng nhập Mật khẩu';
                                }
                                if (value.length < 6) {
                                  return 'Mật khẩu phải có ít nhất 6 ký tự';
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Mật khẩu',
                                hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                prefixIcon: Icon(Icons.password_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                            SizedBox(height: isTablet ? 40.0 : 30.0),
                            GestureDetector(
                              onTap: () async {
                                if (_formkey.currentState!.validate()) {
                                  setState(() {
                                    email = mailcontroller.text;
                                    name = namecontroller.text;
                                    password = passwordcontroller.text;
                                  });
                                  await registration();
                                }
                              },
                              child: Material(
                                elevation: 5.0,
                                borderRadius: BorderRadius.circular(
                                  isTablet ? 25 : 20,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isTablet ? 12.0 : 8.0,
                                  ),
                                  width: isTablet
                                      ? 250
                                      : screenWidth * 0.5, // Responsive width
                                  decoration: BoxDecoration(
                                    color: Color(0Xffff5722),
                                    borderRadius: BorderRadius.circular(
                                      isTablet ? 25 : 20,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "ĐĂNG KÝ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isTablet ? 20.0 : 18.0,
                                        fontFamily: 'Poppins1',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 40.0 : 30.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Đã có tài khoản? ",
                                  style: AppWidget.semiBoldTextFeildStyle(),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LogIn(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Đăng nhập",
                                    style: TextStyle(
                                      color: Color(0Xffff5722),
                                      fontSize: 16.0,
                                      fontFamily: 'Poppins1',
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0Xffff5722),
                                      decorationThickness: 2.0,
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
          ],
        ),
      ),
    );
  }
}
