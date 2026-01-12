import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'scryfall_service.dart';

class CommanderAutocomplete extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool isPartner;
  final bool unconventionalCommanders;

  const CommanderAutocomplete({
    super.key,
    required this.controller,
    required this.labelText,
    this.isPartner = false,
    this.unconventionalCommanders = false,
  });

  Future<List<String>> _getSuggestions(String pattern) async {
    return ScryfallService.searchCards(
      pattern,
      isPartner: isPartner,
      unconventionalCommanders: unconventionalCommanders,
    );
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
