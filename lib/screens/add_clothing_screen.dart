import 'package:flutter/material.dart';

class AddClothingScreen extends StatelessWidget {
  const AddClothingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Clothing'),
      ),
      body: const Center(
        child: Text('Add clothing here'),
      ),
    );
  }
}