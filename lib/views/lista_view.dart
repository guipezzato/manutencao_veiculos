import 'package:flutter/material.dart';
import 'package:manutencao_veiculos/controllers/manutencao_controller.dart';
import 'package:manutencao_veiculos/models/manutencao.dart';
import 'package:manutencao_veiculos/views/cadastro_view.dart'; // Certifique-se que este import existe

class ListaView extends StatefulWidget {
  const ListaView({super.key});

  @override
  State<ListaView> createState() => _ListaViewState();
}

class _ListaViewState extends State<ListaView> {
  final controller = ManutencaoController();
  List<Manutencao> lista = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  void carregar() async {
    final dados = await controller.listar();
    setState(() {
      lista = dados;
    });
  }

  void excluir(int id) async {
    await controller.deletar(id);
    carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manutenções')),
      body: ListView.builder(
        itemCount: lista.length,
        itemBuilder: (context, index) {
          final m = lista[index];
          return ListTile(
            leading: const Icon(Icons.car_repair, color: Colors.blue),
            title: Text(m.veiculo),
            subtitle: Text('${m.descricao} - R\$ ${m.valor}'),
            onTap: () async {
              // Navega para edição e aguarda o retorno
              bool? atualizou = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CadastroView(manutencaoParaEdicao: m),
                ),
              );

              if (atualizou == true) {
                carregar();
              }
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                if (m.id != null) excluir(m.id!);
              },
            ),
          );
        },
      ),
    );
  }
}