class Veiculo {
  final int? id;
  final String nome;
  final String placa;
  final double valorIpva;
  final bool pagoIpva;
  final String statusLicenciamento; // 'Pago' ou 'Pendente'

  Veiculo({
    this.id,
    required this.nome,
    required this.placa,
    this.valorIpva = 0.0,
    this.pagoIpva = false,
    this.statusLicenciamento = 'Pendente',
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'nome': nome,
    'placa': placa,
    'valor_ipva': valorIpva,
    'pago_ipva': pagoIpva ? 1 : 0, // SQLite não tem boolean nativo, salvamos como 0 ou 1
    'status_licenciamento': statusLicenciamento,
  };

  factory Veiculo.fromMap(Map<String, dynamic> m) => Veiculo(
    id: m['id'],
    nome: m['nome'],
    placa: m['placa'],
    valorIpva: (m['valor_ipva'] as num).toDouble(),
    pagoIpva: m['pago_ipva'] == 1,
    statusLicenciamento: m['status_licenciamento'] ?? 'Pendente',
  );
}