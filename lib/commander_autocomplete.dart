import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'scryfall_service.dart';

class CommanderAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool isPartner;

  const CommanderAutocomplete({
    super.key,
    required this.controller,
    required this.labelText,
    this.isPartner = false,
  });

  Future<List<String>> _getSuggestions(String pattern) async {
    return ScryfallService.searchCards(pattern, isPartner: isPartner);
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      suggestionsCallback: _getSuggestions,
      builder: (context, controller, primaryFocus) {
        return TextField(
          controller: controller,
          focusNode: primaryFocus,
          decoration: InputDecoration(
            labelText: labelText,
            border: const OutlineInputBorder(),
          ),
        );
      },
      controller: controller,
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion),
        );
      },
      onSelected: (suggestion) {
        controller.text = suggestion;
      },
    );
  }
}
