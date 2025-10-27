// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:plant_feed/Services/stripe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plant_feed/screens/order_history_screen.dart';
// import 'dart:convert'; // For JSON encoding
// import 'package:http/http.dart' as http; // For HTTP requests
// import 'package:logger/logger.dart'; // For logging

class PaymentScreen extends StatefulWidget {
  final double totalAmount; // Total amount including shipping
  final List<int> selectedProductIds;
  final Map<String, double> sellerShippingFees;
  final double totalShippingFee;

  const PaymentScreen({
    Key? key,
    required this.totalAmount,
    required this.selectedProductIds,
    required this.sellerShippingFees,
    required this.totalShippingFee,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController(); // Address controller

  // Shipping data
  late Map<String, double> sellerShippingFees;
  late double totalShippingFee;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load user data, including full name and email

    // Initialize shipping data from widget
    sellerShippingFees = widget.sellerShippingFees;
    totalShippingFee = widget.totalShippingFee;
  }

  Future<void> _loadUserData() async {
  final prefs = await SharedPreferences.getInstance();
    emailController.text = prefs.getString('email') ?? ''; // Load email
    nameController.text = prefs.getString('name') ?? '';   // Load name
  }

  void _showSuccessDialogAndRedirect() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // After 2 seconds, close the dialog and navigate to OrderHistoryScreen
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop(); // Close the dialog
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
          );
        });

        return const AlertDialog(
          title: Text("Payment Successful"),
          content: Text("Thank you! Your payment has been successfully processed."),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Information'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Shipping Information",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                readOnly: true, // Email is auto-filled; user cannot change
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController, // Address input
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: SizedBox(
            height: 60, // Increased height for better visibility
            child: ElevatedButton(
              onPressed: () async {
                // Validate input fields
                if (nameController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please complete all fields.')),
                  );
                  return;
                }

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                // Proceed to make payment using the Stripe 
                // Facade usage: StripeService simplifies payment operations
                try {
                  // Create the checkout session with the selected products
                  String? sessionId = await StripeService.instance.createCheckoutSession(
                    widget.selectedProductIds,
                    {
                      'address': addressController.text, // Pass the address to the API
                      'name': nameController.text, // Optionally, pass the name if needed
                    },
                  );

                  if (sessionId != null) {
                    bool paymentSuccess = await StripeService.instance
                        .openCheckout(sessionId, widget.selectedProductIds); // Now returns bool

                    if (paymentSuccess) {
                      // If payment succeeds, redirect to Order History
                      Navigator.of(context).pop(); // Dismiss loading indicator
                      _showSuccessDialogAndRedirect();
                    } else {
                      // Dismiss loading indicator
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment was not successful.')),
                      );
                    }
                  } else {
                    // Dismiss loading indicator
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to initialize payment.')),
                    );
                  }
                } catch (e) {
                  // Dismiss loading indicator
                  Navigator.of(context).pop();

                  // Handle payment failure
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment failed: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                textStyle: const TextStyle(
                  fontSize: 18,
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
      ),
    );
  }
}
