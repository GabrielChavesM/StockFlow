// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

// TODO
// Melhorar o Price Range para funcionar com virgulas
// Mudanças no Price Range e no Min/Max Price têm que aparecer cada um no seu suscessivamente
// Ao tocar fora do teclado ele tem que sair

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stockflow/components/decimal_input.dart';
import 'package:stockflow/components/filter_form.dart';
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
    return _productService.getProductsStream().map((snapshot) {
      final name = _nameController.text.toLowerCase();
      final brand = _brandController.text.toLowerCase();
      final category = _categoryController.text.toLowerCase();
      final storeNumber = _storeNumber?.toLowerCase() ?? '';

      double minPrice = _priceRange.start;
      double maxPrice = _priceRange.end >= 5000 ? double.infinity : _priceRange.end;

      if (_minPriceController.text.isNotEmpty) {
        minPrice = double.tryParse(_minPriceController.text) ?? minPrice;
      }

      if (_maxPriceController.text.isNotEmpty) {
        maxPrice = double.tryParse(_maxPriceController.text) ?? maxPrice;
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

        if (storeNumber.isNotEmpty && productStoreNumber != storeNumber) {
          return false;
        }

        return productName.contains(name) &&
            productBrand.contains(brand) &&
            productCategory.contains(category) &&
            productPrice >= minPrice &&
            productPrice <= maxPrice;
      }).toList().take(5).toList();
    });
  }

  void _onPriceRangeChanged(RangeValues newRange) {
    setState(() {
      _priceRange = newRange;
      _minPriceController.text = newRange.start.round().toString();
      _maxPriceController.text = newRange.end >= 5000 ? '' : newRange.end.round().toString();
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
                          // Adicionando os campos de preço mínimo e máximo
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
                                  onChanged: (_) => setState(() {}),
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
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
                onChanged: () => setState(() {}), // Chama setState do pai, ou seja, atualiza a tela
              ),
            ),
            // Espaço entre o filtro e a lista de produtos
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

                      // Card dos produtos
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: InkWell(  // Adicionando o InkWell para tornar o card clicável em toda a sua área
                          onTap: () => _showProductDetailsDialog(context, data),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1), // Fundo semitransparente
                                borderRadius: BorderRadius.circular(12), // Bordas arredondadas
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(30, 240, 250, 255).withOpacity(0.6),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 0.01, sigmaY: 0.01), // Desfoque
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      // Espaço reservado para o código de barras
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
                                      // Informações principais (nome, marca, etc.)
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
                                      // Preço à direita, mas levemente centrado para a esquerda
                                      Container(
                                        alignment: Alignment.centerRight,  // Alinha o preço à direita
                                        padding: const EdgeInsets.only(left: 12), // Ajuste o padding para mover um pouco para a esquerda
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

// Mostra descrição do produto selecionado
void _showProductDetailsDialog(BuildContext context, Map<String, dynamic> data) {
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

  // Mapeando os ícones para cada campo
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
    isScrollControlled: true, // Permite que o tamanho do bottom sheet seja ajustado conforme o conteúdo
    backgroundColor: Colors.transparent, // Deixa o fundo transparente para o efeito de vidro
    builder: (BuildContext context) {
      return AnimatedContainer(
        duration: Duration(milliseconds: 300), // Animação suave para a transição do modal
        constraints: BoxConstraints(
          maxHeight: (MediaQuery.of(context).size.height / 1.75),
        ),
        decoration: BoxDecoration(
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
            // Botão X para fechar
            Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 12.0),
              child: Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    size: 28,
                    color: Colors.black87, // Ícone preto suave
                  ),
                ),
              ),
            ),
            // Título do produto
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0), // Melhor padding para o título
              child: Text(
                data['name'] ?? "No name",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87, // Título em preto suave
                ),
              ),
            ),
            SizedBox(height: 8),
            // Detalhes do produto
            Expanded(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                children: details.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Centraliza os campos
                    children: [
                      // Ícones e texto para cada campo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center, // Alinha os itens no centro
                        children: [
                          Icon(
                            icons[entry.key], // Ícone específico para o campo
                            color: Colors.black54, // Ícone cinza
                            size: 24.0, // Aumenta o tamanho do ícone
                          ),
                          const SizedBox(width: 12.0), // Espaçamento entre o ícone e o texto
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.black87, // Texto principal
                                  fontSize: 16.0,
                                ),
                                children: [
                                  TextSpan(
                                    text: "${entry.key}: ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87, // Texto chave em negrito
                                    ),
                                  ),
                                  TextSpan(
                                    text: entry.value,
                                    style: const TextStyle(
                                      color: Colors.black54, // Texto de valor em cinza suave
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(
                        color: Colors.black26, // Linha divisória suave
                        thickness: 0.5,
                        indent: 20, // Indentação para centralizar a linha
                        endIndent: 20, // Indentação para centralizar a linha
                      ),
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
