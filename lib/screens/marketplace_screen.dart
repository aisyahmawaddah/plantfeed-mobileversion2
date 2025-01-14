// lib/screens/marketplace_screen.dart

import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/product_model.dart';
import 'package:plant_feed/screens/basket_summary_screen.dart';
import 'package:plant_feed/screens/order_history_screen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_feed/screens/my_marketplace_screen.dart';
import 'package:plant_feed/screens/view_product_screen.dart';
import 'package:plant_feed/providers/user_model_provider.dart';
import 'package:provider/provider.dart';


class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  MarketplaceScreenState createState() => MarketplaceScreenState();
}

class MarketplaceScreenState extends State<MarketplaceScreen> {
  late Future<List<Product>> futureProducts;
  final ApiService apiService = ApiService();
  int basketCount = 0; // Will display how many distinct items are in the basket

  @override
  void initState() {
    super.initState();
    // Fetch products for the marketplace
    futureProducts = apiService.fetchProducts();

    // Optionally load from SharedPreferences on startup (if you want to persist)
    loadBasketItems();

    // Or do an initial refresh from the backend to get the correct basket count
    refreshBasketCount();
  }

  // (Optional) Load basketCount from SharedPreferences
  Future<void> loadBasketItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      basketCount = prefs.getInt('basketCount') ?? 0;
    });
  }

  // (Optional) Save basketCount to SharedPreferences
  Future<void> saveBasketState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('basketCount', basketCount);
  }

  // This method calls your basket_summary endpoint via fetchBasketSummary()
  Future<void> refreshBasketCount() async {
    try {
      // Returns a list of basket items
      final basketList = await apiService.fetchBasketSummary();
      setState(() {
        basketCount = basketList.length; // distinct items in the basket
      });
      await saveBasketState(); // (Optional) persist in SharedPreferences
    } catch (e) {
      debugPrint('Error refreshing basket count: $e');
    }
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ID');
  }

  // Add an item to the basket, then refresh the count
  void addToBasket(Product product) async {
    final userId = await getUserId();
    if (userId != null) {
      try {
        // 1. Calls your existing "addToBasket" endpoint
        await apiService.addToBasket(userId, product.productId, 1);

        // 2. Refresh the basket count from the backend
        await refreshBasketCount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${product.productName} added to basket!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add product to basket: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please log in.')),
        );
      }
    }
  }

  // Buy now (adds item to basket on the backend), then refresh and navigate
  void buyNow(Product product) async {
    final userId = await getUserId();
    if (userId != null) {
      try {
        // 1. Calls your existing "buyNow" endpoint (which now increments quantity if it exists)
        await apiService.buyNow(userId, product.productId, 1);

        // 2. Refresh the basket count
        await refreshBasketCount();

        // 3. Navigate to basket summary
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BasketSummaryScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to process purchase: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please log in.')),
        );
      }
    }
  }

  void navigateToBasketSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BasketSummaryScreen()),
    );
  }

  void navigateToOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final sellerId = userProvider.getUser?.id ?? 0;  // Fetch seller ID

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.black,
            tabs: [
              Tab(text: 'Marketplace'), // Tab for Marketplace
              Tab(text: 'My Marketplace'), // Tab for My Marketplace
            ],
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert), // Three dots icon
            onSelected: (String choice) {
              if (choice == 'Basket') {
                navigateToBasketSummary();
              } else if (choice == 'Order History') {
                navigateToOrderHistory();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'Basket',
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.shopping_basket),
                        if (basketCount > 0)
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                              child: Text(
                                '$basketCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Text('Basket'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Order History',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Order History'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        children: [
          MarketplaceTab(
            apiService: apiService,
            addToBasket: addToBasket,
            buyNow: buyNow,
          ),
          MyMarketplaceScreen(sellerId: sellerId),
        ],
      ),
    ),
  );
}
}

class MarketplaceTab extends StatelessWidget {
  final ApiService apiService;
  final Function(Product) addToBasket;
  final Function(Product) buyNow;

  const MarketplaceTab({
    Key? key,
    required this.apiService,
    required this.addToBasket,
    required this.buyNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: apiService.fetchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final products = snapshot.data ?? [];
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                addToBasket: addToBasket,
                buyNow: buyNow,
              );
            },
          );
        }
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final Function(Product) addToBasket;
  final Function(Product) buyNow;

  const ProductCard({
    Key? key,
    required this.product,
    required this.addToBasket,
    required this.buyNow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seller info row
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(product.seller.photoUrl),
                  radius: 20,
                  backgroundColor: Colors.transparent,
                ),
                const SizedBox(width: 8),
                Text(
                  product.seller.username,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewProductScreen(
                      productId: product.productId,
                    ),
                  ),
                );
              },
              child: Text(
                product.productName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Product Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.productPhoto ?? '',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    height: 150,
                    child: const Icon(Icons.broken_image, size: 50),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Price, Stock
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RM ${product.productPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${product.productStock} in stock',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Sold
            Text(
              '${product.productSold} sold',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // Add to Basket & Buy Now
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => addToBasket(product),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add to basket'),
                ),
                ElevatedButton(
                  onPressed: () => buyNow(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Buy now'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Time Posted
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateFormat.yMMMMd().add_jm().format(product.timePosted),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
