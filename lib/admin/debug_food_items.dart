import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugFoodItems extends StatefulWidget {
  const DebugFoodItems({super.key});

  @override
  State<DebugFoodItems> createState() => _DebugFoodItemsState();
}

class _DebugFoodItemsState extends State<DebugFoodItems> {
  List<Map<String, dynamic>> foodItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
  }

  Future<void> _loadFoodItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('FoodItems')
          .get();
      
      setState(() {
        foodItems = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
        isLoading = false;
      });
      
      print('📋 Found ${foodItems.length} food items');
      for (var item in foodItems) {
        print('🍽️ ${item['Name']} - Category: ${item['Category']} - ID: ${item['id']}');
      }
    } catch (e) {
      print('❌ Error loading food items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Food Items'),
        backgroundColor: Colors.red,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: foodItems.length,
              itemBuilder: (context, index) {
                var item = foodItems[index];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(item['Name'] ?? 'No Name'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category: ${item['Category'] ?? 'No Category'}'),
                        Text('Price: \$${item['Price'] ?? '0'}'),
                        Text('ID: ${item['id']}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () => _updateCategory(item['id'], item['Category'] ?? ''),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _updateCategory(String itemId, String currentCategory) {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController(text: currentCategory);
        return AlertDialog(
          title: Text('Update Category'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter category name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('FoodItems')
                      .doc(itemId)
                      .update({'Category': controller.text.trim()});
                  Navigator.pop(context);
                  _loadFoodItems(); // Reload data
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category updated successfully!')),
                  );
                } catch (e) {
                  print('❌ Error updating category: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating category: $e')),
                  );
                }
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }
} 