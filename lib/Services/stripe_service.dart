// ignore_for_file: unused_element, avoid_print

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:plant_feed/Services/consts.dart';
import 'package:plant_feed/config.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StripeService {
  static final Logger logger = Logger();

  StripeService._();

  static final StripeService instance = StripeService._();

  Future<void> makePayment(String sessionId) async {
    try {
      String? paymentIntentClientSecret =
          await _retrievePaymentIntentClientSecret(sessionId);
      if (paymentIntentClientSecret != null) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentClientSecret,
            merchantDisplayName: "Your Merchant Name",
          ),
        );
        await Stripe.instance.presentPaymentSheet();
      } else {
        logger.e("Failed to retrieve payment intent client secret");
      }
    } catch (e) {
      logger.e("Error during payment: $e");
      throw 'Payment processing failed';
    }
  }

  Future<String?> _retrievePaymentIntentClientSecret(String sessionId) async {
    return "your_payment_intent_client_secret";
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();
      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        "currency": currency,
      };
      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer $stripeSecretKey",
            "Content-Type": 'application/x-www-form-urlencoded'
          },
        ),
      );
      if (response.data != null) {
        return response.data["client_secret"];
      }
      return null;
    } catch (e) {
      logger.e("Error creating payment intent: $e");
    }
    return null;
  }

  Future<void> _processPayment() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      await Stripe.instance.confirmPaymentSheetPayment();
    } catch (e) {
      logger.e("Error processing payment: $e");
    }
  }

  String _calculateAmount(int amount) {
    final calculatedAmount = amount * 100;
    return calculatedAmount.toString();
  }

  Future<String?> createCheckoutSession(
      List<int> selectedProductIds, Map<String, String> shippingDetails) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? userId = prefs.getInt('ID');
      if (userId == null) {
        throw Exception('User not logged in.');
      }

      final requestBody = {
        'selected_products': selectedProductIds,
        'shipping_details': shippingDetails,
      };

      final response = await http.post(
        Uri.parse(
            '${Config.apiUrl}/payment/api/create-checkout-session/?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['id'];
      } else {
        logger.e('Error response: ${response.body}');
        throw Exception('Failed to create checkout session.');
      }
    } catch (e) {
      logger.e("Error creating checkout session: $e");
      return null;
    }
  }

  // ✦ CHANGED: now accepts name and address to forward to the backend
  Future<bool> openCheckout(
      String sessionId,
      List<int> selectedProductIds,
      String name,        // ← new
      String address,     // ← new
  ) async {
    final prefs = await SharedPreferences.getInstance();
    int? userId = prefs.getInt('ID');

    if (userId == null) {
      throw Exception('User not logged in.');
    }

    try {
      final response = await http.post(
        Uri.parse(
            '${Config.apiUrl}/payment/api/create-payment-intent/?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'selected_products': selectedProductIds}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String paymentIntentClientSecret = data['client_secret'];
        int totalAmountCents = (data['total_amount'] as num).toInt();

        print('Total Amount (cents): $totalAmountCents');

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentClientSecret,
            merchantDisplayName: "Aisyah M",
          ),
        );

        await Stripe.instance.presentPaymentSheet();

        // ✦ CHANGED: pass name and address to backend
        await _notifyBackendPaymentSuccess(sessionId, name, address);

        logger.i('Payment successful');
        return true;
      } else {
        logger.e('Error creating payment intent: ${response.body}');
        return false;
      }
    } catch (e) {
      logger.e("Payment failed: $e");
      rethrow;
    }
  }

  // ✦ CHANGED: now sends name and address as POST body
  Future<void> _notifyBackendPaymentSuccess(
      String sessionId, String name, String address) async {
    try {
      final response = await http.post(         // ← changed GET → POST
        Uri.parse(
            '${Config.apiUrl}/payment/api/process-payment/?session_id=$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({                       // ← new body
          'name': name,
          'address': address,
        }),
      );

      if (response.statusCode == 200) {
        logger.i("Backend updated successfully after payment.");
      } else {
        logger.e("Backend update failed: ${response.body}");
        throw 'Failed to update backend after payment.';
      }
    } catch (e) {
      logger.e("Error notifying backend: $e");
      rethrow;
    }
  }
}