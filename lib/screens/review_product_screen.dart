// lib/screens/review_product_screen.dart

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/order_model.dart'; // ensures only 1 'Order' definition

class ReviewProductScreen extends StatefulWidget {
  final int userId;
  final int basketId;
  final List<Order> groupOrders;

  const ReviewProductScreen({
    Key? key,
    required this.userId,
    required this.basketId,
    required this.groupOrders,
  }) : super(key: key);

  @override
  _ReviewProductScreenState createState() => _ReviewProductScreenState();
}

class _ReviewProductScreenState extends State<ReviewProductScreen> {
  final ApiService _apiService = ApiService();
  bool _isSubmitting = false;

  // A text controller for each product ID
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // create text controllers for each product
    for (final order in widget.groupOrders) {
      final productId = order.item.product.productId;
      _controllers[productId] = TextEditingController();
    }
  }

  Future<void> _submitReviews() async {
    // build JSON: { "review_<productId>": "User text", ... }
    final Map<String, String> requestData = {};

    for (final order in widget.groupOrders) {
      final productId = order.item.product.productId;
      final text = _controllers[productId]?.text.trim() ?? "";
      if (text.isNotEmpty) {
        requestData["review_$productId"] = text;
      }
    }

    if (requestData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No reviews to submit.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiService.reviewProduct(
        userId: widget.userId,
        basketId: widget.basketId,
        requestData: requestData,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reviews submitted successfully!')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit reviews: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groupOrders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Products')),
        body: const Center(child: Text('No products found to review.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review Products')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please write your reviews for each product:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // For each product in the group...
            for (final order in widget.groupOrders) ...[
              _buildProductReviewField(order),
              const SizedBox(height: 24),
            ],

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReviews,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                  : const Text('Submit Reviews'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductReviewField(Order order) {
    final product = order.item.product;
    final productId = product.productId;
    final controller = _controllers[productId]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Photo
        if (product.productPhoto != null && product.productPhoto!.isNotEmpty) ...[
          SizedBox(
            height: 160,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.productPhoto!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Product Name
        Text(
          product.productName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),

        // Product Price + Category
        Text(
          "RM ${product.productPrice.toStringAsFixed(2)} - ${product.productCategory}",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),

        // Product Description
        if (product.productDesc.isNotEmpty) Text(product.productDesc),

        const SizedBox(height: 12),

        // Review TextField
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: "Review for ${product.productName}...",
          ),
        ),
      ],
    );
  }
}
