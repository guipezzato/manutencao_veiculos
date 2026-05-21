import 'package:manutencao_veiculos/models/manutencao.dart';
import 'package:manutencao_veiculos/database/database_helper.dart';

class ManutencaoController {
  final db = DatabaseHelper.instance;

  Future<void> inserir(Manutencao m) async {
    final database = await db.database;
    await database.insert('manutencoes', m.toMap());
  }

  Future<void> atualizar(Manutencao m) async {
    final database = await db.database;
    await database.update(
      'manutencoes',
      m.toMap(),
      where: 'id = ?',
      whereArgs: [m.id],
    );
  }

  Future<List<Manutencao>> listar() async {
    final database = await db.database;

    final result = await database.query(
      'manutencoes',
      orderBy: 'data DESC',
    );

    return result.map((e) => Manutencao.fromMap(e)).toList();
  }

  Future<void> deletar(int id) async {
    final database = await db.database;
    await database.delete('manutencoes', where: 'id = ?', whereArgs: [id]);
  }
}