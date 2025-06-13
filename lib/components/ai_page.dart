import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';

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

  final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? "";
  final String _groqEndpoint =
      "https://api.groq.com/openai/v1/chat/completions";

  List<Map<String, String>> _recomendacoes = [];

  @override
  void initState() {
    super.initState();
    // Load previous in-memory recommendations
    _recomendacoes = List<Map<String, String>>.from(RecomendacoesStore.recomendacoes);
  }

  Future<void> enviarParaGroq(String prompt) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_apiKey',
    };

    final body = jsonEncode({
      "model": "deepseek-r1-distill-llama-70b",
      "messages": [
        {"role": "user", "content": prompt}
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

      resposta = resposta.replaceAll(RegExp(r'<\/?think>'), '');

      final linhas = resposta
          .trim()
          .split('\n')
          .map((linha) => linha.trim())
          .where((linha) => RegExp(r'^[\w\s]{2,}[:\-–]\s+').hasMatch(linha))
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
        title: const Text("AI Assistant", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
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
                    SizedBox(width: 180, height: 65, child: campoTexto("Owned Product", _produtoController)),
                    const SizedBox(width: 8),
                    SizedBox(width: 180, height: 65, child: campoTexto("Ocasion of change", _ocasiaoController)),
                    const SizedBox(width: 8),
                    SizedBox(width: 120, height: 65, child: campoTexto("Budget", _budgetController)),
                    const SizedBox(width: 8),
                    SizedBox(width: 180, height: 65, child: campoTexto("Brand", _marcaController)),
                    const SizedBox(width: 8),
                    SizedBox(width: 180, height: 65, child: campoTexto("Lifestyle", _lifestyleController)),
                    const SizedBox(width: 8),
                    SizedBox(width: 180, height: 65, child: campoTexto("Usage Time", _tempoUsoController)),
                    const SizedBox(width: 8),
                    SizedBox(width: 180, height: 65, child: campoTexto("Region", _regiaoController)),
                    const SizedBox(width: 8),
                    SizedBox(width: 180, height: 65, child: campoTexto("Technology", _tecnologiaController)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ElevatedButton.icon(
                  onPressed: gerarPromptEEnviar,
                  icon: const Icon(Icons.recommend),
                  label: const Text("Recommend Products"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, rec["nome"]);
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                backgroundColor: Colors.blueGrey[50],
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 1,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec["nome"] ?? "Produto",
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    rec["motivo"] ?? "",
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
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
