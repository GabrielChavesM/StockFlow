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

// Presentation Layer
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
  bool _isLoadingCards = true; // Add loading state for product cards

  List<DocumentSnapshot> _allProducts = [];
  String _storeNumber = '';
  final ProductService _productService = ProductService(ProductRepository());

  @override
  void initState() {
    super.initState();
    _simulateCardLoading(); // Simulate loading for product cards
    _fetchUserStoreNumber();
  }

  Future<void> _simulateCardLoading() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isLoadingCards = false; // Stop loading after the delay
    });
  }

  // Função para buscar o número da loja do utilizador logado
  Future<void> _fetchUserStoreNumber() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _productService.getUserDocument(user.uid);
      if (userDoc.exists) {
        setState(() {
          _storeNumber = userDoc['storeNumber'] ?? '';
          _storeNumberController.text = _storeNumber;
        });
      }
    }
  }

  // Função de filtragem dos produtos
  List<DocumentSnapshot> _applyFilters(List<DocumentSnapshot> products) {
    final name = _nameController.text.toLowerCase();
    final brand = _brandController.text.toLowerCase();
    final category = _categoryController.text.toLowerCase();
    final storeNumber = _storeNumber.toLowerCase();
    final productId = _productIdController.text.trim(); // Get the productId

    return products
        .where((product) {
          final data = product.data() as Map<String, dynamic>;

          final productName = (data['name'] ?? "").toString().toLowerCase();
          final productBrand = (data['brand'] ?? "").toString().toLowerCase();
          final productCategory =
              (data['category'] ?? "").toString().toLowerCase();
          final productStoreNumber =
              (data['storeNumber'] ?? "").toString().toLowerCase();
          final currentProductId = product.id;

          if (storeNumber.isNotEmpty && productStoreNumber != storeNumber) {
            return false;
          }

          if (productId.isNotEmpty && currentProductId != productId) {
            return false; // Filter by productId if provided
          }

          return productName.contains(name) &&
              productBrand.contains(brand) &&
              productCategory.contains(category);
        })
        .toList()
        .take(5)
        .toList();
  }

  void _onBarcodeScanned(String productId) {
    setState(() {
      _productIdController.text = productId; // Set the scanned productId
      _isProductIdVisible = true;
    });
  }

  void _onMapIconPressed() {
    // Example: Navigate to a map page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPage(), // Replace with your map page widget
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Locate Stock', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey),
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 6.0), // Adjust the padding to move the icon left
            icon: Icon(Icons.map, color: Colors.white), // Add map icon
            onPressed: () {
              _onMapIconPressed(); // Call the map icon handler
            },
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
                onProductIdScanned: _onBarcodeScanned, // Pass the callback
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
                  ? Center(
                      child:
                          CircularProgressIndicator()) // Show loading indicator
                  : StreamBuilder<QuerySnapshot>(
                      stream: _productService.getProductsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Erro ao carregar os produtos.'));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                              child: Text('Nenhum produto encontrado.'));
                        }

                        _allProducts = snapshot.data!.docs;
                        final filteredProducts = _applyFilters(_allProducts);

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(vertical: 0),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            final data = product.data() as Map<String, dynamic>;
                            final documentId = product.id;

                            return Card(
                              margin: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
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
                                  data['name'] ?? "Sem nome",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Brand: ${data['brand'] ?? "Sem marca"}"),
                                    Text(
                                        "Model: ${data['model'] ?? "Sem modelo"}"),
                                    RichText(
                                      text: TextSpan(
                                        style:
                                            DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: "Current Stock: ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: data['stockCurrent']
                                                    ?.toString() ??
                                                "No stock.",
                                          ),
                                        ],
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        style:
                                            DefaultTextStyle.of(context).style,
                                        children: [
                                          TextSpan(
                                            text: "Shop Location: ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: data['productLocation'] ??
                                                "Not located.",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  final locationController =
                                      TextEditingController();
                                  _showEditLocationDialog(
                                      context, locationController, documentId);
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

  // Função para mostrar o diálogo de detalhes do produto
  void _showEditLocationDialog(BuildContext context,
      TextEditingController locationController, String documentId) async {
    // Fetch the current product
    final product = _allProducts.firstWhere(
      (product) => product.id == documentId,
      orElse: () => throw Exception(
          'No matching product found'), // Throw an exception if no product is found
    );

    final data = product.data() as Map<String, dynamic>;
    final productStoreNumber = data['storeNumber'] ?? '';

    // Fetch the current user's adminPermission
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _productService.getUserDocument(user.uid);
      if (userDoc.exists) {
        String adminPermission = userDoc['adminPermission'] ?? '';

        // Check if the user is an admin for this product's store
        if (adminPermission != productStoreNumber) {
          // Show a message and prevent editing
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('You do not have permission to edit this location.')),
          );
          return;
        }
      }
    }

    // If the user is an admin, allow editing
    locationController.text = data['productLocation'] ?? "Not located.";

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("Edit Store Location"),
          content: Column(
            children: [
              Text(
                "Change location for ${data['name'] ?? "Sem nome"}",
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 12),
              CupertinoTextField(
                controller: locationController,
                placeholder: "Product Location",
                padding: EdgeInsets.all(12),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () async {
                String locationText = locationController.text.isEmpty
                    ? "Not located."
                    : locationController.text;

                try {
                  await _productService.updateProductLocation(
                      documentId, locationText);
                  setState(
                      () {}); // Refresh the UI to reflect the updated location
                  Navigator.of(context).pop();
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error while saving location: $e')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

Color hexStringToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  return Color(int.parse('0x$hex'));
}
