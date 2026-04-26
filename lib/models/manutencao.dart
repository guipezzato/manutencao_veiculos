class Manutencao {
  int? id;
  String veiculo;
  String descricao;
  String data;
  double valor;

  Manutencao({
    this.id,
    required this.veiculo,
    required this.descricao,
    required this.data,
    required this.valor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'veiculo': veiculo,
      'descricao': descricao,
      'data': data,
      'valor': valor,
    };
  }

  factory Manutencao.fromMap(Map<String, dynamic> map) {
    return Manutencao(
      id: map['id'],
      veiculo: map['veiculo'],
      descricao: map['descricao'],
      data: map['data'],
      valor: map['valor'] is int ? (map['valor'] as int).toDouble() : map['valor'],
    );
  }
}