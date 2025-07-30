import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pizza_app_vs_010/admin/admin_login.dart';
import 'package:pizza_app_vs_010/pages/bottomnav.dart';
import 'package:pizza_app_vs_010/pages/forgotpassword.dart';
import 'package:pizza_app_vs_010/pages/signup.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  String email = "", password = "";
  bool _obscurePassword = true;

  final _formkey = GlobalKey<FormState>();

  TextEditingController useremailcontroller = TextEditingController();
  TextEditingController userpasswordcontroller = TextEditingController();

  userLogin() async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required');
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("Users")
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          await SharedPreferenceHelper().saveUserName(userData['Name'] ?? '');
          await SharedPreferenceHelper().saveUserEmail(userData['Email'] ?? '');
          await SharedPreferenceHelper().saveUserWallet(
            userData['Wallet']?.toString() ?? '0',
          );
          await SharedPreferenceHelper().saveUserId(userCredential.user!.uid);

          print('User info saved: ${userData['Name']}');
          print('User ID saved: ${userCredential.user!.uid}');
        } else {
          print('User document does not exist');
        }
      } catch (e) {
        print('Error loading user details: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Đăng nhập thành công",
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNav()),
      );
    } on FirebaseAuthException catch (e) {
      print('Login error: $e');
      String errorMessage = 'Đăng nhập thất bại';

      if (e.code == 'user-not-found') {
        errorMessage = 'Không tìm thấy người dùng với email này';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Sai mật khẩu';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Định dạng email không hợp lệ';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Tài khoản này đã bị vô hiệu hóa';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Quá nhiều lần thử thất bại. Vui lòng thử lại sau';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(errorMessage, style: TextStyle(fontSize: 16.0)),
        ),
      );
    } catch (e) {
      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Đăng nhập thất bại: ${e.toString()}",
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    bool isTablet = screenWidth > 600;
    bool isDesktop = screenWidth > 900;

    return Scaffold(
      body: SingleChildScrollView(
        // Thêm SingleChildScrollView để cho phép cuộn
        child: Stack(
          children: [
            Container(
              width: screenWidth,
              height:
                  screenHeight * (isTablet ? 0.4 : 0.35), // Tỷ lệ linh hoạt hơn
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
                top: screenHeight * (isTablet ? 0.35 : 0.3),
              ),
              height: screenHeight,
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
                vertical: isTablet ? 80.0 : 60.0,
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
                      fit: BoxFit.contain, // Đảm bảo hình ảnh không tràn
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
                              "Đăng nhập",
                              style: TextStyle(
                                fontSize: isTablet ? 28.0 : 24.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: isTablet ? 40.0 : 30.0),
                            // Email field
                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 10.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: useremailcontroller,
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
                                  hintText: "Email",
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.envelope,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            // Password field
                            Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 10.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: userpasswordcontroller,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Vui lòng nhập mật khẩu';
                                  }
                                  if (value.length < 6) {
                                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                                  }
                                  return null;
                                },
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: "Mật khẩu",
                                  hintStyle: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.lock,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? FontAwesomeIcons.eyeSlash
                                          : FontAwesomeIcons.eye,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 25.0 : 20.0),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ForgotPassword(),
                                  ),
                                );
                              },
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  "Quên mật khẩu?",
                                  style: TextStyle(
                                    fontSize: isTablet ? 16.0 : 14.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 40.0 : 30.0),
                            GestureDetector(
                              onTap: () async {
                                if (_formkey.currentState!.validate()) {
                                  setState(() {
                                    email = useremailcontroller.text;
                                    password = userpasswordcontroller.text;
                                  });
                                  await userLogin();
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
                                      "ĐĂNG NHẬP",
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
                                "Chưa có tài khoản? Đăng ký",
                                style: TextStyle(
                                  fontSize: isTablet ? 16.0 : 14.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            SizedBox(height: isTablet ? 25.0 : 20.0),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminLogin(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: isTablet ? 12.0 : 8.0,
                                  horizontal: isTablet ? 25.0 : 20.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(
                                    isTablet ? 15 : 10,
                                  ),
                                ),
                                child: Text(
                                  "Đăng nhập Admin",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 18.0 : 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}
