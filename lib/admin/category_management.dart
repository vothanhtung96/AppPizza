import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

class CategoryManagement extends StatefulWidget {
  const CategoryManagement({super.key});

  @override
  State<CategoryManagement> createState() => _CategoryManagementState();
}

class _CategoryManagementState extends State<CategoryManagement> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  Uint8List? selectedImageBytes;
  bool isUploading = false;

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

  Future<void> _addCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "Vui lòng nhập tên danh mục",
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      );
      return;
    }

    if (selectedImage == null && selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            "Vui lòng chọn hình ảnh cho danh mục",
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      print('Starting image processing...');

      // Use base64 encoding instead of Firebase Storage to avoid CORS
      String base64Image = await imageToBase64();
      String downloadUrl = "";

      if (base64Image.isNotEmpty) {
        downloadUrl = "data:image/jpeg;base64,$base64Image";
        print('Image converted to base64 successfully');
      } else {
        // Fallback to placeholder if base64 conversion fails
        downloadUrl =
            "https://via.placeholder.com/300x200.png?text=${_nameController.text}";
        print('Using placeholder image');
      }

      print('Saving category with image: ${downloadUrl.substring(0, 50)}...');

      Map<String, dynamic> categoryData = {
        "Image": downloadUrl,
        "Name": _nameController.text.trim(),
        "name": _nameController.text.trim(), // Thêm field name để tương thích
        "icon": "custom", // Thêm field icon để tương thích
        "iconImage": downloadUrl, // Thêm field iconImage để tương thích
        "createdAt": FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('Categories')
          .add(categoryData);

      print('✅ Category added successfully');

      // Clear form after successful upload
      _nameController.clear();
      setState(() {
        selectedImage = null;
        selectedImageBytes = null;
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Thêm danh mục thành công!",
            style: TextStyle(fontSize: 18.0),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error adding category: $e');
      setState(() {
        isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Lỗi khi thêm danh mục: $e",
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      );
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('Categories')
          .doc(categoryId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Danh mục đã được xóa thành công!'),
        ),
      );
    } catch (e) {
      print('Error deleting category: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Lỗi khi xóa danh mục: $e'),
        ),
      );
    }
  }

  void _editCategory(Map<String, dynamic> categoryData, String categoryId) {
    _nameController.text = categoryData['name'] ?? categoryData['Name'] ?? '';
    // Reset image selection
    selectedImage = null;
    selectedImageBytes = null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Chỉnh sửa danh mục',
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
                // Category Name
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên danh mục',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(FontAwesomeIcons.tag),
                  ),
                ),
                SizedBox(height: 20),

                // Current Image
                if (categoryData['Image'] != null ||
                    categoryData['iconImage'] != null)
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
                              categoryData['Image'] ??
                                  categoryData['iconImage'],
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
                _nameController.clear();
                selectedImage = null;
                selectedImageBytes = null;
              },
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateCategory(categoryId);
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

  Future<void> _updateCategory(String categoryId) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text("Vui lòng nhập tên danh mục"),
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
        "name": _nameController.text.trim(),
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
        updateData["iconImage"] = downloadUrl;
      }

      await FirebaseFirestore.instance
          .collection('Categories')
          .doc(categoryId)
          .update(updateData);

      print('✅ Category updated successfully');

      // Clear form
      _nameController.clear();
      setState(() {
        selectedImage = null;
        selectedImageBytes = null;
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "Cập nhật danh mục thành công!",
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      );
    } catch (e) {
      print('❌ Error updating category: $e');
      setState(() {
        isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            "Lỗi khi cập nhật danh mục: $e",
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Quản lý danh mục',
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
              // Form Section
              Container(
                padding: EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Thêm danh mục mới",
                      style: TextStyle(
                        fontSize: isTablet ? 24.0 : 20.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Category Name
                    Text(
                      "Tên danh mục",
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: "Nhập tên danh mục...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(FontAwesomeIcons.tag),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Image Upload
                    Text(
                      "Hình ảnh danh mục",
                      style: TextStyle(
                        fontSize: isTablet ? 18.0 : 16.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 10),

                    // Image Selection Button
                    GestureDetector(
                      onTap: getImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child:
                            (selectedImage != null ||
                                selectedImageBytes != null)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb
                                    ? Image.memory(
                                        selectedImageBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.upload,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Chọn hình ảnh",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Nhấn để chọn hình ảnh từ thư viện",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isUploading ? null : _addCategory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isUploading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Đang thêm...",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                            : Text(
                                "Thêm danh mục",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Categories List Section
              Text(
                "Danh sách danh mục",
                style: TextStyle(
                  fontSize: isTablet ? 20.0 : 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),

              // Categories List
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Categories')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            FontAwesomeIcons.folderOpen,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Chưa có danh mục nào',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var category = snapshot.data!.docs[index];
                      var data = category.data() as Map<String, dynamic>;

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
                              child: _buildCategoryImage(data['Image'] ?? data['iconImage']),
                            ),
                          ),
                          title: Text(
                            data['Name'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'ID: ${category.id.substring(0, 8)}...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  FontAwesomeIcons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _editCategory(data, category.id),
                              ),
                              IconButton(
                                icon: Icon(
                                  FontAwesomeIcons.trash,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteCategory(category.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: Icon(
          FontAwesomeIcons.image,
          color: Colors.grey[600],
        ),
      );
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        String base64String = imageUrl.split(',')[1];
        return Image.memory(
          base64Decode(base64String),
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
        );
      } catch (e) {
        return Container(
          color: Colors.grey[300],
          child: Icon(
            FontAwesomeIcons.image,
            color: Colors.grey[600],
          ),
        );
      }
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
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
      );
    } else {
      return Container(
        color: Colors.grey[300],
        child: Icon(
          FontAwesomeIcons.image,
          color: Colors.grey[600],
        ),
      );
    }
  }
}
