import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shopping_list.dart';

class ApiService {
          Future<Product?> fetchProductById(String id) async {
            // Implementação mock: retorne null ou um Product conforme necessário
            return null;
          }

          Future<void> updateProduct(Product product) async {
            // Implementação mock: não faz nada
            return;
          }

          Future<void> addProduct(Product product) async {
            // Implementação mock: não faz nada
            return;
          }
        Future<void> addItemToList(String listId, Product product) async {
            print('[ApiService] addItemToList called: baseUrl=\'$baseUrl\', listId=\'$listId\', product=\'${product.toMap()}\'');
            final response = await http.post(
              Uri.parse('$baseUrl/lists/$listId/items'),
              headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer qualquercoisa'},
              body: jsonEncode({
                'itemId': product.itemId,
                'itemName': product.itemName,
                'quantity': product.quantity,
                'unit': product.unit,
                'estimatedPrice': product.estimatedPrice,
                'purchased': product.purchased,
                'notes': product.notes,
                'addedAt': product.addedAt.toIso8601String(),
                'updatedAt': product.updatedAt.toIso8601String(),
              }),
            );
            print('[ApiService] Response status: \'${response.statusCode}\', body: \'${response.body}\'');
            if (response.statusCode != 201) {
              throw Exception('Erro ao adicionar item à lista');
            }
          }
      Future<void> deleteItemFromList(String listId, String itemId) async {
        final response = await http.delete(
          Uri.parse('$baseUrl/lists/$listId/items/$itemId'),
          headers: {'Authorization': 'Bearer qualquercoisa'},
        );
        if (response.statusCode != 200) {
          throw Exception('Erro ao excluir item da lista');
        }
      }
    Future<void> deleteShoppingList(String id) async {
      final response = await http.delete(
        Uri.parse('$baseUrl/lists/$id'),
        headers: {'Authorization': 'Bearer qualquercoisa'},
      );
      if (response.statusCode != 200) {
        throw Exception('Erro ao excluir lista');
      }
    }
  Future<void> createShoppingList(String name, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/lists'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer qualquercoisa'},
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Erro ao criar lista');
    }
  }
  static const String baseUrl = 'http://10.0.2.2:3002'; // IP especial para emulador Android

  Future<List<ShoppingList>> fetchShoppingLists() async {
    final response = await http.get(
      Uri.parse('$baseUrl/lists'),
      headers: {'Authorization': 'Bearer qualquercoisa'},
    );
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded['data'] as List? ?? [];
      return data.map((e) => ShoppingList.fromMap(e)).toList();
    }
    throw Exception('Erro ao buscar listas');
  }

  // Métodos para CRUD de listas e produtos
  // ...
}
