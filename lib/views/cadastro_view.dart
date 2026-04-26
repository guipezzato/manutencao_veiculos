import 'package:flutter/material.dart';
import 'package:manutencao_veiculos/controllers/manutencao_controller.dart';
import 'package:manutencao_veiculos/models/manutencao.dart';

class CadastroView extends StatefulWidget {
  final Manutencao? manutencaoParaEdicao; // <--- NOVA LINHA

  const CadastroView({super.key, this.manutencaoParaEdicao}); // <--- CONSTRUTOR ATUALIZADO

  @override
  State<CadastroView> createState() => _CadastroViewState();
}

class _CadastroViewState extends State<CadastroView> {
  final controller = ManutencaoController();

  late TextEditingController veiculo;
  late TextEditingController descricao;
  late TextEditingController data;
  late TextEditingController valor;

  @override
  void initState() {
    super.initState();
    // Preenche os campos se for edição, senão deixa vazio
    veiculo = TextEditingController(text: widget.manutencaoParaEdicao?.veiculo ?? '');
    descricao = TextEditingController(text: widget.manutencaoParaEdicao?.descricao ?? '');
    data = TextEditingController(text: widget.manutencaoParaEdicao?.data ?? '');
    valor = TextEditingController(text: widget.manutencaoParaEdicao?.valor.toString() ?? '');
  }

  void salvar() async {
    final m = Manutencao(
      id: widget.manutencaoParaEdicao?.id, // Importante: mantém o ID na edição
      veiculo: veiculo.text,
      descricao: descricao.text,
      data: data.text,
      valor: double.tryParse(valor.text) ?? 0.0,
    );

    if (widget.manutencaoParaEdicao == null) {
      await controller.inserir(m);
    } else {
      await controller.atualizar(m);
    }

    if (mounted) Navigator.pop(context, true); // Retorna true para atualizar a lista
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.manutencaoParaEdicao == null ? 'Cadastro' : 'Editar')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: veiculo, decoration: const InputDecoration(labelText: 'Veículo')),
            TextField(controller: descricao, decoration: const InputDecoration(labelText: 'Descrição')),
            TextField(controller: data, decoration: const InputDecoration(labelText: 'Data')),
            TextField(controller: valor, decoration: const InputDecoration(labelText: 'Valor'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: salvar, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }
}