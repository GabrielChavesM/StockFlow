// ignore_for_file: use_super_parameters, library_private_types_in_public_api, deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barcode/barcode.dart';
import 'package:flutter_svg/svg.dart';

class ProductCards extends StatefulWidget {
  final Stream<List<DocumentSnapshot>> stream;
  final void Function(BuildContext context, Map<String, dynamic> data)
      onProductTap;
  final List<String> extraFields;
  final Duration loadingDuration;

  const ProductCards({
    Key? key,
    required this.stream,
    required this.onProductTap,
    this.extraFields = const [],
    this.loadingDuration =
        const Duration(milliseconds: 500), // Default to 0.5 seconds
  }) : super(key: key);

  @override
  _ProductCardsState createState() => _ProductCardsState();
}

class _ProductCardsState extends State<ProductCards> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(widget.loadingDuration); // Simulate loading delay
    setState(() {
      _isLoading = false; // Stop loading after the delay
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator()); // Show loading indicator
    }

    return Expanded(
      child: StreamBuilder<List<DocumentSnapshot>>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          // Limit the number of products to 5
          final limitedProducts = products.take(5).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: limitedProducts.length,
            itemBuilder: (context, index) {
              final product = limitedProducts[index];
              final data = product.data() as Map<String, dynamic>;

              // Detecta se o produto tem desconto ativo
              final hasDiscount = (data['discountPercent'] != null && data['discountPercent'] > 0) &&
                  (data['endDate'] != null && (data['endDate'] as Timestamp).toDate().isAfter(DateTime.now()));

              // Calcula preço antigo e novo
              final double vatPrice = (data['vatPrice'] is num) ? data['vatPrice'].toDouble() : 0.0;
              final String storeCurrency = data['storeCurrency'] ?? '';
              final double discountPercent = hasDiscount ? data['discountPercent'].toDouble() : 0.0;
              final double discountedPrice = hasDiscount ? vatPrice / (1 - discountPercent / 100) : vatPrice;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: hasDiscount
                      ? BorderSide(color: Colors.redAccent.shade400, width: 2)
                      : BorderSide(color: Colors.transparent),
                ),
                elevation: hasDiscount ? 6 : 2,
                child: InkWell(
                  onTap: () => widget.onProductTap(context, data),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: hasDiscount
                            ? Colors.redAccent.withOpacity(0.1)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: hasDiscount
                                ? Colors.redAccent.withOpacity(0.3)
                                : const Color.fromARGB(30, 240, 250, 255)
                                    .withOpacity(0.6),
                            blurRadius: hasDiscount ? 10 : 5,
                            spreadRadius: hasDiscount ? 3 : 1,
                          ),
                        ],
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 0.01, sigmaY: 0.01),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(4.0),
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: BarcodeWidget(
                                  productId: data['productId'] ?? '',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? "Sem nome",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: hasDiscount
                                            ? Colors.redAccent.shade700
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        "Brand: ${data['brand'] ?? "Sem marca"}"),
                                    Text(
                                        "Model: ${data['model'] ?? "Sem modelo"}"),
                                    Text(
                                        "Current Stock: ${data['stockCurrent'] ?? 0}"),
                                    ...widget.extraFields.map((field) {
                                      final label = _fieldLabel(field);
                                      final value = data[field] ?? 'N/A';
                                      return RichText(
                                        text: TextSpan(
                                          style: DefaultTextStyle.of(context)
                                              .style,
                                          children: [
                                            TextSpan(
                                              text: "$label: ",
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                              text: value.toString(),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(left: 12),
                                child: hasDiscount
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "$storeCurrency ${discountedPrice.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "$storeCurrency ${vatPrice.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        "$storeCurrency ${vatPrice.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'warehouseLocation':
        return 'Warehouse Location';
      case 'warehouseStock':
        return 'Warehouse Stock';
      case 'productLocation':
        return 'Store Location';
      default:
        return field;
    }
  }
}

class BarcodeWidget extends StatelessWidget {
  final String productId;

  const BarcodeWidget({Key? key, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final barcode = Barcode.code128();
    final svg = barcode.toSvg(
      productId,
      width: 200,
      height: 80,
      drawText: false,
    );

    return SvgPicture.string(
      svg,
      width: 60,
      height: 60,
      fit: BoxFit.contain,
    );
  }
}
