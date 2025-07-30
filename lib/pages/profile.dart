import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pizza_app_vs_010/models/promo_model.dart';
import 'package:pizza_app_vs_010/pages/loyalty_page.dart';
import 'package:pizza_app_vs_010/service/auth.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? profile, name, email, userId;
  int loyaltyPoints = 0;
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Uint8List? selectedImageBytes;
  bool isEditingName = false;
  bool isEditingEmail = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        selectedImageBytes = await image.readAsBytes();
        setState(() {
          uploadItem();
        });
      } else {
        selectedImage = File(image.path);
        setState(() {
          uploadItem();
        });
      }
    }
  }

  uploadItem() async {
    if (selectedImage != null || selectedImageBytes != null) {
      try {
        Uint8List imageBytes;
        if (kIsWeb) {
          imageBytes = selectedImageBytes!;
        } else {
          imageBytes = await selectedImage!.readAsBytes();
        }

        String base64Image = base64Encode(imageBytes);
        String imageData = 'data:image/jpeg;base64,$base64Image';

        await SharedPreferenceHelper().saveUserProfile(imageData);

        if (userId != null) {
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(userId)
              .update({"Profile": imageData});
        }

        setState(() {
          profile = imageData;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("Ảnh hồ sơ đã được cập nhật!"),
          ),
        );
      } catch (e) {
        print('Lỗi khi tải ảnh: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Không thể cập nhật ảnh hồ sơ"),
          ),
        );
      }
    }
  }

  Future<void> updateName() async {
    if (nameController.text.trim().isNotEmpty) {
      try {
        await SharedPreferenceHelper().saveUserName(nameController.text.trim());

        if (userId != null) {
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(userId)
              .update({"Name": nameController.text.trim()});
        }

        setState(() {
          name = nameController.text.trim();
          isEditingName = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("Tên đã được cập nhật!"),
          ),
        );
      } catch (e) {
        print('Lỗi khi cập nhật tên: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Không thể cập nhật tên"),
          ),
        );
      }
    }
  }

  Future<void> updateEmail() async {
    if (emailController.text.trim().isNotEmpty) {
      try {
        await SharedPreferenceHelper().saveUserEmail(
          emailController.text.trim(),
        );

        if (userId != null) {
          await FirebaseFirestore.instance
              .collection("Users")
              .doc(userId)
              .update({"Email": emailController.text.trim()});
        }

        setState(() {
          email = emailController.text.trim();
          isEditingEmail = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text("Email đã được cập nhật!"),
          ),
        );
      } catch (e) {
        print('Lỗi khi cập nhật email: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Không thể cập nhật email"),
          ),
        );
      }
    }
  }

  Future<void> _loadLoyaltyPoints() async {
    if (userId != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(userId)
            .get();
        setState(() {
          loyaltyPoints =
              (userDoc.data()?['loyaltyPoints'] as num?)?.toInt() ?? 0;
        });
      } catch (e) {
        print('❌ Lỗi khi tải điểm thưởng: $e');
      }
    }
  }

  getthesharedpref() async {
    profile = await SharedPreferenceHelper().getUserProfile();
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    userId = await SharedPreferenceHelper().getUserId();

    print('🔍 Thông tin hồ sơ:');
    print('  - User ID: $userId');
    print('  - Name: $name');
    print('  - Email: $email');
    print('  - Profile: ${profile != null ? "Có ảnh" : "Không có ảnh"}');

    if (userId != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("Users")
            .doc(userId)
            .get();

        print('  - Tài liệu Firestore tồn tại: ${userDoc.exists}');

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          print('  - Dữ liệu Firestore: $userData');

          if (userData['Profile'] != null &&
              userData['Profile'].toString().isNotEmpty) {
            profile = userData['Profile'];
            await SharedPreferenceHelper().saveUserProfile(profile!);
          }

          if (userData['Name'] != null &&
              userData['Name'].toString().isNotEmpty) {
            name = userData['Name'];
            await SharedPreferenceHelper().saveUserName(name!);
          }

          if (userData['Email'] != null &&
              userData['Email'].toString().isNotEmpty) {
            email = userData['Email'];
            await SharedPreferenceHelper().saveUserEmail(email!);
          }
        }
      } catch (e) {
        print('❌ Lỗi khi tải dữ liệu người dùng từ Firestore: $e');
      }
    }

    nameController.text = name ?? '';
    emailController.text = email ?? '';
    setState(() {});
  }

  onthisload() async {
    await getthesharedpref();
    await _loadLoyaltyPoints();
    setState(() {});
  }

  @override
  void initState() {
    onthisload();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Quay lại trang trước
          },
        ),
      ),
      body: userId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'Vui lòng đăng nhập',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: Text('Đăng nhập'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
              child: Column(
                children: [
                  // Header with profile image and name
                  Container(
                    height: isTablet ? 220 : 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.elliptical(
                          MediaQuery.of(context).size.width,
                          105.0,
                        ),
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Avatar tròn nổi lên header
                        Positioned(
                          top: isTablet ? 120 : 90, // Điều chỉnh để avatar nằm trong nền đen
                          left: 0,
                          right: 0,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                getImage();
                              },
                              child: CircleAvatar(
                                radius: isTablet ? 70 : 60,
                                backgroundColor: Colors.white,
                                backgroundImage: selectedImageBytes != null
                                    ? MemoryImage(selectedImageBytes!)
                                    : selectedImage != null && !kIsWeb
                                        ? FileImage(selectedImage!) as ImageProvider
                                        : profile != null && profile!.startsWith('data:image')
                                            ? MemoryImage(base64Decode(profile!.split(',')[1]))
                                            : profile != null && profile!.startsWith('http')
                                                ? NetworkImage(profile!)
                                                : AssetImage("images/boy.jpg") as ImageProvider,
                                onBackgroundImageError: (exception, stackTrace) {},
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isTablet ? 30.0 : 20.0),

                  // Name Card - Editable
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 30.0 : 20.0,
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(15),
                      elevation: 3.0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20.0 : 15.0,
                          horizontal: isTablet ? 20.0 : 15.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.black,
                              size: isTablet ? 28 : 24,
                            ),
                            SizedBox(width: isTablet ? 25.0 : 20.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Tên",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: isTablet ? 16.0 : 14.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  isEditingName
                                      ? TextField(
                                          controller: nameController,
                                          style: TextStyle(
                                            fontSize: isTablet ? 18.0 : 16.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                  vertical: 10,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          name ?? '',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: isTablet ? 18.0 : 16.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                if (isEditingName) {
                                  updateName();
                                } else {
                                  setState(() {
                                    isEditingName = true;
                                    nameController.text = name ?? '';
                                  });
                                }
                              },
                              child: Icon(
                                isEditingName ? Icons.check : Icons.edit,
                                color: isEditingName
                                    ? Colors.green
                                    : Colors.blue,
                                size: isTablet ? 26 : 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 25.0 : 20.0),

                  // Email Card - Editable
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 30.0 : 20.0,
                    ),
                    child: Material(
                      borderRadius: BorderRadius.circular(15),
                      elevation: 3.0,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 20.0 : 15.0,
                          horizontal: isTablet ? 20.0 : 15.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email,
                              color: Colors.black,
                              size: isTablet ? 28 : 24,
                            ),
                            SizedBox(width: isTablet ? 25.0 : 20.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Email",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: isTablet ? 16.0 : 14.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  isEditingEmail
                                      ? TextField(
                                          controller: emailController,
                                          style: TextStyle(
                                            fontSize: isTablet ? 18.0 : 16.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 15,
                                                  vertical: 10,
                                                ),
                                          ),
                                        )
                                      : Text(
                                          email ?? '',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: isTablet ? 18.0 : 16.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                ],
                              ),
                            ),
                            SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                if (isEditingEmail) {
                                  updateEmail();
                                } else {
                                  setState(() {
                                    isEditingEmail = true;
                                    emailController.text = email ?? '';
                                  });
                                }
                              },
                              child: Icon(
                                isEditingEmail ? Icons.check : Icons.edit,
                                color: isEditingEmail
                                    ? Colors.green
                                    : Colors.blue,
                                size: isTablet ? 26 : 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 25.0 : 20.0),

                  // Loyalty Points Card
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoyaltyPage(),
                        ),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isTablet ? 30.0 : 20.0,
                      ),
                      child: Material(
                        borderRadius: BorderRadius.circular(15),
                        elevation: 3.0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 20.0 : 15.0,
                            horizontal: isTablet ? 20.0 : 15.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: isTablet ? 28 : 24,
                              ),
                              SizedBox(width: isTablet ? 25.0 : 20.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Điểm thưởng",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: isTablet ? 16.0 : 14.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      '$loyaltyPoints điểm',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: isTablet ? 18.0 : 16.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.amber,
                                size: isTablet ? 20 : 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 25.0 : 20.0),

                  // LogOut Card
                  GestureDetector(
                    onTap: () async {
                      bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.orange,
                                size: 30,
                              ),
                              SizedBox(width: 10),
                              Text("Đăng xuất"),
                            ],
                          ),
                          content: Text("Bạn có chắc chắn muốn đăng xuất?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                "Hủy",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text("Đăng xuất"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await AuthMethods().SignOut();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.green,
                              content: Text("Đăng xuất thành công!"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (Route<dynamic> route) => false,
                          );
                        } catch (e) {
                          print('Lỗi đăng xuất: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: Colors.red,
                              content: Text(
                                "Không thể đăng xuất. Vui lòng thử lại.",
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: isTablet ? 30.0 : 20.0,
                      ),
                      child: Material(
                        borderRadius: BorderRadius.circular(15),
                        elevation: 3.0,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            vertical: isTablet ? 20.0 : 15.0,
                            horizontal: isTablet ? 20.0 : 15.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: Colors.orange,
                                size: isTablet ? 28 : 24,
                              ),
                              SizedBox(width: isTablet ? 25.0 : 20.0),
                              Text(
                                "Đăng xuất",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: isTablet ? 18.0 : 16.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.orange,
                                size: isTablet ? 20 : 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 25.0 : 20.0),

                  // Promo Codes Section
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 30.0 : 20.0,
                    ),
                    child: Material(
                      elevation: 2.0,
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Center(
                          child: Text(
                            "Mã khuyến mãi",
                            style: TextStyle(
                              fontSize: isTablet ? 22.0 : 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 20.0 : 16.0),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: _buildPromoCodesSection(),
                  ),

                  SizedBox(height: isTablet ? 25.0 : 20.0),

                  // Settings Button
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isTablet ? 30.0 : 20.0,
                    ),
                    child: Card(
                      elevation: 3.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: Icon(
                          FontAwesomeIcons.cog,
                          color: Colors.orange[600],
                        ),
                        title: Text('Cài đặt'),
                        subtitle: Text('Giao diện, thông báo, bảo mật'),
                        trailing: Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: isTablet ? 25.0 : 20.0),
                ],
              ),
            ),
    );
  }

  Widget _buildPromoCodesSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadUserPromos(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red[400]),
                SizedBox(height: 12),
                Text(
                  'Có lỗi xảy ra: ${snapshot.error}',
                  style: TextStyle(fontSize: 16, color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> promos = snapshot.data ?? [];

        if (promos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_offer, size: 48, color: Colors.grey[400]),
                SizedBox(height: 12),
                Text(
                  'Chưa có mã khuyến mãi nào',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: promos.length,
          itemBuilder: (context, index) {
            var promo = promos[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_offer, color: Colors.orange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            promo['name'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Mã: ${promo['code']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 4),
                    Text(
                      promo['description'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.discount, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            promo['discountPercent'] != null &&
                                    promo['discountPercent'] > 0
                                ? 'Giảm ${promo['discountPercent']}%'
                                : 'Giảm \$${promo['discountAmount']?.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadUserPromos() async {
    try {
      if (userId == null) return [];

      var snapshot = await FirebaseFirestore.instance
          .collection('promotions')
          .where('isActive', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> userPromos = [];

      for (var doc in snapshot.docs) {
        var promoData = doc.data();
        var promo = PromoModel.fromMap(promoData, doc.id);

        if (promo.isApplicableForUser(userId!)) {
          userPromos.add(promoData);
        }
      }

      return userPromos;
    } catch (e) {
      print('Lỗi khi tải mã khuyến mãi: $e');
      return [];
    }
  }
}
