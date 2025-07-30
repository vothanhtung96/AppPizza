import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:firebase_storage/firebase_storage.dart'; // Commented out to avoid CORS
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pizza_app_vs_010/service/database.dart';
import 'package:pizza_app_vs_010/widget/widget_support.dart';
// import 'package:random_string/random_string.dart'; // Not needed anymore

class AddFood extends StatefulWidget {
  const AddFood({super.key});

  @override
  State<AddFood> createState() => _AddFoodState();
}

class _AddFoodState extends State<AddFood> {
  List<String> fooditems = []; // Thay đổi thành list rỗng
  String? value;
  TextEditingController namecontroller = TextEditingController();
  TextEditingController pricecontroller = TextEditingController();
  TextEditingController detailcontroller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Uint8List? selectedImageBytes;
  bool isUploading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _loadCategories(); // Load categories khi khởi tạo
  }

  Future<void> _loadCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Categories')
          .get();

      setState(() {
        fooditems = snapshot.docs
            .map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['Name'] ?? data['name'] ?? '';
            })
            .where((name) => name.isNotEmpty)
            .cast<String>()
            .toList();
      });
      
      print('📋 Loaded ${fooditems.length} categories: $fooditems');
    } catch (e) {
      print('❌ Error loading categories: $e');
      // Fallback to default categories if loading fails
      setState(() {
        fooditems = ['Pizza', 'Hamburger', 'Salad', 'Ice Cream'];
      });
    }
  }

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        // For web, get bytes
        selectedImageBytes = await image.readAsBytes();
        selectedImage = null;
      } else {
        // For mobile, get file
        selectedImage = File(image.path);
        selectedImageBytes = null;
      }
      setState(() {});
    }
  }

  Future<String> imageToBase64() async {
    try {
      if (kIsWeb && selectedImageBytes != null) {
        print(
          'Converting web image to base64, size: ${selectedImageBytes!.length}',
        );
        return base64Encode(selectedImageBytes!);
      } else if (selectedImage != null) {
        print('Converting mobile image to base64');
        List<int> bytes = await selectedImage!.readAsBytes();
        print('Mobile image size: ${bytes.length}');
        return base64Encode(bytes);
      }
      print('No image selected for base64 conversion');
      return "";
    } catch (e) {
      print('Error converting image to base64: $e');
      return "";
    }
  }

  uploadItem() async {
    if ((selectedImage != null || selectedImageBytes != null) &&
        namecontroller.text != "" &&
        pricecontroller.text != "" &&
        detailcontroller.text != "") {
      setState(() {
        isUploading = true; // Show loading
      });

      String downloadUrl = "";

      try {
        print('Starting image processing...'); // Debug print

        // Use base64 encoding instead of Firebase Storage to avoid CORS
        String base64Image = await imageToBase64();
        if (base64Image.isNotEmpty) {
          downloadUrl = "data:image/jpeg;base64,$base64Image";
          print('Image converted to base64 successfully'); // Debug print
        } else {
          // Fallback to placeholder if base64 conversion fails
          downloadUrl =
              "https://via.placeholder.com/300x200.png?text=${namecontroller.text}";
          print('Using placeholder image'); // Debug print
        }

        print(
          'Saving food item with image: ${downloadUrl.substring(0, 50)}...',
        ); // Debug print

        Map<String, dynamic> addItem = {
          "Image": downloadUrl,
          "Name": namecontroller.text,
          "Price": pricecontroller.text,
          "Detail": detailcontroller.text,
          "Category": value ?? "Pizza", // Use selected category
          "createdAt": FieldValue.serverTimestamp(), // Add timestamp
        };

        await DatabaseMethods()
            .addFoodItem(addItem, value!)
            .then((value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: Text(
                    "Thêm sản phẩm thành công!",
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
              );

              // Clear form after successful upload
              namecontroller.clear();
              pricecontroller.clear();
              detailcontroller.clear();
              setState(() {
                selectedImage = null;
                selectedImageBytes = null;
                isUploading = false; // Hide loading
              });

              // Return to product management page
              Navigator.pop(context, true);
            })
            .catchError((error) {
              print('❌ Error in addFoodItem: $error');
              setState(() {
                isUploading = false; // Hide loading
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.red,
                  content: Text(
                    "Lỗi khi thêm sản phẩm: $error",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ),
              );
            });
      } catch (e) {
        print('Upload error: $e');
        setState(() {
          isUploading = false; // Hide loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Failed to process image: ${e.toString()}",
              style: TextStyle(fontSize: 16.0),
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "Please fill all fields and select an image",
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Color(0xFF373866),
          ),
        ),
        centerTitle: true,
        title: Text(
          "Add Item",
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 600 ? 24.0 : 20.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: 50.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Upload the Item Picture",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              SizedBox(height: 20.0),
              (selectedImage == null && selectedImageBytes == null)
                  ? GestureDetector(
                      onTap: () {
                        getImage();
                      },
                      child: Center(
                        child: Material(
                          elevation: 4.0,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: MediaQuery.of(context).size.width > 600
                                ? 200
                                : 150,
                            height: MediaQuery.of(context).size.width > 600
                                ? 200
                                : 150,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: MediaQuery.of(context).size.width > 600
                              ? 200
                              : 150,
                          height: MediaQuery.of(context).size.width > 600
                              ? 200
                              : 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black, width: 1.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: kIsWeb && selectedImageBytes != null
                                ? Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : selectedImage != null
                                ? Image.file(selectedImage!, fit: BoxFit.cover)
                                : Container(),
                          ),
                        ),
                      ),
                    ),
              SizedBox(height: 30.0),
              Text("Item Name", style: AppWidget.semiBoldTextFeildStyle()),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: namecontroller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Item Name",
                    hintStyle: AppWidget.LightTextFeildStyle(),
                  ),
                ),
              ),
              SizedBox(height: 30.0),
              Text("Item Price", style: AppWidget.semiBoldTextFeildStyle()),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: pricecontroller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Item Price",
                    hintStyle: AppWidget.LightTextFeildStyle(),
                  ),
                ),
              ),
              SizedBox(height: 30.0),
              Text("Item Detail", style: AppWidget.semiBoldTextFeildStyle()),
              SizedBox(height: 10.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  maxLines: 6,
                  controller: detailcontroller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Enter Item Detail",
                    hintStyle: AppWidget.LightTextFeildStyle(),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                "Select Category",
                style: AppWidget.semiBoldTextFeildStyle(),
              ),
              SizedBox(height: 20.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Color(0xFFececf8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: fooditems.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Row(
                            children: [
                              SizedBox(width: 16.0),
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey[600]!,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.0),
                              Text(
                                "Đang tải danh mục...",
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : DropdownButton<String>(
                          items: fooditems
                              .map(
                                (item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: TextStyle(
                                      fontSize: 18.0,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: ((value) => setState(() {
                            this.value = value;
                          })),
                          dropdownColor: Colors.white,
                          hint: Text("Chọn danh mục"),
                          iconSize: 36,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                          value: value,
                        ),
                ),
              ),
              SizedBox(height: 30.0),
              GestureDetector(
                onTap: isUploading
                    ? null
                    : () {
                        uploadItem();
                      },
                child: Center(
                  child: Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      width: 150,
                      decoration: BoxDecoration(
                        color: isUploading ? Colors.grey : Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: isUploading
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
                                "Add",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
