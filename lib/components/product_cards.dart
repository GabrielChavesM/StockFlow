// lib/components/product_cards.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductCards extends StatelessWidget {
  final Stream<List<DocumentSnapshot>> stream;
  final void Function(BuildContext context, Map<String, dynamic> data)
      onProductTap;

  // Campos extras opcionais
  final List<String> extraFields;

  const ProductCards({
    Key? key,
    required this.stream,
    required this.onProductTap,
    this.extraFields = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: StreamBuilder<List<DocumentSnapshot>>(
        stream: stream,
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

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final data = product.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: InkWell(
                  onTap: () => onProductTap(context, data),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(30, 240, 250, 255)
                                .withOpacity(0.6),
                            blurRadius: 5,
                            spreadRadius: 1,
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
                                child: const Center(
                                  child: Icon(Icons.qr_code,
                                      size: 32, color: Colors.black45),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['name'] ?? "Sem nome",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                        "Brand: ${data['brand'] ?? "Sem marca"}"),
                                    Text(
                                        "Model: ${data['model'] ?? "Sem modelo"}"),
                                    Text(
                                        "Current Stock: ${data['stockCurrent'] ?? 0}"),

                                    // Campos extras dinâmicos
                                    ...extraFields.map((field) {
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
                                child: Text(
                                  "€ ${data['vatPrice']?.toStringAsFixed(2) ?? "0.00"}  ",
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

  // Renomeia os campos para melhor exibição
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

/*
// How to use:
ProductCards(
  stream: _filteredProductsStream(),
  onProductTap: showProductDetailsDialog,
  extraFields: ['shopLocation', 'warehouseLocation', 'warehouseStock'],
),
*/
