import 'package:flutter/material.dart';
import '../models/clothing_item.dart';
import 'add_clothing_screen.dart';
import '../widget/graph_paper_background.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  final items = [
      ClothingItem(
        id: "1",
        name: "Baggy Pants Gray",
        category: "Pants",
        color: "Gray",
      ),
      ClothingItem(
        id: "2",
        name: "Compression Shirt Black",
        category: "Top",
        color: "Black",
      ),
      ClothingItem(
        id: "3",
        name: "White Sneakers",
        category: "Shoes",
        color: "White",
      ),
    ];
    int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: const Text('My wardrobe'),
        actions: [
          IconButton(
            onPressed: () {
            Navigator.push(
             context,
                MaterialPageRoute(
                  builder: (context) => const AddClothingScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),

      body: GraphPaperBackground(
      child: ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

      return Card(
        margin: const EdgeInsets.all(8),
        elevation: 5,
        
        color: selectedIndex == index ? Color.fromARGB(188, 189, 164, 233) : null,
        shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        
),
        child: ListTile(
          leading: const Icon(Icons.checkroom),
          title: Text(item.name),
          subtitle: Text('${item.category} • ${item.color}'),
          onTap: () {
          setState(() {
          selectedIndex = index;
        });
            
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Color.fromARGB(234, 146, 94, 235),
              content: Text(item.name),
            ),
          );
},
        )
        );
      },
    ),
  ),
    );
  }
}