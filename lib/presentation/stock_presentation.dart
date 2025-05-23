// lib/presentation/stock_presentation.dart

// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stockflow/components/decimal_input.dart';
import 'package:stockflow/components/filter_form.dart';
import '../components/product_cards.dart';
import '../components/product_details.dart';
import '../domain/stock_domain.dart';
import '../data/stock_data.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _storeNumberController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();
  bool _isProductIdVisible = false;

  RangeValues _priceRange = RangeValues(0, 5000);
  String? _storeNumber;
  bool _showPriceRange = false;

  final ProductService _productService = ProductService(ProductRepository());
  bool _isUpdatingRange = false;
  bool _isUpdatingTextFields = false;

  @override
  void initState() {
    super.initState();
    _fetchUserStoreNumber();
  }

  Future<void> _fetchUserStoreNumber() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _productService.getUserDocument(user.uid);
      if (userDoc.exists) {
        final storeNumber = userDoc['storeNumber'];
        setState(() {
          _storeNumberController.text = storeNumber ?? '';
          _storeNumber = storeNumber;
        });
      }
    }
  }

  Stream<List<DocumentSnapshot>> _filteredProductsStream() {
    return _productService.getProductsStream().map((snapshot) {
      final name = _nameController.text.toLowerCase();
      final brand = _brandController.text.toLowerCase();
      final category = _categoryController.text.toLowerCase();
      final storeNumber = _storeNumber?.toLowerCase() ?? '';
      final productId = _productIdController.text.trim();

      double minPrice = _priceRange.start;
      double maxPrice =
          _priceRange.end >= 5000 ? double.infinity : _priceRange.end;

      if (_minPriceController.text.isNotEmpty) {
        minPrice =
            double.tryParse(_minPriceController.text.replaceAll(',', '.')) ??
                minPrice;
      }

      if (_maxPriceController.text.isNotEmpty) {
        maxPrice =
            double.tryParse(_maxPriceController.text.replaceAll(',', '.')) ??
                maxPrice;
      }

      return snapshot.docs.where((product) {
        final data = product.data() as Map<String, dynamic>;
        final productName = (data['name'] ?? "").toString().toLowerCase();
        final productBrand = (data['brand'] ?? "").toString().toLowerCase();
        final productCategory =
            (data['category'] ?? "").toString().toLowerCase();
        final productStoreNumber =
            (data['storeNumber'] ?? "").toString().toLowerCase();
        final productVatPrice = (data['vatPrice'] ?? 0.0) is int
            ? (data['vatPrice'] as int).toDouble()
            : (data['vatPrice'] ?? 0.0) as double;
        final currentProductId = product.id;

        if (storeNumber.isNotEmpty && productStoreNumber != storeNumber) {
          return false;
        }

        if (productId.isNotEmpty && currentProductId != productId) {
          return false;
        }

        return productName.contains(name) &&
            productBrand.contains(brand) &&
            productCategory.contains(category) &&
            productVatPrice >= minPrice &&
            productVatPrice <= maxPrice;
      }).toList();
    });
  }

  void _onPriceRangeChanged(RangeValues newRange) {
    if (_isUpdatingTextFields) return;

    setState(() {
      _isUpdatingRange = true;

      // Ensure the start value is less than or equal to the end value
      final clampedStart = newRange.start.clamp(0, newRange.end);
      final clampedEnd = newRange.end.clamp(clampedStart, 5000);

      // Update the RangeValues
      _priceRange = RangeValues(clampedStart.toDouble(), clampedEnd.toDouble());

      // Update the text fields
      _minPriceController.text =
          clampedStart.toStringAsFixed(2).replaceAll('.', ',');
      _maxPriceController.text = clampedEnd >= 5000
          ? ''
          : clampedEnd.toStringAsFixed(2).replaceAll('.', ',');

      _isUpdatingRange = false;
    });
  }

  void _onTextFieldChanged() {
    if (_isUpdatingRange) return;

    setState(() {
      _isUpdatingTextFields = true;

      // Parse the min and max values from the text fields
      final min =
          double.tryParse(_minPriceController.text.replaceAll(',', '.')) ?? 0;
      final max =
          double.tryParse(_maxPriceController.text.replaceAll(',', '.')) ??
              5000;

      // Ensure min is less than or equal to max
      final clampedMin = min.clamp(0, max);
      final clampedMax = max.clamp(clampedMin, 5000);

      // Update the RangeValues
      _priceRange = RangeValues(clampedMin.toDouble(), clampedMax.toDouble());

      _isUpdatingTextFields = false;
    });
  }

  void _onBarcodeScanned(String productId) {
    setState(() {
      _productIdController.text = productId;
      _isProductIdVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Filter Products',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("9546C4"),
              hexStringToColor("5E61F4"),
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: kToolbarHeight * 2),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassmorphicFilterForm(
                nameController: _nameController,
                brandController: _brandController,
                categoryController: _categoryController,
                storeNumberController: _storeNumberController,
                onProductIdScanned: _onBarcodeScanned,
                dropdownWidget: Column(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showPriceRange = !_showPriceRange),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "  Price Range",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        ],
                      ),
                    ),
                    if (_showPriceRange)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PriceRangePicker(
                              range: _priceRange,
                              onChanged: _onPriceRangeChanged,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _minPriceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [DecimalInputFormatter()],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Min Price',
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                    ),
                                    onChanged: (_) => _onTextFieldChanged(),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _maxPriceController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    inputFormatters: [DecimalInputFormatter()],
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Max Price',
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                    ),
                                    onChanged: (_) => _onTextFieldChanged(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                onChanged: () => setState(() {}),
              ),
            ),
            if (_isProductIdVisible)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _productIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Product ID',
                    labelStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () => setState(() {
                        _productIdController.clear();
                        _isProductIdVisible = false;
                      }),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ProductCards(
              stream: _filteredProductsStream(),
              onProductTap: showProductDetailsDialog,
            ),
          ],
        ),
      ),
    );
  }

  Color hexStringToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse('0x$hex'));
  }
}

class PriceRangePicker extends StatelessWidget {
  final RangeValues range;
  final Function(RangeValues) onChanged;

  const PriceRangePicker(
      {super.key, required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "€${range.start.round()} - ${range.end >= 5000 ? "€5000+" : "€${range.end.round()}"}",
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        RangeSlider(
          min: 0,
          max: 5000,
          divisions: 100,
          labels: RangeLabels(
            "€${range.start.round()}",
            range.end >= 5000 ? "€5000+" : "€${range.end.round()}",
          ),
          values: range,
          onChanged: onChanged,
          activeColor: Colors.white,
          inactiveColor: Colors.white54,
        ),
      ],
    );
  }
}
