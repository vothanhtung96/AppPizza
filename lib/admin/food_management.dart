import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

class FoodManagement extends StatefulWidget {
  const FoodManagement({super.key});

  @override
  State<FoodManagement> createState() => _FoodManagementState();
}

class _FoodManagementState extends State<FoodManagement> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Uint8List? selectedImageBytes;
  bool isUploading = false;
  List<String> availableCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Categories')
          .get();

      setState(() {
        availableCategories = snapshot.docs
            .map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return data['Name'] ?? data['name'] ?? '';
            })
            .where((name) => name.isNotEmpty)
            .cast<String>()
            .toList();
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future getImage() async {
    var image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      if (kIsWeb) {
        selectedImageBytes = await image.readAsBytes();
        selectedImage = null;
      } else {
        selectedImage = File(image.path);
        selectedImageBytes = null;
      }
      setState(() {});
    }
  }

  Future<String> imageToBase64() async {
    try {
      if (kIsWeb && selectedImageBytes != null) {
        return base64Encode(selectedImageBytes!);
      } else if (selectedImage != null) {
        List<int> bytes = await selectedImage!.readAsBytes();
        return base64Encode(bytes);
      }
      return "";
    } catch (e) {
      print('Error converting image to base64: $e');
      return "";
    }
  }

  void _editFood(Map<String, dynamic> foodData, String foodId) {
    _nameController.text = foodData['Name'] ?? '';
    _priceController.text = (foodData['Price'] ?? 0).toString();
    _detailController.text = foodData['Detail'] ?? '';
    _categoryController.text = foodData['Category'] ?? '';

    // Reset image selection
    selectedImage = null;
    selectedImageBytes = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Chỉnh sửa sản phẩm',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Food Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên sản phẩm',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(FontAwesomeIcons.utensils),
                  ),
                ),
                SizedBox(height: 16),

                // Price
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Giá (\$)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(FontAwesomeIcons.dollarSign),
                  ),
                ),
                SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _categoryController.text.isNotEmpty
                      ? _categoryController.text
                      : null,
                  decoration: InputDecoration(
                    labelText: 'Danh mục',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(FontAwesomeIcons.tag),
                  ),
                  items: availableCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    _categoryController.text = value ?? '';
                  },
                ),
                SizedBox(height: 16),

                // Detail
                TextField(
                  controller: _detailController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(FontAwesomeIcons.info),
                  ),
                ),
                SizedBox(height: 20),

                // Current Image
                if (foodData['Image'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hình ảnh hiện tại:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Container(
                          height: 100,
                          width: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              foodData['Image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    FontAwesomeIcons.image,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),

                // New Image Upload
                Text(
                  'Hình ảnh mới (tùy chọn):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: getImage,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: (selectedImage != null || selectedImageBytes != null)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: kIsWeb
                                ? Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(selectedImage!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                FontAwesomeIcons.upload,
                                size: 30,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Chọn hình ảnh mới",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearForm();
              },
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateFood(foodId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateFood(String foodId) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Vui lòng nhập tên sản phẩm"),
        ),
      );
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Vui lòng nhập giá sản phẩm"),
        ),
      );
      return;
    }

    if (_categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Vui lòng chọn danh mục"),
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      Map<String, dynamic> updateData = {
        "Name": _nameController.text.trim(),
        "Price": double.tryParse(_priceController.text.trim()) ?? 0.0,
        "Detail": _detailController.text.trim(),
        "Category": _categoryController.text.trim(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      // If new image is selected, update it
      if (selectedImage != null || selectedImageBytes != null) {
        String base64Image = await imageToBase64();
        String downloadUrl = "";

        if (base64Image.isNotEmpty) {
          downloadUrl = "data:image/jpeg;base64,$base64Image";
        }

        updateData["Image"] = downloadUrl;
      }

      await FirebaseFirestore.instance
          .collection('FoodItems')
          .doc(foodId)
          .update(updateData);

      print('✅ Food item updated successfully');

      _clearForm();
      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Cập nhật sản phẩm thành công!",
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error updating food item: $e');
      setState(() {
        isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Lỗi khi cập nhật sản phẩm: $e",
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      );
    }
  }

  Future<void> _deleteFood(String foodId) async {
    try {
      await FirebaseFirestore.instance
          .collection('FoodItems')
          .doc(foodId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Sản phẩm đã được xóa thành công!'),
        ),
      );
    } catch (e) {
      print('Error deleting food item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi xóa sản phẩm: $e'),
        ),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _detailController.clear();
    _categoryController.clear();
    selectedImage = null;
    selectedImageBytes = null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Quản lý sản phẩm',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        margin: EdgeInsets.all(20.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('FoodItems')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FontAwesomeIcons.utensils,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Chưa có sản phẩm nào',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var foodDoc = snapshot.data!.docs[index];
                var foodData = foodDoc.data() as Map<String, dynamic>;

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: foodData['Image'] != null
                            ? Image.network(
                                foodData['Image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: Icon(
                                      FontAwesomeIcons.utensils,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: Icon(
                                  FontAwesomeIcons.utensils,
                                  color: Colors.grey[600],
                                ),
                              ),
                      ),
                    ),
                    title: Text(
                      foodData['Name'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giá: \$${foodData['Price'] ?? '0'}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Danh mục: ${foodData['Category'] ?? 'N/A'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (foodData['Detail'] != null &&
                            (foodData['Detail'] ?? '').toString().isNotEmpty)
                          Text(
                            'Mô tả: ${foodData['Detail']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(FontAwesomeIcons.edit, color: Colors.blue),
                          onPressed: () => _editFood(foodData, foodDoc.id),
                        ),
                        IconButton(
                          icon: Icon(FontAwesomeIcons.trash, color: Colors.red),
                          onPressed: () => _deleteFood(foodDoc.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
