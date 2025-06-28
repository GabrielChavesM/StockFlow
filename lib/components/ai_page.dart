import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';
import '../services/product_cache_service.dart';

class RecomendacoesStore {
  static final List<Map<String, String>> recomendacoes = [];
}

class AIChatPage extends StatefulWidget {
  @override
  _AIChatPageState createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final _produtoController = TextEditingController();
  final _ocasiaoController = TextEditingController();
  final _budgetController = TextEditingController();
  final _marcaController = TextEditingController();
  final _lifestyleController = TextEditingController();
  final _tempoUsoController = TextEditingController();
  final _regiaoController = TextEditingController();
  final _tecnologiaController = TextEditingController();

  static const _prefsKeys = {
    'produto': 'ctrl_produto',
    'ocasiao': 'ctrl_ocasiao',
    'budget': 'ctrl_budget',
    'marca': 'ctrl_marca',
    'lifestyle': 'ctrl_lifestyle',
    'tempoUso': 'ctrl_tempoUso',
    'regiao': 'ctrl_regiao',
    'tecnologia': 'ctrl_tecnologia',
  };

  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? "";
  final String _groqEndpoint =
      "https://api.groq.com/openai/v1/chat/completions";

  List<Map<String, String>> _recomendacoes = [];

  @override
  void initState() {
    super.initState();
    _atualizarCacheSeNecessario();
    _recomendacoes =
        List<Map<String, String>>.from(RecomendacoesStore.recomendacoes);
    _carregarControllersDoCache();
    _adicionarListenersParaSalvar();
  }

  void _adicionarListenersParaSalvar() {
    _produtoController.addListener(
        () => _salvarControllerNoCache('produto', _produtoController.text));
    _ocasiaoController.addListener(
        () => _salvarControllerNoCache('ocasiao', _ocasiaoController.text));
    _budgetController.addListener(
        () => _salvarControllerNoCache('budget', _budgetController.text));
    _marcaController.addListener(
        () => _salvarControllerNoCache('marca', _marcaController.text));
    _lifestyleController.addListener(
        () => _salvarControllerNoCache('lifestyle', _lifestyleController.text));
    _tempoUsoController.addListener(
        () => _salvarControllerNoCache('tempoUso', _tempoUsoController.text));
    _regiaoController.addListener(
        () => _salvarControllerNoCache('regiao', _regiaoController.text));
    _tecnologiaController.addListener(() =>
        _salvarControllerNoCache('tecnologia', _tecnologiaController.text));
  }

