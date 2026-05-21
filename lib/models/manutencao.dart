class Manutencao {
  int? id;
  String veiculo;
  String descricao;
  DateTime data;
  double? custo;
  int? km;
  String status;

  Manutencao({
    this.id,
    required this.veiculo,
    required this.descricao,
    required this.data,
    this.custo,
    this.km,
    this.status = 'pendente',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'veiculo': veiculo,
      'descricao': descricao,
      'data': data.toIso8601String(),
      'custo': custo,
      'km': km,
      'status': status,
    };
  }

  factory Manutencao.fromMap(Map<String, dynamic> map) {
    return Manutencao(
      id: map['id'],
      veiculo: map['veiculo'],
      descricao: map['descricao'],
      data: DateTime.parse(map['data']),
      custo: map['custo'] != null
          ? (map['custo'] as num).toDouble()
          : null,
      km: map['km'],
      status: map['status'] ?? 'pendente',
    );
  }
}