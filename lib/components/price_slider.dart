// ignore_for_file: prefer_const_constructors_in_immutables, use_key_in_widget_constructors, library_private_types_in_public_api

import 'package:flutter/material.dart';

class PriceRangeSlider extends StatefulWidget {
  final ValueChanged<RangeValues> onChanged; // Callback para passar os valores

  PriceRangeSlider({required this.onChanged});

  @override
  _PriceRangeSliderState createState() => _PriceRangeSliderState();
}

class _PriceRangeSliderState extends State<PriceRangeSlider> {
  // Definindo os limites do intervalo de preços
  RangeValues _priceRange = RangeValues(0, 1000);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            "Select Price Range",
            style: TextStyle(color: Colors.black),
          ),
        ),

        // O RangeSlider com valores mínimos e máximos
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 5000,
          divisions: 100,
          labels: RangeLabels(
            _priceRange.start.round().toString(),
            _priceRange.end.round().toString(),
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _priceRange = values; // Atualiza os valores ao mover o slider
            });
            widget.onChanged(
                values); // Chama o callback para atualizar o valor no FilterPage
          },
        ),

        // Exibindo o intervalo de preços selecionado
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Price: ${_priceRange.start.round()} - ${_priceRange.end.round()}',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
