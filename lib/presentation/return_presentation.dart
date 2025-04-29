// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stockflow/components/filter_form.dart';
import '../data/return_data.dart';
import '../domain/return_domain.dart';

// Presentation Layer
class ReturnPage extends StatefulWidget {
  const ReturnPage({super.key});

  @override
  _ReturnPageState createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _storeNumberController = TextEditingController();
  String _storeNumber = '';
  int _breakageQty = 0; // Quantidade inicial de quebras
  final ProductService _productService = ProductService(ProductRepository());

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
        setState(() {
          _storeNumber = userDoc['storeNumber'] ?? '';
          _storeNumberController.text =
              _storeNumber; // Atribui o valor ao controlador
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Stock Brakes', style: TextStyle(color: Colors.white)),
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
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  final allProducts = snapshot.data!.docs;

                  // Filtragem dos produtos
                  final filteredProducts = allProducts
                      .where((product) {
                        final data = product.data() as Map<String, dynamic>;
                        final productName =
                            (data['name'] ?? "").toString().toLowerCase();
                        final productBrand =
                            (data['brand'] ?? "").toString().toLowerCase();
                        final productCategory =
                            (data['category'] ?? "").toString().toLowerCase();
                        final productStoreNumber = (data['storeNumber'] ?? "")
                            .toString()
                            .toLowerCase();
                        final currentStock = data['stockCurrent'] ?? 0;
                        final warehouseStock = data['wareHouseStock'] ?? 0;

                        // Verifica se o produto tem estoque (warehouseStock > 0 ou currentStock > 0)
                        bool hasStock = currentStock > 0 || warehouseStock > 0;

                        return productName
                                .contains(_nameController.text.toLowerCase()) &&
                            productBrand.contains(
                                _brandController.text.toLowerCase()) &&
                            productCategory.contains(
                                _categoryController.text.toLowerCase()) &&
                            (_storeNumber.isEmpty ||
                                productStoreNumber ==
                                    _storeNumber.toLowerCase()) &&
                            hasStock; // Apenas incluir produtos com estoque
                      })
                      .toList()
                      .take(5)
                      .toList(); // Limita a 5 produtos

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 0),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final data = product.data() as Map<String, dynamic>;

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
                          title: Text(data['name'] ?? "Without name"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Brand: ${data['brand'] ?? "Without brand"}"),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Current Stock: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: (data['stockCurrent'] ?? 0)
                                          .toString(),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: [
                                    TextSpan(
                                      text: "Warehouse Stock: ",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: (data['wareHouseStock'] ?? 0)
                                          .toString(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () async {
                            User? user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              DocumentSnapshot userDoc = await _productService
                                  .getUserDocument(user.uid);
                              if (userDoc.exists) {
                                String adminPermission =
                                    userDoc['adminPermission'] ?? '';
                                if (adminPermission == _storeNumber) {
                                  _showBreakageDialog(context, product);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('No permission.')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // Método para converter string hexadecimal em cor
  void _showBreakageDialog(BuildContext context, DocumentSnapshot product) {
    final data = product.data() as Map<String, dynamic>;

    String breakageType =
        'stockCurrent'; // Tipo inicial padrão: Estoque de Loja

    // Obtendo o estoque disponível
    int currentStock = data['stockCurrent'] ?? 0;
    int warehouseStock = data['wareHouseStock'] ?? 0;

    // A quantidade máxima que pode ser selecionada será o estoque disponível
    int maxBreakageQty =
        (breakageType == 'stockCurrent') ? currentStock : warehouseStock;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                padding: EdgeInsets.all(16),
                height: 400,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Product Breakage: ${data['name'] ?? "Without name"}",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text("Store Stock: $currentStock"),
                    Text("Warehouse Stock: $warehouseStock"),
                    SizedBox(height: 20),

                    // Seleção de tipo de estoque
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Radio<String>(
                          value: 'stockCurrent',
                          groupValue: breakageType,
                          onChanged: (value) {
                            setState(() {
                              breakageType = value!;
                              // Atualiza a quantidade máxima de quebra conforme o tipo de estoque
                              maxBreakageQty = (breakageType == 'stockCurrent')
                                  ? currentStock
                                  : warehouseStock;
                              if (_breakageQty > maxBreakageQty) {
                                _breakageQty =
                                    maxBreakageQty; // Ajusta a quantidade se necessário
                              }
                            });
                          },
                        ),
                        Text('Store'),
                        Radio<String>(
                          value: 'wareHouseStock',
                          groupValue: breakageType,
                          onChanged: (value) {
                            setState(() {
                              breakageType = value!;
                              // Atualiza a quantidade máxima de quebra conforme o tipo de estoque
                              maxBreakageQty = (breakageType == 'stockCurrent')
                                  ? currentStock
                                  : warehouseStock;
                              if (_breakageQty > maxBreakageQty) {
                                _breakageQty =
                                    maxBreakageQty; // Ajusta a quantidade se necessário
                              }
                            });
                          },
                        ),
                        Text('Warehouse'),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Contador de quantidade de quebra
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (_breakageQty > 1) _breakageQty--;
                            });
                          },
                        ),
                        Text("$_breakageQty", style: TextStyle(fontSize: 24)),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              if (_breakageQty < maxBreakageQty)
                                _breakageQty++; // Respeita o limite do estoque
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Botões de Cancelar e Salvar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100], // Cor do fundo
                              borderRadius: BorderRadius.circular(
                                  12), // Bordas arredondadas
                              boxShadow: [
                                // Sombra clara (parte superior)
                                BoxShadow(
                                  color: Colors.white, // Sombra clara
                                  offset: Offset(-4, -4), // Direção da sombra
                                  blurRadius: 6, // Difusão da sombra
                                ),
                                // Sombra escura (parte inferior)
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.1), // Sombra escura
                                  offset: Offset(4, 4), // Direção da sombra
                                  blurRadius: 6, // Difusão da sombra
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20), // Espaçamento interno
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87, // Cor do texto
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            if (_breakageQty <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Invalid breakage quantity")),
                              );
                              return;
                            }

                            _showConfirmationDialog(
                                context, product, breakageType);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors
                                  .blue, // Cor do fundo (ajuste conforme necessário)
                              borderRadius: BorderRadius.circular(
                                  12), // Bordas arredondadas
                              boxShadow: [
                                // Sombra clara (parte superior)
                                BoxShadow(
                                  color: Colors.white, // Sombra clara
                                  offset: Offset(-4, -4), // Direção da sombra
                                  blurRadius: 6, // Difusão da sombra
                                ),
                                // Sombra escura (parte inferior)
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.1), // Sombra escura
                                  offset: Offset(4, 4), // Direção da sombra
                                  blurRadius: 6, // Difusão da sombra
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20), // Espaçamento interno
                            child: Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white, // Cor do texto
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showConfirmationDialog(
      BuildContext context, DocumentSnapshot product, String breakageType) {
    final data = product.data() as Map<String, dynamic>;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Breakage"),
          content: Text(
            "Are you sure you want to mark ${data['name']} as breakage from "
            "${breakageType == 'stockCurrent' ? 'Store Stock' : 'Warehouse Stock'}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                // Estoque atual e nova quantidade
                int currentStock = data[breakageType] ?? 0;
                int newStock = currentStock - _breakageQty;

                if (newStock < 0) newStock = 0;

                String breakageField = breakageType == 'stockCurrent'
                    ? 'storeBreak'
                    : 'warehouseStockBreak';
                int stockBreak = data[breakageField] ?? 0;
                stockBreak += _breakageQty;

                try {
                  await _productService.updateProductStock(product.id, {
                    breakageType: newStock,
                    breakageField: stockBreak,
                  });

                  await _productService.addBreakageRecord({
                    'productId': product.id,
                    'productName': data['name'],
                    'breakageQty': _breakageQty,
                    'breakageType': breakageType,
                    'timestamp': Timestamp.now(),
                  });

                  Navigator.of(context).pop(); // Fecha a confirmação
                  Navigator.of(context).pop(); // Fecha o diálogo principal

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Breakage recorded successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error saving breakage: $e")),
                  );
                }
              },
              child: Text("Confirm"),
            ),
          ],
        );
      },
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
