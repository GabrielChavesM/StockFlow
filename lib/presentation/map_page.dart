// ignore_for_file: unused_element, unnecessary_cast, unused_field, use_key_in_widget_constructors, library_private_types_in_public_api, sort_child_properties_last, no_leading_underscores_for_local_identifiers, deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final List<Block> _matrix = List.generate(
    30 * 30,
    (index) => Block(color: Colors.grey, name: null),
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _productIdController = TextEditingController();

  bool _isMoveMode = false; // Tracks if the app is in move mode
  int? _selectedBlockIndex; // Tracks the index of the block being moved

  @override
  void initState() {
    super.initState();
    _loadBlocksFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text('Map View'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.cloud_upload),
                onPressed: _saveBlocksToFirebase,
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.cloud_download),
                onPressed: _loadBlocksFromFirebase,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _productIdController,
                        placeholder: 'Enter Product ID',
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 12.0),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(CupertinoIcons.search, size: 24),
                      onPressed: _highlightBlockByProductId,
                    ),
                    SizedBox(width: 8.0),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(CupertinoIcons.camera, size: 24),
                      onPressed: _scanBarcode,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 30,
                      ),
                      itemCount: _matrix.length,
                      itemBuilder: (context, index) {
                        final block = _matrix[index];
                        return GestureDetector(
                          onTap: () => _onBlockTapped(index),
                          child: Container(
                            margin: const EdgeInsets.all(0.5),
                            color: block.color,
                            child: Center(
                              child: Text(
                                block.name ?? '',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 8),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBlockTapped(int index) async {
    final block = _matrix[index];
    _nameController.text = block.name ?? '';

    // Fetch products for the block's location
    List<Map<String, dynamic>> products = [];
    if (block.name != null && block.name!.isNotEmpty) {
      products = await _fetchProductsByLocation(block.name!);
    }

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: Text('Configure Block'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: _nameController,
                      placeholder: 'Enter block name',
                    ),
                    SizedBox(height: 16.0),
                    if (products.isNotEmpty) ...[
                      Text('Products in this block:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8.0),
                      Expanded(
                        child: CupertinoScrollbar(
                          child: ListView.builder(
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Name: ${product['name'] ?? 'Unknown'}'),
                                  Text(
                                      'Brand: ${product['brand'] ?? 'Unknown'}'),
                                  Text(
                                      'Category: ${product['category'] ?? 'Unknown'}'),
                                  Text(
                                      'Stock: ${product['stockCurrent'] ?? 'Unknown'}'),
                                  Divider(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ] else
                      Text('No products found in this block.'),
                    SizedBox(height: 16.0),
                    CupertinoButton(
                      child: Text('Move Block'),
                      onPressed: () {
                        setState(() {
                          _isMoveMode = true; // Enter move mode
                          _selectedBlockIndex =
                              index; // Store the index of the block being moved
                        });
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                    SizedBox(height: 8.0),
                    CupertinoButton(
                      child: Text('Delete Block',
                          style:
                              TextStyle(color: CupertinoColors.destructiveRed)),
                      onPressed: () {
                        setState(() {
                          // Reset the block to its default state
                          block.name = null;
                          block.color = Colors.grey;
                        });
                        Navigator.of(context).pop(); // Close the dialog
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: Text('Save'),
                  onPressed: () {
                    setState(() {
                      block.name = _nameController.text;
                      block.color = Colors
                          .brown; // Update block color to indicate it's occupied
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<int?> _showMoveBlockDialog(int currentIndex) async {
    final TextEditingController _rowController = TextEditingController();
    final TextEditingController _colController = TextEditingController();

    return showCupertinoDialog<int>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: Text('Move Block'),
          content: Column(
            children: [
              CupertinoTextField(
                controller: _rowController,
                placeholder: 'Enter row (0-29)',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8.0),
              CupertinoTextField(
                controller: _colController,
                placeholder: 'Enter column (0-29)',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: Text('Move'),
              onPressed: () {
                final row = int.tryParse(_rowController.text);
                final col = int.tryParse(_colController.text);

                if (row != null &&
                    col != null &&
                    row >= 0 &&
                    row < 30 &&
                    col >= 0 &&
                    col < 30) {
                  final newIndex = row * 30 + col;
                  Navigator.of(context).pop(newIndex);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Invalid row or column. Please enter values between 0 and 29.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBlocksToFirebase() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String storeNumber = userDoc['storeNumber'] ?? 'Unknown';

      final blocksWithData = _matrix
          .asMap()
          .entries
          .where((entry) =>
              entry.value.name != null || entry.value.color != Colors.grey)
          .map((entry) {
        final index = entry.key;
        final row = index ~/ 30;
        final col = index % 30;
        return {
          'row': row,
          'col': col,
          'name': entry.value.name,
          'color': entry.value.color.value,
        };
      }).toList();

      await FirebaseFirestore.instance.collection('maps').doc(storeNumber).set({
        'storeNumber': storeNumber,
        'blocks': blocksWithData,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Map saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving map: $e')),
      );
    }
  }

  Future<void> _loadBlocksFromFirebase() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String storeNumber = userDoc['storeNumber'] ?? 'Unknown';

      DocumentSnapshot mapDoc = await FirebaseFirestore.instance
          .collection('maps')
          .doc(storeNumber)
          .get();

      if (!mapDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No saved map found for this store.')),
        );
        return;
      }

      final blocks = List<Map<String, dynamic>>.from(mapDoc['blocks'] ?? []);

      setState(() {
        for (var blockData in blocks) {
          final row = blockData['row'];
          final col = blockData['col'];
          final index = row * 30 + col;
          _matrix[index] = Block(
            color: Color(blockData['color']),
            name: blockData['name'],
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Map loaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading map: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchProductByLocation(String location) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('productLocation', isEqualTo: location)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching product: $e');
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchProductsByLocation(
      String location) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Fetch the user's storeNumber
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String storeNumber = userDoc['storeNumber'] ?? 'Unknown';

      // Query products with the same storeNumber and location
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('productLocation', isEqualTo: location)
          .where('storeNumber', isEqualTo: storeNumber)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching products: $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> _fetchProductById(String productId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Fetch the user's storeNumber
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String storeNumber = userDoc['storeNumber'] ?? 'Unknown';

      // Query product with the same storeNumber and productId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('productId', isEqualTo: productId)
          .where('storeNumber', isEqualTo: storeNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching product: $e');
      }
    }
    return null;
  }

  Future<void> _scanBarcode() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Barcode scanning is not supported on this platform.')),
      );
      return;
    }

    try {
      final String? barcode = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Scan Barcode'),
            ),
            body: MobileScanner(
              onDetect: (BarcodeCapture capture) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null) {
                  Navigator.of(context).pop(barcode.rawValue);
                }
              },
            ),
          ),
        ),
      );

      if (barcode == null) {
        return;
      }

      _productIdController.text = barcode;

      await _highlightBlockByProductId();
    } catch (e) {
      if (kDebugMode) {
        print('Error scanning barcode: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning barcode: $e')),
      );
    }
  }

  Future<void> _highlightBlockByProductId() async {
    final productId = _productIdController.text.trim();
    if (productId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a Product ID.')),
      );
      return;
    }

    try {
      final product = await _fetchProductById(productId);

      if (product != null) {
        final productLocation = product['productLocation'];

        final blockIndex =
            _matrix.indexWhere((block) => block.name == productLocation);

        if (blockIndex != -1) {
          setState(() {
            for (var block in _matrix) {
              if (block.name == null) {
                block.color = Colors.grey;
              } else {
                block.color = Colors.brown;
              }
            }

            _matrix[blockIndex].color = Colors.yellow;
          });

          showCupertinoDialog(
            context: context,
            builder: (context) {
              return CupertinoAlertDialog(
                title: Text('Product Found'),
                content: Column(
                  children: [
                    Text('Name: ${product['name'] ?? 'Unknown'}'),
                    Text('Brand: ${product['brand'] ?? 'Unknown'}'),
                    Text('Category: ${product['category'] ?? 'Unknown'}'),
                    Text('Stock: ${product['stockCurrent'] ?? 'Unknown'}'),
                    Text(
                        'Location: ${product['productLocation'] ?? 'Unknown'}'),
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    child: Text('Close'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('No block found for this product location.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No product found for this Product ID.')),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error searching for product: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching for product: $e')),
      );
    }
  }
}

class Block {
  Color color;
  String? name;

  Block({required this.color, this.name});
}
