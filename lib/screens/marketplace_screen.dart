import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/product_model.dart';
import 'package:plant_feed/screens/basket_summary_screen.dart';
import 'package:plant_feed/screens/order_history_screen.dart';
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
  int basketCount = 0;

  @override
  void initState() {
    super.initState();
    futureProducts = apiService.fetchProducts();
    loadBasketItems();
    refreshBasketCount();
  }

  Future<void> loadBasketItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      basketCount = prefs.getInt('basketCount') ?? 0;
    });
  }

  Future<void> saveBasketState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('basketCount', basketCount);
  }

  Future<void> refreshBasketCount() async {
    try {
      final basketList = await apiService.fetchBasketSummary();
      setState(() {
        basketCount = basketList.length;
      });
      await saveBasketState();
    } catch (e) {
      debugPrint('Error refreshing basket count: $e');
    }
  }

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ID');
  }

  void addToBasket(Product product) async {
    final userId = await getUserId();
    if (userId != null) {
      try {
        await apiService.addToBasket(userId, product.productId, 1);
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

  void buyNow(Product product) async {
    final userId = await getUserId();
    if (userId != null) {
      try {
        await apiService.buyNow(userId, product.productId, 1);
        await refreshBasketCount();
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
    final sellerId = userProvider.getUser?.id ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.black,
            tabs: [
              Tab(text: 'Marketplace'),
              Tab(text: 'My Marketplace'),
            ],
          ),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
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
          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 0.57,
            ),
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
    // ✦ KEY CHANGE: detect out-of-stock
    final bool isOutOfStock = product.productStock <= 0;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Photo
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
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  product.productPhoto ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, size: 40),
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seller info row
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(product.seller.photoUrl),
                      radius: 10,
                      backgroundColor: Colors.transparent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        product.seller.username,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${product.productPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${product.productStock} in stock · ${product.productSold} sold',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // ✦ KEY CHANGE: show Out of Stock button OR normal buttons
                if (isOutOfStock)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: null, // disabled — cannot be pressed
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => addToBasket(product),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Icon(Icons.add_shopping_cart, size: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => buyNow(product),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Buy', style: TextStyle(fontSize: 12)),
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