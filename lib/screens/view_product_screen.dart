import 'package:flutter/material.dart';
import 'package:plant_feed/model/product_model.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:plant_feed/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import your BasketSummaryScreen (if it isn't already)
import 'package:plant_feed/screens/basket_summary_screen.dart';

class ViewProductScreen extends StatefulWidget {
  final int productId; // Pass only the product ID

  const ViewProductScreen({Key? key, required this.productId}) : super(key: key);

  @override
  ViewProductScreenState createState() => ViewProductScreenState();
}

class ViewProductScreenState extends State<ViewProductScreen> {
  final ApiService apiService = ApiService();
  bool isLoading = true;
  Product? product; // Nullable Product instance

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  // Fetch the product details (including reviews, if any)
  Future<void> fetchData() async {
    try {
      product = await apiService.fetchProductDetails(widget.productId);
    } catch (error) {
      debugPrint('Error fetching product details: $error');
      setState(() {
        product = null; // On error, ensure product is null
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Get the user ID from SharedPreferences (must match how you stored it after login)
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ID'); 
  }

  // Add this product to the basket (quantity = 1 by default)
  Future<void> _addToBasket() async {
    final userId = await _getUserId();
    if (userId == null) {
      // Show an error if the user is not logged in (no user ID in SharedPreferences)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please log in.')),
        );
      }
      return;
    }

    try {
      // Calls your "addToBasket" endpoint from ApiService
      await apiService.addToBasket(userId, widget.productId, 1);

      if (mounted) {
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product?.productName} added to basket!')),
        );
      }
    } catch (e) {
      debugPrint('Failed to add to basket: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product to basket: $e')),
        );
      }
    }
  }

  // "Buy now" = add (or increment) in the basket, then navigate to summary
  Future<void> _buyNow() async {
    final userId = await _getUserId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please log in.')),
        );
      }
      return;
    }

    try {
      // Calls your "buyNow" endpoint from ApiService
      // which increments qty if the product is already in the basket.
      await apiService.buyNow(userId, widget.productId, 1);

      // On success, navigate to your Basket Summary screen
      // (Replace BasketSummaryScreen() with your actual import)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BasketSummaryScreen()),
        );
      }
    } catch (e) {
      debugPrint('Failed to process purchase: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process purchase: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product != null ? product!.productName : 'Loading...'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
              ? const Center(child: Text('Failed to load product'))
              : buildProductDetails(),
    );
  }

  // Helper: Resolves relative vs. absolute image URLs
  String _getFullImageUrl(String? relativeUrl) {
    if (relativeUrl != null && !relativeUrl.startsWith('http')) {
      return '${Config.apiUrl}$relativeUrl';
    }
    return relativeUrl ?? '';
  }

  // Build the full product details layout
  Widget buildProductDetails() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: _getFullImageUrl(product!.productPhoto),
                height: 250,
                width: double.infinity,
                fit: BoxFit.contain,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image, size: 100, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // Product Name
            Text(
              product!.productName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Product Description
            Text(
              product!.productDesc,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Product Price + Stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RM ${product!.productPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${product!.productStock} left in stock',
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Product Category
            Text(
              'Category: ${product!.productCategory}',
              style: const TextStyle(fontSize: 16, color: Colors.blueGrey),
            ),
            const SizedBox(height: 16),

            // Buttons: Add to Basket / Buy Now
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: _addToBasket,
                  child: const Text('Add to Basket'),
                ),
                ElevatedButton(
                  onPressed: _buyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Buy Now'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Seller Information
            const Text(
              'Seller Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(_getFullImageUrl(product!.seller.photo)),
                radius: 30,
                backgroundColor: Colors.transparent,
              ),
              title: Text(
                'Seller: ${product!.seller.username}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Email: ${product!.seller.email}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Reviews Section
            const Text(
              'Customer Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            product!.reviews.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: product!.reviews.length,
                    itemBuilder: (context, index) {
                      final review = product!.reviews[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.only(bottom: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Reviewer info
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage:
                                        NetworkImage(_getFullImageUrl(review.reviewer.photo)),
                                    radius: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    review.reviewer.username,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Text(
                                    review.date,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Review content
                              Text(
                                review.content,
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Text(
                    'No reviews yet.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
          ],
        ),
      ),
    );
  }
}
