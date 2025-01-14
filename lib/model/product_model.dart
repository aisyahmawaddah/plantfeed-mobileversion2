// lib/models/product_model.dart

// ignore_for_file: avoid_print

import 'package:plant_feed/config.dart';
import 'package:plant_feed/model/review_model.dart';
import 'package:plant_feed/model/person_model.dart';

class Product {
  final int productId;
  final String productName;
  final String productDesc;
  final String productCategory;
  final double productPrice;
  final int productStock;
  final String? productPhoto;
  final int productRating;
  final int productSold;
  final DateTime timePosted;
  final bool restricted;
  final Person seller;
  final List<Review> reviews;

  static const String baseUrl = 'http://127.0.0.1:8000/';

  Product({
    required this.productId,
    required this.productName,
    required this.productDesc,
    required this.productCategory,
    required this.productPrice,
    required this.productStock,
    this.productPhoto,
    required this.productRating,
    required this.productSold,
    required this.timePosted,
    required this.restricted,
    required this.seller,
    this.reviews = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['productid'] ?? 0,
      productName: json['productName'] ?? json['name'] ?? 'Unnamed Product',
      productDesc: json['productDesc'] ??
          json['description'] ??
          'No Description Available',
      productCategory:
          json['productCategory'] ?? json['category'] ?? 'Uncategorized',
      productPrice: double.tryParse(json['productPrice']?.toString() ??
              json['price']?.toString() ??
              '0.0') ??
          0.0,
      productStock: json['productStock'] ?? json['stock'] ?? 0,
      productPhoto: json['productPhoto'] != null
          ? '${Config.apiUrl}${json['productPhoto'] ?? json['photo']}'
          : null,
      productRating: json['productRating'] ?? json['rating'] ?? 0,
      productSold: json['productSold'] ?? json['sold'] ?? 0,
      timePosted:
          DateTime.tryParse(json['timePosted'] ?? json['time_posted'] ?? '') ??
              DateTime.now(),
      restricted: (json['restricted'] is bool)
          ? json['restricted']
          : (json['restricted'] == 'true'),
      seller: Person.fromJson(json['seller_info'] ?? {}),
      reviews: (json['reviews'] as List<dynamic>? ?? [])
          .map((reviewJson) => Review.fromJson(reviewJson))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productid': productId,
      'productName': productName,
      'productDesc': productDesc,
      'productCategory': productCategory,
      'productPrice': productPrice,
      'productStock': productStock,
      'productPhoto': productPhoto,
      'productRating': productRating,
      'productSold': productSold,
      'timePosted': timePosted.toIso8601String(),
      'restricted': restricted,
      'seller_info': seller.toJson(),
      'reviews': reviews.map((review) => review.toJson()).toList(),
    };
  }

  String get formattedPrice => '\$${productPrice.toStringAsFixed(2)}';

  String get stockStatus => productStock > 0 ? 'In Stock' : 'Out of Stock';

  String get formattedTimePosted => '${timePosted.toLocal()}';
}

// Order Model
class Order {
  final String transactionCode;
  final List<Product> products;
  final double totalPrice;
  final String orderStatus;
  final String email;
  final String address;
  final double shipping;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.transactionCode,
    required this.products,
    required this.totalPrice,
    required this.orderStatus,
    required this.email,
    required this.address,
    required this.shipping,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      print('Order Details: ${json.toString()}'); // Debugging API response

      var transactionCode = json['transaction_code']?.toString() ?? 'Unknown';
      var totalPrice = double.tryParse(
              json['total_price_for_seller']?.toString() ?? '0.0') ??
          0.0;
      var orderStatus = json['orderStatus']?.toString() ?? 'Pending';
      var email = json['buyer_email']?.toString() ?? 'no-email@example.com';
      var address = json['address']?.toString() ?? 'No address provided';
      var shipping =
          double.tryParse(json['shipping']?.toString() ?? '0.0') ?? 0.0;
      var createdAt =
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now();
      var updatedAt =
          DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now();

      // Deserialize products list
      var productList = json['products'] as List<dynamic>? ?? [];

      List<Product> productsList = productList.map((item) {
        try {
          return Product.fromJson(item); // Reuse Product.fromJson
        } catch (e) {
          print('Error parsing product: $e');
          return Product(
            productId: 0,
            productName: 'Unknown Product',
            productDesc: 'No description available',
            productCategory: 'Unknown',
            productPrice: 0.0,
            productStock: 0,
            productPhoto: null,
            productRating: 0,
            productSold: 0,
            timePosted: DateTime.now(),
            restricted: false,
            seller: Person(
              id: 0,
              username: 'Unknown', // Add this line
              email: 'unknown@example.com',
              name: 'Unknown Seller',
              photo: '',
            ),
          );
        }
      }).toList();

      return Order(
        transactionCode: transactionCode,
        products: productsList,
        totalPrice: totalPrice,
        orderStatus: orderStatus,
        email: email,
        address: address,
        shipping: shipping,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Error parsing order: $e');
      return Order(
        transactionCode: 'Error',
        products: [],
        totalPrice: 0.0,
        orderStatus: 'Error',
        email: 'unknown@example.com',
        address: 'Unknown',
        shipping: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
}
