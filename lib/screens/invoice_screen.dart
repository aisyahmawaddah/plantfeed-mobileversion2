// lib/screens/invoice_screen.dart

// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InvoiceScreen extends StatelessWidget {
  final List<Map<String, dynamic>> orders;

  const InvoiceScreen({Key? key, required this.orders}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    final List<Map<String, dynamic>> items = orders.map((order) {
      final item = order['item'] as Map<String, dynamic>? ?? {};
      return item;
    }).toList();

    // Compute per-seller shipping & total from items
    double itemsSubtotal = 0.0;
    int totalQty = 0;
    for (final item in items) {
      final price = double.tryParse(item['productPrice']?.toString() ?? '0') ?? 0.0;
      final qty = int.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
      itemsSubtotal += price * qty;
      totalQty += qty;
    }
    final double shippingCost = totalQty * 5.0;
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
            // Header
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
            // Items list
            Expanded(
              child: items.isNotEmpty
                  ? ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final productName = item['productName'] ?? 'Unknown Product';
                        final productQty = item['quantity'] ?? 0;
                        final productPrice = item['productPrice'] ?? '0.00';
                        final photoUrl = item['productPhoto'] as String?; // ✦ NEW

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // ✦ NEW: product image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: photoUrl != null && photoUrl.isNotEmpty
                                      ? Image.network(
                                          photoUrl,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _placeholderImage(),
                                        )
                                      : _placeholderImage(),
                                ),
                                const SizedBox(width: 12),
                                // Product details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("Qty: $productQty",
                                          style: const TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                // Price
                                Text(
                                  "RM$productPrice",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: () => _createPdf(
                      context, transactionCode, shippingCost, total, items),
                  child: const Text('Save Invoice'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Grey placeholder when image is missing
  Widget _placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  // ✦ Downloads a network image as bytes for embedding in the PDF
  Future<Uint8List?> _fetchImageBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
    } catch (_) {}
    return null;
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

    // ✦ Pre-fetch all product images before building the PDF
    final List<Uint8List?> imageBytesList = await Future.wait(
      items.map((item) {
        final url = item['productPhoto'] as String?;
        if (url != null && url.isNotEmpty) return _fetchImageBytes(url);
        return Future.value(null);
      }),
    );

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("IGROW Invoice",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text("Universiti Teknologi Malaysia"),
              pw.Text("Skudai, Johor, Malaysia"),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 12),
              pw.Text("Transaction ID: $transactionCode"),
              pw.SizedBox(height: 16),
              pw.Text("Items",
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 18)),
              pw.SizedBox(height: 8),
              // ✦ PDF items with image
              ...List.generate(items.length, (i) {
                final item = items[i];
                final productName = item['productName'] ?? 'Unknown Product';
                final productQty = item['quantity'] ?? 0;
                final productPrice = item['productPrice'] ?? '0.00';
                final imgBytes = imageBytesList[i];

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    children: [
                      // Product image or grey placeholder
                      if (imgBytes != null)
                        pw.ClipRRect(
                          horizontalRadius: 4,
                          verticalRadius: 4,
                          child: pw.Image(
                            pw.MemoryImage(imgBytes),
                            width: 56,
                            height: 56,
                            fit: pw.BoxFit.cover,
                          ),
                        )
                      else
                        pw.Container(
                          width: 56,
                          height: 56,
                          color: PdfColors.grey200,
                          child: pw.Center(
                            child: pw.Text('N/A',
                                style: pw.TextStyle(color: PdfColors.grey)),
                          ),
                        ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(productName,
                                style:
                                    pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text("Qty: $productQty"),
                          ],
                        ),
                      ),
                      pw.Text("RM$productPrice",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                );
              }),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Shipping: RM${shippingCost.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Total Price: RM${total.toStringAsFixed(2)}",
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());

    Navigator.of(context).pop();
  }
}