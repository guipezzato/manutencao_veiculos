import 'package:flutter/material.dart';
import 'package:manutencao_veiculos/controllers/manutencao_controller.dart';
import 'package:manutencao_veiculos/models/manutencao.dart';

class CadastroView extends StatefulWidget {
  final Manutencao? manutencaoParaEdicao;
  // Callback usado quando CadastroView é uma aba do IndexedStack
  // Se for null, usa Navigator.pop (para uso como tela empilhada no futuro)
  final VoidCallback? onSaved;

  const CadastroView({super.key, this.manutencaoParaEdicao, this.onSaved});

  @override
  State<CadastroView> createState() => _CadastroViewState();
}

class _CadastroViewState extends State<CadastroView> {
  final controller = ManutencaoController();

  late TextEditingController veiculo;
  late TextEditingController descricao;
  late TextEditingController custo;
  late TextEditingController km;

  bool _estaSalvando = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
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

  @override
  void dispose() {
    veiculo.dispose();
    descricao.dispose();
    custo.dispose();
    km.dispose();
    super.dispose();
  }

  void _limparFormulario() {
    veiculo.clear();
    descricao.clear();
    custo.clear();
    km.clear();
  }

  void salvar() async {
    if (_estaSalvando) return;

    if (veiculo.text.isEmpty || descricao.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o veículo e a descrição.')),
      );
      return;
    }

    setState(() => _estaSalvando = true);

    final m = Manutencao(
      id: widget.manutencaoParaEdicao?.id,
      veiculo: veiculo.text.trim(),
      descricao: descricao.text.trim(),
      data: widget.manutencaoParaEdicao?.data ?? DateTime.now(),
      custo: double.tryParse(custo.text.replaceAll(',', '.')),
      km: int.tryParse(km.text),
      status: widget.manutencaoParaEdicao?.status ?? 'pendente',
    );

    try {
      if (widget.manutencaoParaEdicao == null) {
        await controller.inserir(m);
      } else {
        await controller.atualizar(m);
      }

      if (!mounted) return;

      // Mostra feedback de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manutenção salva com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      if (widget.onSaved != null) {
        // Modo aba: limpa o formulário e avisa o MainShell
        _limparFormulario();
        widget.onSaved!();
      } else {
        // Modo rota empilhada: volta para a tela anterior normalmente
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _estaSalvando = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar no banco: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _estaSalvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.manutencaoParaEdicao == null ? 'Cadastro' : 'Editar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: veiculo,
              decoration: const InputDecoration(labelText: 'Veículo'),
            ),
            TextField(
              controller: descricao,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            TextField(
              controller: custo,
              decoration: const InputDecoration(labelText: 'Custo (R\$)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: km,
              decoration: const InputDecoration(labelText: 'KM'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _estaSalvando ? null : salvar,
                child: _estaSalvando
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Salvar Manutenção'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}