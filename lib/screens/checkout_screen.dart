// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:plant_feed/config.dart';
import 'package:plant_feed/screens/payment_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final double totalCheckout; // Total amount for the checkout (excluding shipping)
  final Map<String, Map<String, dynamic>> items; // Product details
  final Map<String, double> sellerSubtotals; // Subtotal for each seller

  const CheckoutScreen({
    Key? key,
    required this.totalCheckout,
    required this.items,
    required this.sellerSubtotals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Gather selected product IDs
    List<int> selectedProductIds = items.keys
        .map((key) => int.tryParse(key) ?? 0)
        .where((id) => id != 0)
        .toList(); // Ensure valid IDs

    // Group items by seller
    Map<String, List<Map<String, dynamic>>> sellerItems = {};
    items.forEach((productId, itemDetails) {
      String sellerName = itemDetails['seller'] ?? 'Unknown Seller';
      (sellerItems[sellerName] ??= []).add(itemDetails);
    });

    // Calculate shipping fee per seller (RM5 per quantity)
    Map<String, double> sellerShippingFees = {};
    sellerItems.forEach((sellerName, itemsList) {
      int totalQuantity = itemsList.fold(
          0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
      double shippingFee = totalQuantity * 5.0;
      sellerShippingFees[sellerName] = shippingFee;
    });

    // Calculate total shipping fee for the order
    double totalShippingFee =
        sellerShippingFees.values.fold(0.0, (sum, fee) => sum + fee);

    // Calculate final total checkout amount (sum of seller subtotals + shipping)
    double finalTotalCheckout = totalCheckout + totalShippingFee;

    // Logging for debugging
    print(
        'Final Total Checkout (including shipping): RM ${finalTotalCheckout.toStringAsFixed(2)}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout Summary'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display order items grouped by seller
            Expanded(
              child: ListView(
                children: sellerItems.entries.map((entry) {
                  String sellerName = entry.key;
                  double sellerSubtotal = sellerSubtotals[sellerName] ?? 0.0;
                  double shippingFee = sellerShippingFees[sellerName] ?? 0.0;
                  double sellerTotal = sellerSubtotal + shippingFee;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seller: $sellerName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          ...entry.value.map((itemDetails) {
                            // Initialize unitPrice
                            double unitPrice = 0.0;

                            // Retrieve subtotal and quantity
                            var subtotalDynamic = itemDetails['subtotal'];
                            var quantityDynamic = itemDetails['quantity'];

                            // Parse subtotal
                            double subtotal = 0.0;
                            if (subtotalDynamic is double) {
                              subtotal = subtotalDynamic;
                            } else if (subtotalDynamic is int) {
                              subtotal = subtotalDynamic.toDouble();
                            } else if (subtotalDynamic is String) {
                              // Remove any non-numeric characters before parsing
                              subtotal = double.tryParse(
                                      subtotalDynamic.replaceAll(RegExp(r'[^\d.]'), '')) ??
                                  0.0;
                            } else {
                              print(
                                  'Unexpected subtotal type: ${subtotalDynamic.runtimeType}');
                            }

                            // Parse quantity
                            int quantity = 0;
                            if (quantityDynamic is int) {
                              quantity = quantityDynamic;
                            } else if (quantityDynamic is String) {
                              quantity = int.tryParse(quantityDynamic) ?? 0;
                            } else {
                              print(
                                  'Unexpected quantity type: ${quantityDynamic.runtimeType}');
                            }

                            // Compute unitPrice if possible
                            if (quantity > 0) {
                              unitPrice = subtotal / quantity;
                            } else {
                              print(
                                  'Quantity is zero or invalid for product: ${itemDetails['name'] ?? 'Unknown Product'}');
                            }

                            // Debugging logs
                            print('Product ID: ${itemDetails['id'] ?? 'N/A'}');
                            print(
                                'Product Name: ${itemDetails['name'] ?? 'Unknown Product'}');
                            print('Subtotal: $subtotal');
                            print('Quantity: $quantity');
                            print('Computed Unit Price: $unitPrice');

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 5.0),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      '${Config.apiUrl}${itemDetails['photo'] ?? ''}',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const CircleAvatar(
                                            child: Icon(Icons.error));
                                      },
                                    ),
                                  ),
                                ),
                                title: Text(
                                  itemDetails['name'] ?? 'Unknown Product',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Price: RM ${unitPrice.toStringAsFixed(2)}', // Display computed unit price
                                    ),
                                    Text(
                                      'Quantity: $quantity',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const Divider(thickness: 1, color: Colors.black54),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Shop Subtotal:',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                                Text(
                                  'RM ${sellerSubtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Shipping (RM5 x Quantity):',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                                Text(
                                  'RM ${shippingFee.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                          const Divider(thickness: 1, color: Colors.black54),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Shop Total:',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                                Text(
                                  'RM ${sellerTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Total Shipping Fee Display
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Shipping Fee:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'RM ${totalShippingFee.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Total Amount Display
            Card(
              elevation: 2,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'RM ${finalTotalCheckout.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      // Bottom navigation for payment or cancellation
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // **Proceed to Payment** Button
              Expanded(
                child: SizedBox(
                  height: 50, // Ensures sufficient height
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to PaymentScreen with shipping data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            totalAmount: finalTotalCheckout, // Includes shipping
                            selectedProductIds: selectedProductIds,
                            sellerShippingFees: sellerShippingFees, // Per-seller shipping
                            totalShippingFee: totalShippingFee, // Total shipping
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text(
                      'Proceed to Payment',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // **Return to Cart** Button
              Expanded(
                child: SizedBox(
                  height: 50, // Ensures sufficient height
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to the previous screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text(
                      'Return to Cart',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
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
}
