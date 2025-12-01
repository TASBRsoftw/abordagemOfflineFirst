import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shopping_list.dart';

class ApiService {
  final String baseUrl = 'http://localhost:3000'; // Ajuste conforme necessário

  Future<List<ShoppingList>> fetchShoppingLists() async {
    final response = await http.get(Uri.parse('$baseUrl/lists'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => ShoppingList.fromMap(e)).toList();
    }
    throw Exception('Erro ao buscar listas');
  }

  // Métodos para CRUD de listas e produtos
  // ...
}
