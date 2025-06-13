// lib/services/product_cache_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ProdutoCacheService {
  static const _chaveProdutos = 'produtos_loja';
  static const _chaveUltimaAtualizacao = 'ultima_atualizacao';
  static const _chaveUltimaCriacao = 'ultima_criacao_verificada';

  /// Salva produtos filtrando pelo storeNumber do utilizador
  static Future<void> salvarProdutosFiltradosNoCache(
      List<Map<String, dynamic>> todosProdutos, String storeNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Carrega produtos já armazenados
    final jsonStringExistente = prefs.getString(_chaveProdutos);
    List<Map<String, dynamic>> produtosExistentes = [];
    if (jsonStringExistente != null) {
      final decoded = jsonDecode(jsonStringExistente);
      produtosExistentes = List<Map<String, dynamic>>.from(decoded);
    }

    // Conjunto dos IDs já em cache
    final idsExistentes = produtosExistentes.map((p) => p['productId']).toSet();

    // Filtra os novos produtos da loja do usuário que ainda não estão em cache
    final novosProdutos = todosProdutos
        .where((p) =>
            p['storeNumber'] == storeNumber &&
            !idsExistentes.contains(p['productId']))
        .toList();

    if (novosProdutos.isEmpty) return;

    // Converter os campos Timestamp para string ISO
    List<Map<String, dynamic>> novosProdutosSerializados =
        novosProdutos.map((produto) {
      final Map<String, dynamic> produtoSerializado = Map.from(produto);

      produtoSerializado.forEach((key, value) {
        if (value is Timestamp) {
          produtoSerializado[key] = value.toDate().toIso8601String();
        }
      });

      return produtoSerializado;
    }).toList();

    // Adiciona os novos produtos serializados ao cache existente
    final todosAtualizados = [
      ...produtosExistentes,
      ...novosProdutosSerializados
    ];
    final jsonStringAtualizado = jsonEncode(todosAtualizados);

    await prefs.setString(_chaveProdutos, jsonStringAtualizado);
    await prefs.setString(_chaveUltimaAtualizacao, hoje);

    // Atualiza a maior data de criação verificada
    final maioresDatas = todosProdutos
        .map((p) => p['createdAt'])
        .whereType<Timestamp>()
        .map((t) => t.toDate())
        .toList();

    if (maioresDatas.isNotEmpty) {
      maioresDatas.sort();
      final maisRecente = maioresDatas.last.toIso8601String();
      await prefs.setString(_chaveUltimaCriacao, maisRecente);
    }
  }

  /// Retorna a lista de produtos em cache como lista de mapas
  static Future<List<Map<String, dynamic>>> obterProdutosDoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_chaveProdutos);
    if (jsonString == null) return [];
    final decoded = jsonDecode(jsonString);
    return List<Map<String, dynamic>>.from(decoded);
  }

  /// Verifica se é necessário atualizar os produtos (1x por dia)
  static Future<bool> precisaAtualizarProdutos() async {
    final prefs = await SharedPreferences.getInstance();
    final ultima = prefs.getString(_chaveUltimaAtualizacao);
    final hoje = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return ultima != hoje;
  }

  /// Busca apenas os produtos criados após a última verificação
  Future<List<Object?>> buscarProdutosDoFirebase() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimaCriacao = prefs.getString(_chaveUltimaCriacao);

    Query query = FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: false);

    if (ultimaCriacao != null) {
      final ultimaData = DateTime.parse(ultimaCriacao);
      query = query.where('createdAt',
          isGreaterThan: Timestamp.fromDate(ultimaData));
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['productId'] = doc.id;
      return data;
    }).toList();
  }

  // NOVO método para remover produto do cache pelo nome
  static Future<void> removerProdutoDoCache(String nomeProduto) async {
    final prefs = await SharedPreferences.getInstance();
    final produtosJson =
        prefs.getString(_chaveProdutos); // Usar _chaveProdutos aqui

    if (produtosJson == null) return; // Nada a remover

    final List<dynamic> produtosList = jsonDecode(produtosJson);
    final List<Map<String, dynamic>> produtos =
        produtosList.cast<Map<String, dynamic>>();

    // Remove o produto com o nome igual ao passado (ignorando case e espaços)
    produtos.removeWhere((produto) {
      final nome = (produto['name'] ?? '').toString().trim().toLowerCase();
      return nome == nomeProduto.trim().toLowerCase();
    });

    // Salva a lista atualizada no cache
    final jsonAtualizado = jsonEncode(produtos);
    await prefs.setString(_chaveProdutos, jsonAtualizado);
  }
}
