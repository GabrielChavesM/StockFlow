// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stockflow/components/filter_form.dart';
import '../data/warehouse_data.dart';
import '../domain/warehouse_domain.dart';

// Presentation Layer
class WarehouseFilteredPage extends StatefulWidget {
  const WarehouseFilteredPage({super.key});

  @override
  _WarehouseFilteredPageState createState() => _WarehouseFilteredPageState();
}

class _WarehouseFilteredPageState extends State<WarehouseFilteredPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _storeNumberController = TextEditingController();
  String? _selectedPriceRange;

  String? _storeNumber;
  final ProductService _productService = ProductService(ProductRepository());

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

  // Função de filtragem dos produtos
  Stream<List<DocumentSnapshot>> _filteredProductsStream() {
    return _productService.getProductsStream().map((snapshot) {
      final name = _nameController.text.toLowerCase();
      final brand = _brandController.text.toLowerCase();
      final category = _categoryController.text.toLowerCase();
      final storeNumber = _storeNumber?.toLowerCase() ?? '';

      double minPrice = 0;
      double maxPrice = double.infinity;

      if (_selectedPriceRange != null) {
        if (_selectedPriceRange == '5000+') {
          minPrice = 5000;
          maxPrice = double.infinity;
        } else {
          final range = _selectedPriceRange!.split('-');
          minPrice = double.tryParse(range[0]) ?? 0;
          maxPrice = double.tryParse(range[1]) ?? double.infinity;
        }
      }

      return snapshot.docs.where((product) {
        final data = product.data() as Map<String, dynamic>;

        final productName = (data['name'] ?? "").toString().toLowerCase();
        final productBrand = (data['brand'] ?? "").toString().toLowerCase();
        final productCategory = (data['category'] ?? "").toString().toLowerCase();
        final productStoreNumber = (data['storeNumber'] ?? "").toString().toLowerCase();
        final productPrice = (data['salePrice'] ?? 0.0) is int
            ? (data['salePrice'] as int).toDouble()
            : (data['salePrice'] ?? 0.0) as double;
        final warehouseStock = data['wareHouseStock'] ?? 0;

        // Verifica se o estoque no armazém é maior que 0
        if (warehouseStock <= 0) return false;

        // Verifica se o storeNumber é válido e corresponde ao filtro
        if (storeNumber.isNotEmpty && productStoreNumber != storeNumber) {
          return false;
        }

        // Se o utilizador acabou de fazer login e não colocou um código de loja, não aparecem produtos
        if (storeNumber.isEmpty) return false;

        // Aplica os outros filtros
        return productName.contains(name) &&
            productBrand.contains(brand) &&
            productCategory.contains(category) &&
            productPrice >= minPrice &&
            productPrice <= maxPrice;
      }).toList().take(5).toList();
    });
  }

  void _showEditLocationDialog(BuildContext context, TextEditingController locationController, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Editar Localização"),
          content: TextField(
            controller: locationController,
            decoration: InputDecoration(
              labelText: "Localização do Produto",
              contentPadding: EdgeInsets.symmetric(vertical: 0.5, horizontal: 12.0),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-4, -4),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: Offset(4, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                // Verifica se o campo está vazio e atribui "Not located." caso necessário
                String locationText = locationController.text.isEmpty ? "Not located." : locationController.text;

                try {
                  await _productService.updateProductLocation(documentId, locationText);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                } catch (e) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error while saving location: $e')),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-4, -4),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: Offset(4, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductDetailsDialog(BuildContext context, Map<String, dynamic> data, String documentId) {
    final TextEditingController locationController =
        TextEditingController(text: data['warehouseLocation'] ?? '');

    final details = {
      "Brand": data['brand'] ?? "No brand",
      "Model": data['model'] ?? "No model",
      "Category": data['category'] ?? "No category",
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(data['name'] ?? "No name", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...details.entries.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: "${entry.key}: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: entry.value),
                        ],
                      ),
                    ),
                    SizedBox(height: 8), // Adiciona espaçamento entre os itens
                    Divider(), // Linha separadora
                  ],
                );
              }),

              // Exibição da localização de forma clicável
              GestureDetector(
                onTap: () async {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    DocumentSnapshot userDoc = await _productService.getUserDocument(user.uid);
                    if (userDoc.exists) {
                      String adminPermission = userDoc['adminPermission'] ?? '';
                      if (adminPermission == _storeNumber) {
                        _showEditLocationDialog(context, locationController, documentId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Você não tem permissão para editar a localização.')),
                        );
                      }
                    }
                  }
                },
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      TextSpan(
                        text: "Location: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: data['warehouseLocation'] ?? "Não localizado",
                        style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () async { 
                try {
                  await _productService.updateProductLocation(documentId, locationController.text);
                  Navigator.of(context).pop();
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error while saving location: $e')),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      offset: Offset(-4, -4),
                      blurRadius: 6,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      offset: Offset(4, 4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Warehouse Stock', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey), // Muda a cor do botão de voltar para branco
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
            SizedBox(height: kToolbarHeight * 2), // Compensa a altura da AppBar
            Padding(
              padding: const EdgeInsets.all(16.0), // Espaçamento igual ao LocationsPage

              // Filter form
              child: GlassmorphicFilterForm(
                nameController: _nameController,
                brandController: _brandController,
                categoryController: _categoryController,
                storeNumberController: _storeNumberController,
                onChanged: () => setState(() {}), // Faz o setState quando o texto muda
              ),
            ),

            Expanded(
              child: StreamBuilder<List<DocumentSnapshot>>(
                stream: _filteredProductsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final products = snapshot.data ?? [];

                  if (products.isEmpty) {
                    return Center(child: Text('No products available.'));
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 0),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final data = product.data() as Map<String, dynamic>;
                      final documentId = product.id;

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(data['name'] ?? "Sem nome", style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Brand: ${data['brand'] ?? "Sem marca"}"),
                              Text("Model: ${data['model'] ?? "Sem modelo"}"),
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    TextSpan(
                                      text: "Warehouse Stock: ",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: data['wareHouseStock']?.toString() ?? "No stock.",
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    TextSpan(
                                      text: "Warehouse Location: ",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: data['warehouseLocation'] ?? "Not located.",
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showProductDetailsDialog(context, data, documentId),
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
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse('0x$hex'));
  }
}