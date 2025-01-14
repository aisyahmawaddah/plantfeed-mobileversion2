// lib/screens/order_history_screen.dart

// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_feed/screens/layout.dart';
import 'package:plant_feed/screens/invoice_screen.dart';
import 'package:plant_feed/screens/review_product_screen.dart';
import 'package:plant_feed/model/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<Order>> orderHistory;
  final ApiService _apiService = ApiService();

  bool sortByNewest = true;

  @override
  void initState() {
    super.initState();
    orderHistory = _loadOrderHistory();
  }

  /// Fetch order history from the API
  Future<List<Order>> _loadOrderHistory() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('ID');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final Map<String, dynamic> historyData =
          await _apiService.fetchOrderHistory(userId);

      debugPrint('Fetched historyData: $historyData');

      List<Order> orders = [];
      if (historyData.containsKey('all_basket') &&
          historyData['all_basket'] is List) {
        List<dynamic> allBasket = historyData['all_basket'];

        debugPrint('Number of orders in all_basket: ${allBasket.length}');

        for (var orderJson in allBasket) {
          if (orderJson is Map<String, dynamic>) {
            Order parsedOrder = Order.fromJson(orderJson);
            orders.add(parsedOrder);
            debugPrint('Parsed Order ID: ${parsedOrder.id}');
            debugPrint('Parsed Seller: ${parsedOrder.item.product.seller.name}');
          } else {
            debugPrint('Invalid order format: $orderJson');
          }
        }
      } else {
        debugPrint('all_basket is either missing or not a List.');
      }

      debugPrint('Total parsed orders: ${orders.length}');
      for (var order in orders) {
        debugPrint(
            'Order ID: ${order.id}, Seller: ${order.item.product.seller.name}');
      }

      return orders;
    } catch (e) {
      debugPrint('Error loading order history: $e');
      rethrow;
    }
  }

  void _toggleSortOrder() {
    setState(() {
      sortByNewest = !sortByNewest;
    });
  }

  /// Cancel an order (by basket ID)
  Future<void> _cancelOrder(int basketId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _apiService.cancelOrder(basketId);

      Navigator.of(context).pop(); // remove the loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order canceled successfully.')),
      );

      // Refresh the order list
      setState(() {
        orderHistory = _loadOrderHistory();
      });
    } catch (e) {
      Navigator.of(context).pop(); // remove the loading indicator on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel order: $e')),
      );
    }
  }

  /// Confirm before actually canceling
  Future<void> _confirmCancelOrder(int basketId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _cancelOrder(basketId);
    }
  }

  /// Complete order (partial logic via basketId)
  Future<void> _completeOrder(int basketId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _apiService.completeOrder(basketId);

      Navigator.of(context).pop();

      setState(() {
        orderHistory = _loadOrderHistory();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order marked as received.')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete order: $e')),
      );
    }
  }

  /// Re-Order (partial logic via basketId + userId)
  /// Updated to call _apiService.orderAgain(basketId, userId).
  Future<void> _addToBasket(int basketId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('ID');

      if (userId == null) {
        throw Exception('User ID not found');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Connect to the updated orderAgain() method
      await _apiService.orderAgain(basketId);

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order added to your basket.')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add order to basket: $e')),
      );
    }
  }

  /// Pass all orders in the group so user can review them all at once
  Future<void> _reviewProducts(List<Order> groupOrders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('ID');
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found, unable to review products')),
        );
        return;
      }
      final basketId = groupOrders.first.basketId;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewProductScreen(
            userId: userId,
            basketId: basketId,
            groupOrders: groupOrders, // pass entire group
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start review: $e')),
      );
    }
  }

  /// View Invoice
  Future<void> _viewInvoice(List<Order> groupOrders) async {
    final List<Map<String, dynamic>> orderMaps =
        groupOrders.map((order) => order.toJson()).toList();

    debugPrint('InvoiceScreen received orderMaps: $orderMaps');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceScreen(orders: orderMaps),
      ),
    );
  }

  String _getSellerName(Order order) {
    return order.item.product.seller.name;
  }

  /// Group orders by transactionCode + sellerId
  Map<String, List<Order>> _groupOrdersByTransactionCodeAndSeller(
      List<Order> orders) {
    final Map<String, List<Order>> grouped = {};

    for (var order in orders) {
      final key = '${order.transactionCode}_${order.item.product.seller.id}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(order);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        centerTitle: true,
        backgroundColor: Colors.green,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'Marketplace',
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AppLayout(selectedIndex: 3),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Order>>(
        future: orderHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No order history available.'));
          }

          List<Order> orders = snapshot.data!;
          // Sort them by ID
          orders.sort((a, b) {
            return sortByNewest ? b.id.compareTo(a.id) : a.id.compareTo(b.id);
          });

          // Group by (transactionCode, sellerId)
          final groupedOrders = _groupOrdersByTransactionCodeAndSeller(orders);
          final groupKeys = groupedOrders.keys.toList();

          return Column(
            children: [
              // Sort toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(sortByNewest ? 'Newest to Oldest' : 'Oldest to Newest'),
                    IconButton(
                      icon: const Icon(Icons.sort),
                      onPressed: _toggleSortOrder,
                    ),
                  ],
                ),
              ),
              // Main list
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  child: ListView.builder(
                    itemCount: groupKeys.length,
                    itemBuilder: (context, index) {
                      final key = groupKeys[index];
                      final group = groupedOrders[key]!;
                      final firstOrder = group.first; // reference

                      final transactionCode = firstOrder.transactionCode;
                      final sellerName = _getSellerName(firstOrder);
                      final status = firstOrder.status.toLowerCase();

                      // For partial logic, we use basketId
                      final basketId = firstOrder.basketId;

                      // Decide on the UI logic
                      String statusButtonText;
                      Color statusButtonColor;
                      bool isStatusButtonEnabled = false;
                      VoidCallback? statusButtonAction;

                      String actionButtonText;
                      Color actionButtonColor;
                      VoidCallback? actionButtonAction;

                      switch (status) {
                        case 'payment made':
                        case 'package order':
                          statusButtonText = firstOrder.status;
                          statusButtonColor = Colors.blueGrey;
                          isStatusButtonEnabled = false;

                          actionButtonText = 'Cancel Order';
                          actionButtonColor = Colors.red;
                          actionButtonAction = () => _confirmCancelOrder(basketId);
                          break;

                        case 'ship order':
                          statusButtonText = 'Ship Order';
                          statusButtonColor = Colors.blueGrey;
                          isStatusButtonEnabled = false;

                          actionButtonText = 'Complete Order';
                          actionButtonColor = Colors.green;
                          actionButtonAction = () => _completeOrder(basketId);
                          break;

                        case 'order received':
                          statusButtonText = 'Review Product';
                          statusButtonColor = Colors.green;
                          isStatusButtonEnabled = true;
                          statusButtonAction = () => _reviewProducts(group);

                          actionButtonText = 'Re-Order';
                          actionButtonColor = Colors.orange;
                          // Now uses basketId for partial re-order
                          actionButtonAction = () => _addToBasket(basketId);
                          break;

                        case 'product reviewed':
                          statusButtonText = 'Product Reviewed';
                          statusButtonColor = Colors.blueGrey;
                          isStatusButtonEnabled = false;

                          actionButtonText = 'Re-Order';
                          actionButtonColor = Colors.orange;
                          actionButtonAction = () => _addToBasket(basketId);
                          break;

                        case 'cancel':
                          statusButtonText = 'Cancelled';
                          statusButtonColor = Colors.red;
                          isStatusButtonEnabled = false;

                          actionButtonText = 'Re-Order';
                          actionButtonColor = Colors.orange;
                          actionButtonAction = () => _addToBasket(basketId);
                          break;

                        default:
                          statusButtonText = 'Unknown Status';
                          statusButtonColor = Colors.blueGrey;
                          isStatusButtonEnabled = false;

                          actionButtonText = 'N/A';
                          actionButtonColor = Colors.grey;
                          actionButtonAction = null;
                          break;
                      }

                      // Build the primary status button
                      Widget statusButton = ElevatedButton(
                        onPressed: isStatusButtonEnabled ? statusButtonAction : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: statusButtonColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          statusButtonText,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );

                      // Build the secondary action button
                      Widget actionButton = ElevatedButton(
                        onPressed: actionButtonAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionButtonColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          actionButtonText,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 4.0,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // Transaction code
                              Text(
                                'Transaction Code:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                transactionCode,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(thickness: 1, height: 24),
                              // Seller & status row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      const Icon(Icons.store, color: Colors.grey),
                                      const SizedBox(height: 4),
                                      Text(
                                        sellerName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Icon(Icons.info_outline, color: Colors.grey),
                                      const SizedBox(height: 4),
                                      Text(
                                        firstOrder.status,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Buttons
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  statusButton,
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _viewInvoice(group),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                    ),
                                    child: const Text(
                                      'View Invoice',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (actionButtonAction != null) actionButton,
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
