// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stockflow/components/filter_form.dart';
import 'package:stockflow/presentation/map_page.dart';
import '../components/product_cards.dart';
import '../data/locations_data.dart';
import '../domain/locations_domain.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  _LocationsPageState createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _storeNumberController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();

  bool _isProductIdVisible = false;
  bool _isLoadingCards = true;

  List<DocumentSnapshot> _allProducts = [];
  String _storeNumber = '';
  String _adminPermission = '';
  final ProductService _productService = ProductService(ProductRepository());

  @override
  void initState() {
    super.initState();
    _simulateCardLoading();
    _fetchUserStoreNumber();
  }

  Future<void> _simulateCardLoading() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isLoadingCards = false;
    });
  }

  Future<void> _fetchUserStoreNumber() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _productService.getUserDocument(user.uid);
      if (userDoc.exists) {
        setState(() {
          _storeNumber = userDoc['storeNumber'] ?? '';
          _adminPermission = userDoc['adminPermission'] ?? '';
          _storeNumberController.text = _storeNumber;
        });
      }
    }
  }

  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> products) {
    final name = _nameController.text.toLowerCase();
    final brand = _brandController.text.toLowerCase();
    final category = _categoryController.text.toLowerCase();
    final storeNumber = _storeNumber.toLowerCase();
    final productId = _productIdController.text.trim();

    return products
        .where((product) {
          final data = product.data() as Map<String, dynamic>;
          final productName = (data['name'] ?? "").toString().toLowerCase();
          final productBrand = (data['brand'] ?? "").toString().toLowerCase();
          final productCategory = (data['category'] ?? "").toString().toLowerCase();
          final productStoreNumber = (data['storeNumber'] ?? "").toString().toLowerCase();
          final currentProductId = product.id;

          if (storeNumber.isNotEmpty && productStoreNumber != storeNumber) return false;
          if (productId.isNotEmpty && currentProductId != productId) return false;

          return productName.contains(name) &&
              productBrand.contains(brand) &&
              productCategory.contains(category);
        })
        .take(5)
        .toList();
  }

  void _onBarcodeScanned(String productId) {
    setState(() {
      _productIdController.text = productId;
      _isProductIdVisible = true;
    });
  }

  void _onMapIconPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPage()),
    );
  }

  void _showEditLocationDialog(BuildContext context, List<String> locations, String documentId) async {
    final TextEditingController locationController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: const Text("Edit Product Locations"),
              content: Column(
                children: [
                  const Text(
                    "Manage locations for this product:",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  CupertinoTextField(
                    controller: locationController,
                    placeholder: "Add a new location",
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 12),
                  if (locations.isNotEmpty)
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(locations[index]),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                child: const Icon(CupertinoIcons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    locations.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  child: const Text('Add Location'),
                  onPressed: () {
                    if (locationController.text.isNotEmpty) {
                      setState(() {
                        locations.add(locationController.text.trim());
                        locationController.clear();
                      });
                    }
                  },
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () async {
                    try {
                      await updateProductLocations(documentId, locations);
                      setState(() {});
                      Navigator.of(context).pop();
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error while saving locations: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Locate Stock', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.grey),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 12.0),
            icon: const Icon(Icons.map, color: Colors.white),
            onPressed: _onMapIconPressed,
          ),
        ],
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: kToolbarHeight * 2),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GlassmorphicFilterForm(
                nameController: _nameController,
                brandController: _brandController,
                categoryController: _categoryController,
                storeNumberController: _storeNumberController,
                onProductIdScanned: _onBarcodeScanned,
                onChanged: () => setState(() {}),
              ),
            ),
            if (_isProductIdVisible)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      onPressed: () {
                        setState(() {
                          _productIdController.clear();
                          _isProductIdVisible = false;
                        });
                      },
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            Expanded(
              child: _isLoadingCards
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<QuerySnapshot>(
                      stream: _productService.getProductsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return const Center(child: Text('Error loading products.'));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No products found.'));
                        }

                        _allProducts = snapshot.data!.docs;
                        final filteredProducts = _applyFilters(_allProducts);

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final data = product.data() as Map<String, dynamic>;
                            final documentId = product.id;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              child: ListTile(
                                leading: Container(
                                  margin: const EdgeInsets.all(4.0),
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: BarcodeWidget(
                                    productId: data['productId'] ?? '',
                                  ),
                                ),
                                title: Text(
                                  data['name'] ?? "No name",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Brand: ${data['brand'] ?? "No brand"}"),
                                    Text("Model: ${data['model'] ?? "No model"}"),
                                    RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          const TextSpan(
                                            text: "Current Stock: ",
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: data['stockCurrent']?.toString() ?? "No stock.",
                                          ),
                                        ],
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style: DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: (data['productLocations'] as List<dynamic>?)?.length == 1
                                                ? "Shop Location: "
                                                : "Shop Locations: ",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: (data['productLocations'] as List<dynamic>?)?.join(', ') ?? "Not located.",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () async {
                                  User? user = FirebaseAuth.instance.currentUser;
                                  if (user != null) {
                                    DocumentSnapshot userDoc = await _productService.getUserDocument(user.uid);
                                    if (userDoc.exists) {
                                      String adminPermission = userDoc['adminPermission'] ?? '';

                                      String productStoreNumber = data['storeNumber'] ?? '';
                                      if (adminPermission != productStoreNumber) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('You do not have permission to edit this location.'),
                                          ),
                                        );
                                        return;
                                      }
                                    }
                                  }

                                  final locations = List<String>.from(data['productLocations'] ?? []);
                                  _showEditLocationDialog(context, locations, documentId);
                                },
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
}

Future<void> updateProductLocations(String documentId, List<String> locations) async {
  await FirebaseFirestore.instance.collection('products').doc(documentId).update({
    'productLocations': locations,
  });
}

Color hexStringToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return Color(int.parse('0x$hex'));
}