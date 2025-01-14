// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/product_model.dart';
import 'order_update_screen.dart';

class OrderListScreen extends StatefulWidget {
  final int sellerId;

  const OrderListScreen({Key? key, required this.sellerId}) : super(key: key);

  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  late Future<List<Order>> orders;
  List<Order> filteredOrders = [];
  List<Order> allOrders = [];
  String searchQuery = '';
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    orders = ApiService().fetchSellHistory(widget.sellerId);
    orders.then((data) {
      setState(() {
        allOrders = data;
        _filterOrders();
      });
    });
  }

// Map the raw status to the filtered status
String _mapStatusForFilter(String status) {
  switch (status.toLowerCase()) {
    case 'payment made':
      return 'Pending Orders';
    case 'package order':
      return 'Packaged Orders';
    case 'ship order':
      return 'Shipped Orders';
    case 'order received':
      return 'Completed Orders';
    case 'cancel':
      return 'Cancelled Orders';
    default:
      return 'Completed Orders';
  }
}

  void _filterOrders() {
    setState(() {
      filteredOrders = allOrders.where((order) {
        final matchesSearch = order.transactionCode
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            order.email.toLowerCase().contains(searchQuery.toLowerCase());

        // Map the order status to match filter values
        final orderStatusMapped = _mapStatusForFilter(order.orderStatus);
        final filterStatusNormalized = selectedStatus.toLowerCase().trim();

        final matchesStatus = filterStatusNormalized == 'all' ||
            orderStatusMapped.toLowerCase() == filterStatusNormalized;

        return matchesSearch && matchesStatus;
      }).toList();
    });

    // Debugging
    print('Filtered Orders Count: ${filteredOrders.length}');
    print('Selected Status: "$selectedStatus"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell History'),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar Section
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.green.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      hintText: 'Search by Transaction Code or Email',
                      hintStyle:
                          TextStyle(color: Colors.grey[600], fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 16),
                    onChanged: (query) {
                      setState(() {
                        searchQuery = query;
                        _filterOrders();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12), // Slightly smaller spacing

                // Status Filter Section
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.green.shade400, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.green),
                      iconSize: 28,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                      items: [
                        'All',
                        'Pending Orders',
                        'Packaged Orders',
                        'Shipped Orders',
                        'Completed Orders',
                        'Cancelled Orders',
                      ].map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedStatus = newValue!;
                          _filterOrders();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Order List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchOrders,
              child: FutureBuilder<List<Order>>(
                future: orders,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    );
                  }

                  if (filteredOrders.isEmpty) {
                    return const Center(
                      child: Text(
                        'No orders match your search or filter.',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16.0),
          leading: CircleAvatar(
            backgroundColor: Colors.green[100],
            child: const Icon(Icons.shopping_bag, color: Colors.green),
          ),
          title: Text(
            order.transactionCode,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Status: ${order.orderStatus}',
                style: TextStyle(
                  color: _getStatusColor(order.orderStatus.trim()),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Buyer: ${order.email}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                'Total: RM${order.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.black87),
              ),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OrderDetailScreen(order: order, sellerId: widget.sellerId),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (_mapStatusForFilter(status)) {
      case 'Completed Orders':
        return Colors.green;
      case 'Cancelled Orders':
        return Colors.redAccent;
      default:
        return Colors.grey; // Fallback color for unknown statuses
    }
  }
}
