// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Uncommented
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/product_model.dart';

class UpdateProductScreen extends StatefulWidget {
  final Product product;

  const UpdateProductScreen({Key? key, required this.product})
      : super(key: key);

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
    'Fertiliser',
    'Tools',
    'Others'
  ];

  String? _selectedCategory;

  // Getter for baseUrl
  String get baseUrl {
    return _productService.url.endsWith('/')
        ? _productService.url
        : '${_productService.url}/';
  }

  // Getter for fullImageUrl
  String get fullImageUrl {
    if (widget.product.productPhoto != null &&
        widget.product.productPhoto!.startsWith('http')) {
      // If productPhoto is already a full URL
      return widget.product.productPhoto!;
    } else {
      // Otherwise, construct it using baseUrl
      return '${baseUrl}${widget.product.productPhoto}';
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.product.productName;
    _descController.text = widget.product.productDesc;
    _selectedCategory = widget.product.productCategory;
    print("Selected Category: $_selectedCategory"); // Debugging line

    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = 'None Selected'; // Default to a safe value
    }
    _priceController.text = widget.product.productPrice.toString();
    _stockController.text = widget.product.productStock.toString();

    // Debugging: Print the full image URL
    print("Full Image URL: $fullImageUrl");
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
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
          SnackBar(
              content: Text(
                  "Product name already exists. Please choose a different name.")),
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
          SnackBar(content: Text("Product updated successfully")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update product")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        Colors.green; // Match MyMarketplace_screen colors

    return Scaffold(
      appBar: AppBar(
        title: Text("Update Product"),
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
                Text(
                  "Edit Product Details",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: "Product Name"),
                  onChanged: (value) {
                    _checkNameDuplicate(value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a product name";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _descController,
                  decoration: InputDecoration(
                    labelText: "Product Description",
                    border: OutlineInputBorder(),
                  ),
                  minLines: 3, // Minimum height for the text area
                  maxLines: 5, // Maximum expandable height
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter a product description";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Category",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value == 'None Selected') {
                      return "Please select a category";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                _buildTextField("Product Price", _priceController, true,
                    keyboardType: TextInputType.number),
                SizedBox(height: 10),
                _buildTextField("Stock Available", _stockController, true,
                    keyboardType: TextInputType.number),
                SizedBox(height: 16),
                Text(
                  "Attach Photo",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton(
                      onPressed: _pickImage,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white, // White background
                        side: BorderSide(color: Colors.black), // Black border
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              8), // Optional rounded corners
                        ),
                        padding: EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16), // Adjust padding
                      ),
                      child: Text(
                        "Choose Photo",
                        style: TextStyle(
                          color: Colors.black, // Black text color
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Center(
                      // Center the "Current Photo" label and image
                      child: Column(
                        children: [
                          Text(
                            "Current Photo",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          SizedBox(height: 10),
                          _buildImagePreview(), // Center the larger image preview
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    minimumSize: Size(double.infinity,
                        50), // Make button width fill the page and height 50
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8), // Optional rounded corners
                    ),
                  ),
                  child: Text(
                    "Update",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey),
                    minimumSize: Size(double.infinity,
                        50), // Make button width fill the page and height 50
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8), // Optional rounded corners
                    ),
                  ),
                  child: Text(
                    "Return to Shop",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, bool isRequired,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return "Please enter $label";
              }
              return null;
            }
          : null,
      onChanged: (value) {
        if (label == "Product Name") {
          _checkNameDuplicate(value);
        }
      },
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
          SnackBar(
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
      borderRadius: BorderRadius.circular(10), // Rounded corners
      child: SizedBox(
        height: 200, // Fixed height
        width: 200, // Fixed width
        child: _selectedImage != null
            ? Image.file(
                _selectedImage!,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
              )
            : (widget.product.productPhoto != null &&
                    widget.product.productPhoto!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: fullImageUrl,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) {
                      print("Error loading image: $error"); // Debugging line
                      return Container(
                        color: Colors.grey[300],
                        child:
                            Icon(Icons.broken_image, size: 50, color: Colors.red),
                      );
                    },
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
