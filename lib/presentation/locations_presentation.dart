// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stockflow/components/filter_form.dart';

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

  List<DocumentSnapshot> _allProducts = []; // Mantém todos os produtos
  String _storeNumber = '';
  final ProductService _productService = ProductService(ProductRepository());

  @override
  void initState() {
    super.initState();
    _fetchUserStoreNumber();
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

    return products
        .where((product) {
          final data = product.data() as Map<String, dynamic>;

          final productName = (data['name'] ?? "").toString().toLowerCase();
          final productBrand = (data['brand'] ?? "").toString().toLowerCase();
          final productCategory =
              (data['category'] ?? "").toString().toLowerCase();
          final productStoreNumber =
              (data['storeNumber'] ?? "").toString().toLowerCase();

          if (storeNumber.isNotEmpty && productStoreNumber != storeNumber)
            return false;
          if (storeNumber.isEmpty) return false;

          return productName.contains(name) &&
              productBrand.contains(brand) &&
              productCategory.contains(category);
        })
        .toList()
        .take(5)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Locate Stock', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: Colors.grey), // Muda a cor do botão de voltar para branco
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
          crossAxisAlignment:
              CrossAxisAlignment.stretch, // Ajusta o alinhamento
          children: [
            SizedBox(height: kToolbarHeight * 2), // Espaço para a AppBar
            Padding(
              padding: const EdgeInsets.all(16.0),
              // Filter form
              child: GlassmorphicFilterForm(
                nameController: _nameController,
                brandController: _brandController,
                categoryController: _categoryController,
                storeNumberController: _storeNumberController,
                onChanged: () =>
                    setState(() {}), // Faz o setState quando o texto muda
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _productService.getProductsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar os produtos.'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('Nenhum produto encontrado.'));
                  }

                  _allProducts = snapshot.data!.docs;
                  final filteredProducts = _applyFilters(_allProducts);

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                        vertical:
                            0), // Adicione um padding para evitar colar no topo
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final data = product.data() as Map<String, dynamic>;
                      final documentId = product.id;

                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          leading: Container(
                            margin: const EdgeInsets.all(4.0),
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.qr_code,
                                  size: 32, color: Colors.black45),
                            ),
                          ),
                          title: Text(
                            data['name'] ?? "Sem nome",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                                      text: "Current Stock: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: data['stockCurrent']?.toString() ??
                                          "No stock.",
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
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
                            final locationController = TextEditingController();
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
      TextEditingController locationController, String documentId) {
    // Fetch the current location of the product and set it in the controller
    final product =
        _allProducts.firstWhere((product) => product.id == documentId);
    final data = product.data() as Map<String, dynamic>;
    locationController.text = data['productLocation'] ?? "Not located.";

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text("Edit Location"),
          content: Column(
            children: [
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
                  Navigator.of(context).pop(); // Close the CupertinoDialog
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
