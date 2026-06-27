// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/product_model.dart';

class UpdateProductScreen extends StatefulWidget {
  final Product product;

  const UpdateProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _UpdateProductScreenState createState() => _UpdateProductScreenState();
}

class _UpdateProductScreenState extends State<UpdateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ApiService();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'None Selected',
    'Fruit',
    'Seed',
    'Pest Control',
    'Sapling',
    'Fertiliser',
    'Tool',
    'Plant',
    'Others',
  ];

  String? _selectedCategory;

  String get fullImageUrl {
    if (widget.product.productPhoto != null &&
        widget.product.productPhoto!.startsWith('http')) {
      return widget.product.productPhoto!;
    }
    return '${_productService.url}${widget.product.productPhoto}';
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.productName;
    _descController.text = widget.product.productDesc;

    _selectedCategory = widget.product.productCategory;
    // Normalize old mismatched category names
    if (_selectedCategory == 'Tools') _selectedCategory = 'Tool';
    if (_selectedCategory == 'Fertilizer') _selectedCategory = 'Fertiliser';
    if (!_categories.contains(_selectedCategory)) _selectedCategory = 'None Selected';

    _priceController.text = widget.product.productPrice.toStringAsFixed(2);
    _stockController.text = widget.product.productStock.toString();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      final productName = _nameController.text;

      final isDuplicate = await _productService.isProductNameDuplicate(
        productName,
        widget.product.productId,
      );

      if (isDuplicate && productName != widget.product.productName) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Product name already exists. Please choose a different name.")),
        );
        return;
      }

      final data = {
        "product_name": productName,
        "product_desc": _descController.text,
        "product_category": _selectedCategory ?? "None Selected",
        "product_price": _priceController.text,
        "product_stock": _stockController.text,
      };

      final success = await _productService.updateProduct(
        widget.product.productId,
        data,
        _selectedImage,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product updated successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update product")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Product"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Edit Product Details",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Product Name"),
                  onChanged: _checkNameDuplicate,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter a product name"
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: "Product Description",
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3,
                  maxLines: 5,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter a product description"
                      : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() => _selectedCategory = newValue!);
                  },
                  decoration: const InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value == 'None Selected'
                          ? "Please select a category"
                          : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: "Product Price",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [BankPriceFormatter()],
                  validator: (value) =>
                      value == null || value.isEmpty || value == '0.00'
                          ? "Please enter Product Price"
                          : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: "Stock Available",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty
                      ? "Please enter Stock Available"
                      : null,
                ),
                const SizedBox(height: 16),
                const Text("Attach Photo",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor)),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                  ),
                  child: const Text("Choose Photo",
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      const Text("Current Photo",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor)),
                      const SizedBox(height: 10),
                      _buildImagePreview(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Update",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Return to Shop",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkNameDuplicate(String value) async {
    try {
      final isDuplicate = await _productService.isProductNameDuplicate(
        value,
        widget.product.productId,
      );
      if (isDuplicate && value != widget.product.productName) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product name is already taken."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error during duplicate check: $e");
    }
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 200,
        width: 200,
        child: _selectedImage != null
            ? Image.file(_selectedImage!,
                height: 200, width: 200, fit: BoxFit.cover)
            : (widget.product.productPhoto != null &&
                    widget.product.productPhoto!.isNotEmpty
                ? Image.network(
                    fullImageUrl,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image,
                          size: 50, color: Colors.red),
                    ),
                  )
                : Container(
                    height: 200,
                    width: 200,
                    color: Colors.grey[300],
                    child: const Center(child: Text("No Image")),
                  )),
      ),
    );
  }
}

class BankPriceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '0.00',
        selection: TextSelection.collapsed(offset: 4),
      );
    }
    digits = digits.replaceAll(RegExp(r'^0+'), '');
    if (digits.isEmpty) digits = '0';
    while (digits.length < 3) digits = '0$digits';
    String intPart = digits.substring(0, digits.length - 2);
    String decPart = digits.substring(digits.length - 2);
    intPart = intPart.replaceAll(RegExp(r'^0+'), '');
    if (intPart.isEmpty) intPart = '0';
    String result = '$intPart.$decPart';
    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}