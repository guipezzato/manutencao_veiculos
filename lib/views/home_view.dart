import 'package:flutter/material.dart';
import 'cadastro_view.dart';
import 'lista_view.dart';

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Controle de Manutenção')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Cadastrar'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CadastroView()),
                );
              },
            ),
            ElevatedButton(
              child: Text('Listar'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ListaView()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}