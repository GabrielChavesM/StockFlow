// ignore_for_file: use_super_parameters, deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicFilterForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController brandController;
  final TextEditingController categoryController;
  final TextEditingController storeNumberController;
  final Widget? dropdownWidget;
  final VoidCallback? onChanged;

  const GlassmorphicFilterForm({
    Key? key,
    required this.nameController,
    required this.brandController,
    required this.categoryController,
    required this.storeNumberController,
    this.dropdownWidget,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 2,
                offset: Offset(-5, -5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
                offset: Offset(5, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(nameController, 'Name'),
              _buildTextField(brandController, 'Brand'),
              _buildTextField(categoryController, 'Category'),
              _buildTextField(storeNumberController, 'Filter by store number', enabled: false),
              if (dropdownWidget != null) dropdownWidget!,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(
        controller: controller,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        onChanged: (_) => onChanged?.call(), // Chama setState do pai
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 12.0),
        ),
      ),
    );
  }
}
