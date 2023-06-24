import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum TableStatus { idle, loading, ready, error }

enum ItemType { beer, coffee, nation, none }

class DataService {
  static const MAX_N_ITEMS = 15;
  static const MIN_N_ITEMS = 3;
  static const DEFAULT_N_ITEMS = 7;

  int _numberOfItems = DEFAULT_N_ITEMS;

  set numberOfItems(n) {
    _numberOfItems = n <= 0
        ? MIN_N_ITEMS
        : n > MAX_N_ITEMS
            ? MAX_N_ITEMS
            : n;
  }

  int get numberOfItems {
    return _numberOfItems;
  }

  final ValueNotifier<Map<String, dynamic>> tableStateNotifier = ValueNotifier({
    'status': TableStatus.idle,
    'dataObjects': [],
    'itemType': ItemType.none,
  });

  void carregar(int index) {
    if (tableStateNotifier.value['status'] == TableStatus.loading) return;

    ItemType itemType;
    List<String> propertyNames;
    List<String> columnNames;
    String path;

    switch (index) {
      case 0:
        itemType = ItemType.coffee;
        propertyNames = ["blend_name", "origin", "variety"];
        columnNames = ["Nome", "Origem", "Tipo"];
        path = 'api/coffee/random_coffee';
        break;
      case 1:
        itemType = ItemType.beer;
        propertyNames = ["name", "style", "ibu"];
        columnNames = ["Nome", "Estilo", "IBU"];
        path = 'api/beer/random_beer';
        break;
      case 2:
        itemType = ItemType.nation;
        propertyNames = [
          "nationality",
          "capital",
          "language",
          "national_sport"
        ];
        columnNames = ["Nome", "Capital", "Idioma", "Esporte"];
        path = 'api/nation/random_nation';
        break;
      default:
        return;
    }

    if (tableStateNotifier.value['itemType'] != itemType) {
      tableStateNotifier.value = {
        'status': TableStatus.loading,
        'dataObjects': [],
        'itemType': itemType,
      };
    }

    var uri = Uri(
      scheme: 'https',
      host: 'random-data-api.com',
      path: path,
      queryParameters: {'size': '$_numberOfItems'},
    );

    http.read(uri).then((jsonString) {
      var itemsJson = jsonDecode(jsonString);

      if (tableStateNotifier.value['status'] != TableStatus.loading) {
        itemsJson = [...tableStateNotifier.value['dataObjects'], ...itemsJson];
      }

      tableStateNotifier.value = {
        'itemType': itemType,
        'status': TableStatus.ready,
        'dataObjects': itemsJson,
        'propertyNames': propertyNames,
        'columnNames': columnNames,
      };
    });
  }
}

final dataService = DataService();
