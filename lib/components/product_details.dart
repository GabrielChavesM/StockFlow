// lib/components/product_dialog.dart

import 'package:flutter/material.dart';
import 'dart:ui';

void showProductDetailsDialog(BuildContext context, Map<String, dynamic> data) {
  final details = {
    "Brand": data['brand'] ?? "Without brand",
    "Model": data['model'] ?? "Without model",
    "Category": data['category'] ?? "Without category",
    "Subcategory": data['subCategory'] ?? "Without subcategory",
    "Description": data['description'] ?? "Without description",
    "Sale Price": "€ ${data['salePrice']?.toStringAsFixed(2) ?? "0.00"}",
    "Current Stock": "${data['stockCurrent'] ?? 0}",
    "Stock Order": "${data['stockOrder'] ?? 0}",
  };

  final Map<String, IconData> icons = {
    "Brand": Icons.storefront,
    "Model": Icons.device_hub,
    "Category": Icons.category,
    "Subcategory": Icons.subdirectory_arrow_right,
    "Description": Icons.description,
    "Sale Price": Icons.attach_money,
    "Current Stock": Icons.inventory,
    "Stock Order": Icons.shopping_cart,
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        constraints: BoxConstraints(
          maxHeight: (MediaQuery.of(context).size.height / 1.75),
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Close Button
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 12.0),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 28, color: Colors.black87),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
              child: Text(
                data['name'] ?? "No name",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Details
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: details.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icons[entry.key], color: Colors.black54, size: 24.0),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16.0,
                                ),
                                children: [
                                  TextSpan(
                                    text: "${entry.key}: ",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: entry.value,
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Divider(color: Colors.black26, thickness: 0.5, indent: 20, endIndent: 20),
                      const SizedBox(height: 6),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
