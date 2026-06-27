// lib/screens/invoice_screen.dart

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const InvoiceScreen({Key? key, required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('InvoiceScreen received orders: $orders');

    if (orders.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Invoice'),
          backgroundColor: Colors.green,
        ),
        body: const Center(child: Text('No orders available for the invoice.')),
      );
    }

    final transactionCode = orders.first['transaction_code'] ?? 'N/A';

    // Build items list from this group (already per-seller)
    final List<Map<String, dynamic>> items = orders.map((order) {
      final item = order['item'] as Map<String, dynamic>? ?? {};
      return item;
    }).toList();

    // ✦ FIX: compute shipping and total from THIS group's items only,
    //   not from order_info which holds the grand total across all sellers.
    //   Backend charges RM5 per quantity per seller.
    double itemsSubtotal = 0.0;
    int totalQty = 0;
    for (final item in items) {
      final price = double.tryParse(item['productPrice']?.toString() ?? '0') ?? 0.0;
      final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      itemsSubtotal += price * qty;
      totalQty += qty;
    }
    final double shippingCost = totalQty * 5.0; // RM5 per quantity
    final double total = itemsSubtotal + shippingCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Header
            Center(
              child: Column(
                children: [
                  const Text(
                    "IGROW Invoice",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Universiti Teknologi Malaysia\nSkudai, Johor, Malaysia",
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey[400], thickness: 1),
            const SizedBox(height: 16),
            Text(
              "Transaction ID: $transactionCode",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              "Items",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 8),
            // Items List
            Expanded(
              child: items.isNotEmpty
                  ? ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final productName = item['productName'] ?? 'Unknown Product';
                        final productQty = item['quantity'] ?? 0;
                        final productPrice = item['productPrice'] ?? '0.00';

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text("Qty: $productQty"),
                                  ],
                                ),
                                Text(
                                  "RM$productPrice",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : const Center(child: Text('No items found for this order.')),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey[400], thickness: 1),
            const SizedBox(height: 8),
            // ✦ Now shows only THIS seller's shipping and total
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Shipping: RM${shippingCost.toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Total Price: RM${total.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _createPdf(context, transactionCode, shippingCost, total, items);
                  },
                  child: const Text('Save Invoice'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createPdf(BuildContext context, String transactionCode,
      double shippingCost, double total, List<Map<String, dynamic>> items) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        title: Text('Generating PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Please wait while the invoice is being generated...'),
          ],
        ),
      ),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "IGROW Invoice",
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Universiti Teknologi Malaysia",
                  style: pw.TextStyle(fontSize: 16)),
              pw.Text("Skudai, Johor, Malaysia",
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text("Transaction ID: $transactionCode",
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Text("Items",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Product Name', 'Quantity', 'Price'],
                data: items.map((item) {
                  final productName = item['productName'] ?? 'Unknown Product';
                  final productQty = item['quantity'] ?? 0;
                  final productPrice = item['productPrice'] ?? '0.00';
                  return [productName, productQty.toString(), "RM$productPrice"];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text("Shipping: RM${shippingCost.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text("Total Price: RM${total.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );

    Navigator.of(context).pop();
  }
}