  Future<void> _salvarControllerNoCache(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeys[key]!, value);
  }

  Future<void> _carregarControllersDoCache() async {
    final prefs = await SharedPreferences.getInstance();

    _produtoController.text = prefs.getString(_prefsKeys['produto']!) ?? '';
    _ocasiaoController.text = prefs.getString(_prefsKeys['ocasiao']!) ?? '';
    _budgetController.text = prefs.getString(_prefsKeys['budget']!) ?? '';
    _marcaController.text = prefs.getString(_prefsKeys['marca']!) ?? '';
    _lifestyleController.text = prefs.getString(_prefsKeys['lifestyle']!) ?? '';
    _tempoUsoController.text = prefs.getString(_prefsKeys['tempoUso']!) ?? '';
    _regiaoController.text = prefs.getString(_prefsKeys['regiao']!) ?? '';
    _tecnologiaController.text =
        prefs.getString(_prefsKeys['tecnologia']!) ?? '';
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _ocasiaoController.dispose();
    _budgetController.dispose();
    _marcaController.dispose();
    _lifestyleController.dispose();
    _tempoUsoController.dispose();
    _regiaoController.dispose();
    _tecnologiaController.dispose();
    super.dispose();
  }

  Future<void> _atualizarCacheSeNecessario() async {
    final precisaAtualizar =
        await ProdutoCacheService.precisaAtualizarProdutos();

    if (precisaAtualizar) {
      final storeNumber = await _fetchUserStoreNumber();
      final produtosFirebase = await buscarProdutosDoFirebase();

      await ProdutoCacheService.salvarProdutosFiltradosNoCache(
          produtosFirebase, storeNumber);
    }
  }

  Future<String> _fetchUserStoreNumber() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data()!.containsKey('storeNumber')) {
        return userDoc['storeNumber'] as String;
      }
    }
    return '';
  }

  Future<List<Map<String, dynamic>>> buscarProdutosDoFirebase() async {
    final querySnapshot =
        await FirebaseFirestore.instance.collection('products').get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> enviarParaGroq(String prompt) async {
    final produtosCache = await ProdutoCacheService.obterProdutosDoCache();

    if (produtosCache.isEmpty) {
      setState(() {
        _recomendacoes.clear();
        _recomendacoes.add({
          "nome": "Erro",
          "motivo": "Nenhum produto disponível na loja para recomendação."
        });
        RecomendacoesStore.recomendacoes
          ..clear()
          ..addAll(_recomendacoes);
      });
      return;
    }

    // Filter products based on relevance to the user's input
    final nomesProdutos = produtosCache
        .map((p) => p['name']?.toString().trim())
        .where((nome) => nome != null && nome.isNotEmpty)
        .toSet()
        .toList();

    final filteredProdutos = nomesProdutos.where((nome) {
      final lowerNome = nome!.toLowerCase();
      return lowerNome.contains(_produtoController.text.toLowerCase()) ||
           lowerNome.contains(_marcaController.text.toLowerCase()) ||
           lowerNome.contains(_lifestyleController.text.toLowerCase());
    }).toList();

    // Use filtered products in the prompt
    final promptFinal = '''
Based on the information below, recommend only product names and a brief sentence explaining why this choice is ideal. Be direct and objective. List one recommendation per line, in the format: Product Name: brief explanation.

IMPORTANT: Only choose from this list of products available in store:
${filteredProdutos.join(', ')}
IMPORTANT: If no products match with the customer's needs or no products with those names are available in store, return an empty list of recommendations, do not reply with anything else.

- Product that the customer has: ${_produtoController.text}
- Occasion or utility: ${_ocasiaoController.text}
- Estimated budget: ${_budgetController.text}
- Brand or brand preference: ${_marcaController.text}
- Lifestyle and usability: ${_lifestyleController.text}
- Current usage time of the product: ${_tempoUsoController.text}
- Region of use: ${_regiaoController.text}
- Technological requirements and compatibility: ${_tecnologiaController.text}

If the products in the store do not match the customer's needs, return an empty message, nothing else.

IMPORTANT: DO NOT send any output with the following: "Looking at the available products in the store, Looking at products avaible, Looking at the products in the store, etc ..."

Only the recommendations, in the format: Product Name: brief explanation.
Do not send duplicated recommendations, only unique products.
IMPORTANT: DO NOT include any phrases such as "Looking at the available products in the store", "Looking at products available", "Looking at the products in the store" or similar expressions in the response.

ONLY return the recommendations, exactly in the format:
Product Name: brief explanation.

If the products in the store do not match the customer's needs, return an empty message, NOTHING ELSE.
''';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = jsonEncode({
      "model": "deepseek-r1-distill-llama-70b",
      "messages": [
        {"role": "user", "content": promptFinal}
      ],
    });

    final response = await http.post(
      Uri.parse(_groqEndpoint),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      String resposta = data['choices'][0]['message']['content'] as String;

      resposta = resposta.replaceAll(RegExp(r'<\/?think>|(Looking at the products available|Considering the products in the store|Looking at products available|Looking at the available products in the store|In the store)'), '');

      final linhas = resposta
          .trim()
          .split('\n')
          .map((linha) => linha.trim())
          .where((linha) => RegExp(r'^[\w\s]{2,}[:\-–]\s+').hasMatch(linha)) // Filtra linhas no formato esperado
          .where((linha) {
            final titulo = linha.split(RegExp(r'[:\-–]')).first.trim();
            return filteredProdutos.contains(titulo); // Verifica se o título está em filteredProdutos
          })
          .toList();

      final recomendacoes = linhas.map((linha) {
        final partes = linha.split(RegExp(r'[:\-–]'));
        final nome = partes.first.trim();
        final motivo =
            partes.length > 1 ? partes.sublist(1).join('-').trim() : '';
        return {"nome": nome, "motivo": motivo};
      }).toList();

      setState(() {
        _recomendacoes.clear();
        _recomendacoes.addAll(recomendacoes);
        RecomendacoesStore.recomendacoes
          ..clear()
          ..addAll(recomendacoes); // Persist in memory
      });
    } else {
      setState(() {
        _recomendacoes.clear();
        _recomendacoes.add({"nome": "Erro", "motivo": response.body});
        RecomendacoesStore.recomendacoes
          ..clear()
          ..add({"nome": "Erro", "motivo": response.body});
      });
    }
  }

  void gerarPromptEEnviar() {
    // Conta quantos campos têm texto não vazio
    int filledFields = 0;
    if (_produtoController.text.trim().isNotEmpty) filledFields++;
    if (_ocasiaoController.text.trim().isNotEmpty) filledFields++;
    if (_budgetController.text.trim().isNotEmpty) filledFields++;
    if (_marcaController.text.trim().isNotEmpty) filledFields++;
    if (_lifestyleController.text.trim().isNotEmpty) filledFields++;
    if (_tempoUsoController.text.trim().isNotEmpty) filledFields++;
    if (_regiaoController.text.trim().isNotEmpty) filledFields++;
    if (_tecnologiaController.text.trim().isNotEmpty) filledFields++;

    if (filledFields < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please fill at least 3 fields to receive recommendations.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey[800],
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final prompt = '''
Based on the information below, recommend only product names and a brief sentence explaining why this choice is ideal. Be direct and objective. List one recommendation per line, in the format: Product Name: brief explanation.

- Product that the customer has: ${_produtoController.text}
- Occasion or utility: ${_ocasiaoController.text}
- Estimated budget: ${_budgetController.text}
- Brand or brand preference: ${_marcaController.text}
- Lifestyle and usability: ${_lifestyleController.text}
- Current usage time of the product: ${_tempoUsoController.text}
- Region of use: ${_regiaoController.text}
- Technological requirements and compatibility: ${_tecnologiaController.text}
''';

    enviarParaGroq(prompt);
  }

  Widget campoTexto(String label, TextEditingController controller) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Color hexStringToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse('0x$hex'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title:
            const Text("AI Assistant", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              hexStringToColor("CB2B93"),
              hexStringToColor("9546C4"),
              hexStringToColor("5E61F4"),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    SizedBox(
                        width: 180,
                        height: 65,
                        child: campoTexto("Owned Product", _produtoController)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 180,
                        height: 65,
                        child: campoTexto(
                            "Ocasion of change", _ocasiaoController)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 120,
                        height: 65,
                        child: campoTexto("Budget", _budgetController)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 180,
                        height: 65,
                        child: campoTexto("Brand", _marcaController)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 180,
                        height: 65,
                        child: campoTexto("Lifestyle", _lifestyleController)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 180,
                        height: 65,
                        child: campoTexto("Usage Time", _tempoUsoController)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 180,
                        height: 65,
                        child: campoTexto("Region", _regiaoController)),
                    const SizedBox(width: 8),
                    SizedBox(
                        width: 180,
                        height: 65,
                        child: campoTexto("Technology", _tecnologiaController)),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ElevatedButton.icon(
                  onPressed: gerarPromptEEnviar,
                  icon: const Icon(Icons.recommend),
                  label: const Text("Recommend Products"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    backgroundColor: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
              const Divider(height: 1, color: Colors.white38),
              Expanded(
                child: _recomendacoes.isEmpty
                    ? const Center(
                        child: Text("No recomendations yet.",
                            style: TextStyle(color: Colors.white)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _recomendacoes.length,
                        itemBuilder: (context, index) {
                          final rec = _recomendacoes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context, rec["nome"]);
                              },
                              onLongPress: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Removal'),
                                    content: Text(
                                        'Do you want to delete the product "${rec["nome"]}" from cache memory?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await ProdutoCacheService
                                      .removerProdutoDoCache(rec["nome"]!);
                                  Navigator.pop(context, rec["nome"]);
                                }
                              },
                              child: ElevatedButton(
                                onPressed:
                                    null, // Desativa o onPressed do ElevatedButton
                                style: ButtonStyle(
                                  padding: MaterialStateProperty.all(
                                      const EdgeInsets.all(16)),
                                  backgroundColor: MaterialStateProperty.all(
                                      Colors.white.withOpacity(0.85)),
                                  foregroundColor:
                                      MaterialStateProperty.all(Colors.black87),
                                  shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  elevation: MaterialStateProperty.all(1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rec["nome"] ?? "Produto",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      rec["motivo"] ?? "",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
