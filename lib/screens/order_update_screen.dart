// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:plant_feed/Services/services.dart';
import 'package:plant_feed/model/product_model.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;
  final int sellerId;

  const OrderDetailScreen(
      {Key? key, required this.order, required this.sellerId})
      : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late String selectedStatus;
  bool isStatusEditable = true;

  @override
  void initState() {
    super.initState();
    selectedStatus = _mapStatusForFilter(widget.order.orderStatus);

    // Disable editing if the status is Completed or Cancelled
    if (selectedStatus == 'Completed Orders' ||
        selectedStatus == 'Cancelled Orders') {
      isStatusEditable = false;
    }
  }

  String _mapStatusForFilter(String apiStatus) {
    switch (apiStatus.toLowerCase()) {
      case 'payment made':
        return 'Pending Orders';
      case 'package order':
        return 'Packaged Orders';
      case 'ship order':
        return 'Shipped Orders';
      case 'order received':
      case 'completed':
        return 'Completed Orders';
      case 'cancel':
        return 'Cancelled Orders';
      default:
        return 'Pending Orders';
    }
  }

  String _mapStatusToApi(String dropdownStatus) {
    switch (dropdownStatus) {
      case 'Pending Orders':
        return 'Payment Made';
      case 'Packaged Orders':
        return 'Package Order';
      case 'Shipped Orders':
        return 'Ship Order';
      case 'Completed Orders':
        return 'Order Received';
      case 'Cancelled Orders':
        return 'Cancel';
      default:
        return 'Payment Made';
    }
  }

  Future<void> _updateOrderStatus() async {
    try {
      String apiStatus = _mapStatusToApi(selectedStatus);

      await ApiService().updateOrderStatus(
        widget.order.transactionCode,
        apiStatus,
        widget.sellerId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use API-provided totalPrice or recalculate if necessary
    double totalProductCost = widget.order.totalPrice > 0
        ? widget.order.totalPrice
        : widget.order.products.fold(
            0.0,
            (sum, product) =>
                sum + (product.productPrice * product.productStock),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        backgroundColor: Colors.green[700],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Transaction Code'),
              _buildCard(widget.order.transactionCode),
              const SizedBox(height: 20),
              _buildSectionTitle('Products'),
              ...widget.order.products.map((product) {
                return _buildProductCard(product);
              }),
              const SizedBox(height: 20),
              _buildSectionTitle('Order Summary'),
              _buildSummaryRow(
                'Total (Excl. Shipping)',
                'RM${totalProductCost.toStringAsFixed(2)}',
              ),
              _buildSummaryRow(
                'Shipping Fee',
                'RM${widget.order.shipping.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('Order Status'),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.green[50],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  underline: Container(),
                  items: [
                    'Pending Orders',
                    'Packaged Orders',
                    'Shipped Orders',
                    'Completed Orders',
                    'Cancelled Orders',
                  ].map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 16,
                          color: isStatusEditable ? Colors.black : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: isStatusEditable
                      ? (String? newValue) {
                          setState(() {
                            selectedStatus = newValue!;
                          });
                        }
                      : null,
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isStatusEditable ? _updateOrderStatus : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    'Submit Update',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade300, width: 1.2),
      ),
      child: Text(
        content,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
        ],
      ),
    );
  }
Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.productName,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('Category: ${product.productCategory}'),
            Text('Price: RM${product.productPrice.toStringAsFixed(2)}'),
            Text('Quantity: ${product.productStock}'),
          ],
        ),
      ),
    );
  }
}