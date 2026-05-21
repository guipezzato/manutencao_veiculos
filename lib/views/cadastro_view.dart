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
  late TextEditingController custo;
  late TextEditingController km;

  @override
  void initState() {
    super.initState();

    veiculo = TextEditingController(
      text: widget.manutencaoParaEdicao?.veiculo ?? '',
    );

    descricao = TextEditingController(
      text: widget.manutencaoParaEdicao?.descricao ?? '',
    );

    custo = TextEditingController(
      text: widget.manutencaoParaEdicao?.custo?.toString() ?? '',
    );

    km = TextEditingController(
      text: widget.manutencaoParaEdicao?.km?.toString() ?? '',
    );
  }

  void salvar() async {
    final m = Manutencao(
      id: widget.manutencaoParaEdicao?.id,
      veiculo: veiculo.text,
      descricao: descricao.text,
      data: DateTime.now(),
      custo: double.tryParse(custo.text),
      km: int.tryParse(km.text),
      status: 'pendente',
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
            TextField(controller: custo, decoration: const InputDecoration(labelText: 'Custo'), keyboardType: TextInputType.number,),
            TextField(controller: km, decoration: const InputDecoration(labelText: 'KM'), keyboardType: TextInputType.number,),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: salvar, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }
}