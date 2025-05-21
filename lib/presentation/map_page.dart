// ignore_for_file: unused_element, unnecessary_cast, unused_field, use_key_in_widget_constructors, library_private_types_in_public_api, sort_child_properties_last, no_leading_underscores_for_local_identifiers, deprecated_member_use

import 'dart:ui';

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
  // A 30x30 grid of shelfs, each represented by a Block object
  final List<Block> _matrix = List.generate(
    30 * 30,
    (index) => Block(color: Colors.white30, name: null),
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
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            hexStringToColor("CB2B93"),
            hexStringToColor("9546C4"),
            hexStringToColor("5E61F4"),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: CupertinoPageScaffold(
        backgroundColor: Colors.transparent, // Important: transparent to see the gradient
        navigationBar: CupertinoNavigationBar(
          middle: const Text('Map View',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              )),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.cloud_upload, color: Colors.white),
                onPressed: _saveBlocksToFirebase,
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(CupertinoIcons.cloud_download, color: Colors.white),
                onPressed: _loadBlocksFromFirebase,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 5.0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32.0),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(32.0),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 30,
                            ),
                            itemCount: _matrix.length,
                            itemBuilder: (context, index) {
                              final block = _matrix[index];
                              final isSelected = _isMoveMode && _selectedBlockIndex == index;

                              return GestureDetector(
                                onTap: () => _onBlockTapped(index),
                                child: Container(
                                  margin: const EdgeInsets.all(0.5),
                                  color: isSelected
                                      ? Colors.blue
                                      : block.color,
                                  child: Center(
                                    child: Text(
                                      block.name ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}


  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _productIdController,
              placeholder: 'Enter Product ID',
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), // lower opacity
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              style: const TextStyle(
                color: Colors.white, // text color
              ),
              placeholderStyle: TextStyle(
                color: Colors.white.withOpacity(0.6), // placeholder color
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.search, size: 24, color: Colors.white),
            onPressed: _highlightBlockByProductId,
          ),
          const SizedBox(width: 8.0),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.camera, size: 24, color: Colors.white),
            onPressed: _scanBarcode,
          ),
        ],
      ),
    );
  }

  void _onBlockTapped(int index) async {
    final block = _matrix[index];

    if (_isMoveMode) {
      _handleMoveMode(index, block);
    } else {
      await _showBlockConfigurationDialog(index, block);
    }
  }

  void _handleMoveMode(int index, Block block) {
    if (_selectedBlockIndex != null && _selectedBlockIndex != index) {
      if (block.name == null) {
        setState(() {
          // Move the block to the new index
          _matrix[index] = Block(
            color: _matrix[_selectedBlockIndex!].color,
            name: _matrix[_selectedBlockIndex!].name,
          );
          // Reset the old block
          _matrix[_selectedBlockIndex!] = Block(color: Colors.white30, name: null);
          _isMoveMode = false; // Exit move mode
          _selectedBlockIndex = null; // Clear the selected block
        });
        _showSnackBar('Block moved successfully!');
      } else {
        _showSnackBar('Cannot move block to an occupied space.');
      }
    } else {
      _showSnackBar('Invalid move. Please select a valid block.');
    }
  }

  Future<void> _showBlockConfigurationDialog(int index, Block block) async {
    List<Map<String, dynamic>> products = [];
    if (block.name != null && block.name!.isNotEmpty) {
      products = await _fetchProductsByLocation(block.name!);
    }

    _nameController.text = block.name ?? '';

    showCupertinoDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: const Text('Configure Block'),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.5,
                child: Column(
                  children: [
                    CupertinoTextField(
                      controller: _nameController,
                      placeholder: 'Enter block name',
                    ),
                    const SizedBox(height: 16.0),
                    if (products.isNotEmpty) ...[
                      const Text('Products in this block:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8.0),
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
                                  Text('Brand: ${product['brand'] ?? 'Unknown'}'),
                                  Text('Category: ${product['category'] ?? 'Unknown'}'),
                                  Text('Stock: ${product['stockCurrent'] ?? 'Unknown'}'),
                                  Text('Locations: ${product['productLocations']?.join(', ') ?? 'Unknown'}'),
                                  const Divider(),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ] else
                      const Text('No products found in this block.'),
                  ],
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Move Block'),
                  onPressed: () {
                    setState(() {
                      _isMoveMode = true; // Enable move mode
                      _selectedBlockIndex = index; // Set the selected block
                    });
                    Navigator.of(context).pop(); // Close the dialog
                    _showSnackBar('Select an empty space to move the block.');
                  },
                ),
                CupertinoDialogAction(
                  child: const Text('Delete Block',
                      style: TextStyle(color: CupertinoColors.destructiveRed)),
                  onPressed: () {
                    setState(() {
                      block.name = null;
                      block.color = Colors.white30;
                    });
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
                CupertinoDialogAction(
                  child: const Text('Save',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeBlue)),
                  onPressed: () {
                    setState(() {
                      block.name = _nameController.text;
                      block.color = Colors.brown; // Indicate the block is occupied
                    });
                    Navigator.of(context).pop();
                  },
                ),
                CupertinoDialogAction(
                  child: const Text('Cancel'),
                  onPressed: () {
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<List<Map<String, dynamic>>> _fetchProductsByLocation(String location) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      String storeNumber = userDoc['storeNumber'] ?? 'Unknown';

      // Query products where the location is in the productLocations array
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('productLocations', arrayContains: location)
          .where('storeNumber', isEqualTo: storeNumber)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching products: $e');
      return [];
    }
  }

  Future<void> _highlightBlockByProductId() async {
    final productId = _productIdController.text.trim();
    if (productId.isEmpty) {
      _showSnackBar('Please enter a Product ID.');
      return;
    }

    try {
      final product = await _fetchProductById(productId);

      if (product != null) {
        final productLocations = List<String>.from(product['productLocations'] ?? []);

        setState(() {
          _resetBlockColors(); // Reset all block colors

          // Highlight blocks corresponding to the product's locations
          for (var location in productLocations) {
            for (int i = 0; i < _matrix.length; i++) {
              if (_matrix[i].name == location) {
                _matrix[i].color = Colors.yellow;
              }
            }
          }
        });

        showCupertinoDialog(
          context: context,
          builder: (context) {
            return CupertinoAlertDialog(
              title: const Text('Product Found'),
              content: Column(
                children: [
                  Text('Name: ${product['name'] ?? 'Unknown'}'),
                  Text('Brand: ${product['brand'] ?? 'Unknown'}'),
                  Text('Category: ${product['category'] ?? 'Unknown'}'),
                  Text('Stock: ${product['stockCurrent'] ?? 'Unknown'}'),
                  Text('Locations: ${productLocations.join(', ')}'),
                ],
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        _showSnackBar('No product found for this Product ID.');
      }
    } catch (e) {
      _showSnackBar('Error searching for product: $e');
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
              entry.value.name != null || entry.value.color != Colors.white30)
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

      _showSnackBar('Map saved successfully!');
    } catch (e) {
      _showSnackBar('Error saving map: $e');
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
        _showSnackBar('No saved map found for this store.');
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

      _showSnackBar('Map loaded successfully!');
    } catch (e) {
      _showSnackBar('Error loading map: $e');
    }
  }

  void _resetBlockColors() {
    for (var block in _matrix) {
      block.color = block.name == null ? Colors.white30 : Colors.brown;
    }
  }
}

class Block {
  Color color;
  String? name;

  Block({required this.color, this.name});
}

Color hexStringToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor";
  }
  return Color(int.parse(hexColor, radix: 16));
}