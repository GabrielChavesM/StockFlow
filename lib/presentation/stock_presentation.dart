// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

// TODO
// ( + ) Melhorar o Price Range para funcionar com vírgulas
// ( + ) Mudanças no Price Range e no Min/Max Price têm que aparecer cada um no seu sucessivamente
// ( + ) Melhorar o filtro de produtos para não ficar tão lento

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stockflow/components/decimal_input.dart';
import 'package:stockflow/components/filter_form.dart';
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
      DocumentSnapshot userDoc = await _productService.getUserDocument(user.uid);
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
  final storeNumber = _storeNumber?.toLowerCase() ?? '';

  final name = _nameController.text.toLowerCase();
  final brand = _brandController.text.toLowerCase();
  final category = _categoryController.text.toLowerCase();

  double minPrice = _priceRange.start;
  double maxPrice = _priceRange.end >= 5000 ? double.infinity : _priceRange.end;

  if (_minPriceController.text.isNotEmpty) {
    final cleanMin = _minPriceController.text.replaceAll(',', '.');
    minPrice = double.tryParse(cleanMin) ?? minPrice;
  }

  if (_maxPriceController.text.isNotEmpty) {
    final cleanMax = _maxPriceController.text.replaceAll(',', '.');
    maxPrice = double.tryParse(cleanMax) ?? maxPrice;
  }

  return _productService.getProductsStream(
    storeNumber: storeNumber,
    name: name.isEmpty ? null : name,
    brand: brand.isEmpty ? null : brand,
    category: category.isEmpty ? null : category,
    minPrice: minPrice,
    maxPrice: maxPrice,
  ).map((snapshot) => snapshot.docs.take(5).toList());
}


  void _onPriceRangeChanged(RangeValues newRange) {
    if (_isUpdatingTextFields) return;

    setState(() {
      _isUpdatingRange = true;
      _priceRange = newRange;
      _minPriceController.text = newRange.start.toStringAsFixed(2).replaceAll('.', ',');
      _maxPriceController.text = newRange.end >= 5000 ? '' : newRange.end.toStringAsFixed(2).replaceAll('.', ',');
      _isUpdatingRange = false;
    });
  }

  void _onTextFieldChanged() {
    if (_isUpdatingRange) return;

    setState(() {
      _isUpdatingTextFields = true;
      final min = double.tryParse(_minPriceController.text.replaceAll(',', '.')) ?? 0;
      final max = double.tryParse(_maxPriceController.text.replaceAll(',', '.')) ?? 5000;

      _priceRange = RangeValues(min.clamp(0, 5000), max.clamp(0, 5000));
      _isUpdatingTextFields = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Filter Products', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey),
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
            SizedBox(height: kToolbarHeight * 2),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassmorphicFilterForm(
                nameController: _nameController,
                brandController: _brandController,
                categoryController: _categoryController,
                storeNumberController: _storeNumberController,
                dropdownWidget: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPriceRange = !_showPriceRange;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "  Price Range",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            _showPriceRange ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    if (_showPriceRange)
                      Column(
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
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [DecimalInputFormatter()],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Min Price',
                                    labelStyle: TextStyle(color: Colors.white),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  onChanged: (_) => _onTextFieldChanged(),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _maxPriceController,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [DecimalInputFormatter()],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Max Price',
                                    labelStyle: TextStyle(color: Colors.white),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white),
                                    ),
                                  ),
                                  onChanged: (_) => _onTextFieldChanged(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
                onChanged: () => setState(() {}),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<DocumentSnapshot>>(
                stream: _filteredProductsStream(),
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
                          onTap: () => showProductDetailsDialog(context, data),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(30, 240, 250, 255).withOpacity(0.6),
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
                                          child: Icon(Icons.qr_code, size: 32, color: Colors.black45),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['name'] ?? "Sem nome",
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 4),
                                            Text("Brand: ${data['brand'] ?? "Sem marca"}"),
                                            Text("Model: ${data['model'] ?? "Sem modelo"}"),
                                            Text("Current Stock: ${data['stockCurrent'] ?? 0}"),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(left: 12),
                                        child: Text(
                                          "€ ${data['salePrice']?.toStringAsFixed(2) ?? "0.00"}  ",
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

  const PriceRangePicker({
    super.key,
    required this.range,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "€${range.start.round()} - ${range.end >= 5000 ? "€5000+" : "€${range.end.round()}"}",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
