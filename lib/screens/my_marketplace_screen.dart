// lib/screens/my_marketplace_screen.dart

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/providers/user_model_provider.dart';
import 'package:provider/provider.dart';
import 'package:plant_feed/model/product_model.dart';
//import 'package:cached_network_image/cached_network_image.dart';
import 'package:plant_feed/screens/update_product_screen.dart';
import 'view_product_screen.dart';
import 'order_list_screen.dart';
import 'add_product_screen.dart';

class MyMarketplaceScreen extends StatefulWidget {
  final int sellerId;
  const MyMarketplaceScreen({Key? key, required this.sellerId})
      : super(key: key);

  @override
  _MyMarketplaceScreenState createState() => _MyMarketplaceScreenState();
}

class _MyMarketplaceScreenState extends State<MyMarketplaceScreen> {
  final ApiService apiService = ApiService();
  late Future<List<Product>> _futureProducts;
  Map<String, dynamic> _shopAnalytics = {}; // For analytics data

  @override
  void initState() {
    super.initState();
    _fetchProductsAndAnalytics();
    _futureProducts = apiService.fetchSellerProducts(widget.sellerId);
  }

  void _fetchProductsAndAnalytics() {
    final sellerId = widget.sellerId; // Use passed sellerId
    setState(() {
      _futureProducts = apiService.fetchSellerProducts(sellerId);
      _fetchShopAnalytics(sellerId);
    });
  }

  Future<void> _fetchShopAnalytics(int sellerId) async {
    try {
      final analytics = await apiService.fetchSellerAnalytics(sellerId);
      setState(() {
        _shopAnalytics = analytics;
      });
    } catch (error) {
      debugPrint('Error fetching analytics: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserHeader(),
            const SizedBox(height: 10),
            _buildShopAnalytics(),
            const SizedBox(height: 10),
            // Expanded ListView for Products
            Expanded(
              child: _buildProductsSection(),
            ),
          ],
        ),
      ),
    );
  }

  // User Header Widget with Buttons
  Widget _buildUserHeader() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // User Profile and Location
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: userProvider.getUser?.photo != null &&
                      userProvider.getUser!.photo.isNotEmpty
                  ? NetworkImage(
                      "${apiService.url}${userProvider.getUser?.photo}")
                  : const AssetImage(
                          'assets/images/placeholder_image.png')
                      as ImageProvider,
              radius: 25, // Reduced radius for smaller display
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProvider.getUser?.name ?? 'User Name',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Location: ${userProvider.getUser?.state ?? 'Unknown'}",
                  style:
                      const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Buttons in Center
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final userId = userProvider.getUser?.id;

                debugPrint(
                    "Navigating to SellHistoryScreen for User ID: $userId");

                if (userId != null) {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderListScreen(sellerId: userId),
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("User ID is missing!")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              label: const Text("Orders",
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddProductScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Sell Product",
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        )
      ],
    );
  }

  // Shop Analytics Section
  Widget _buildShopAnalytics() {
    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            const Text(
              "Shop Analytics",
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 3,
              ),
              children: [
                _analyticsCard("Gross Income",
                    "RM ${_shopAnalytics['gross_income'] ?? '0'}"),
                _analyticsCard("Products Sold",
                    "${_shopAnalytics['total_sales'] ?? '0'}"),
                _analyticsCard("Products in Shop",
                    "${_shopAnalytics['product_in_shop'] ?? '0'}"),
                _analyticsCard("Total Orders",
                    "${_shopAnalytics['total_orders'] ?? '0'}"),
                _analyticsCard("Most Popular Product",
                    "${_shopAnalytics['most_popular_product'] ?? 'N/A'}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _analyticsCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Product Section
  Widget _buildProductsSection() {
    return FutureBuilder<List<Product>>(
      future: _futureProducts,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text('Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red)));
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products found.'));
        } else {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final product = snapshot.data![index];
              return ProductCard(
                product: product,
                apiService: apiService,
                onDelete: _fetchProductsAndAnalytics,
              );
            },
          );
        }
      },
    );
  }
}

// Product Card Widget - Adjusted for smaller display and fixed overflow
class ProductCard extends StatelessWidget {
  final Product product;
  final ApiService apiService;
  final VoidCallback onDelete;

  const ProductCard({
    Key? key,
    required this.product,
    required this.apiService,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          SizedBox(
            height: 120, // Reduced height for smaller display
            width: double.infinity,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              child: Image.network(
                product.productPhoto ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child:
                        const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Product Details
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProductScreen(
                            productId: product.productId),
                      ),
                    );
                  },
                  child: Text(
                    product.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 4),
                // Product Price
                Text(
                  'Price: RM ${product.productPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.green),
                ),
                const SizedBox(height: 8),
                // Edit and Delete Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Edit Button
                    OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UpdateProductScreen(product: product),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        side: const BorderSide(
                            color: Colors.blue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.blue,
                      ),
                    ),
                    // Delete Button
                    OutlinedButton(
                      onPressed: () async {
                        final confirmation = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Product'),
                            content: const Text(
                                'Are you sure you want to delete this product?'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmation == true) {
                          final success = await apiService.deleteProduct(
                              product.productId);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Product deleted successfully')),
                            );
                            onDelete(); // Refresh product list
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Failed to delete product')),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        side: const BorderSide(
                            color: Colors.red, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
