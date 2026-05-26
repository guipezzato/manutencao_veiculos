import 'package:flutter/material.dart';
import '../app_theme/app_theme.dart';
import '../database/database_helper.dart';

class Abastecimento {
  final int? id;
  final String veiculo;
  final DateTime data;
  final double litros;
  final double valorTotal;
  final int kmAtual;
  final String tipoCombustivel;
  final String? posto;

  Abastecimento({
    this.id,
    required this.veiculo,
    required this.data,
    required this.litros,
    required this.valorTotal,
    required this.kmAtual,
    required this.tipoCombustivel,
    this.posto,
  });

  double get precoPorLitro => valorTotal / litros;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'veiculo': veiculo,
    'data': data.toIso8601String(),
    'litros': litros,
    'valor_total': valorTotal,
    'km_atual': kmAtual,
    'tipo_combustivel': tipoCombustivel,
    'posto': posto,
  };

  factory Abastecimento.fromMap(Map<String, dynamic> m) => Abastecimento(
    id: m['id'],
    veiculo: m['veiculo'],
    data: DateTime.parse(m['data']),
    litros: (m['litros'] as num).toDouble(),
    valorTotal: (m['valor_total'] as num).toDouble(),
    kmAtual: m['km_atual'],
    tipoCombustivel: m['tipo_combustivel'],
    posto: m['posto'],
  );
}

class AbastecimentoView extends StatefulWidget {
  const AbastecimentoView({super.key});

  @override
  State<AbastecimentoView> createState() => _AbastecimentoViewState();
}

class _AbastecimentoViewState extends State<AbastecimentoView>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _formKey = GlobalKey<FormState>();
  final _editFormKey = GlobalKey<FormState>(); // Chave para o formulário de edição

  final _veiculoCtrl = TextEditingController();
  final _litrosCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _kmCtrl = TextEditingController();
  final _postoCtrl = TextEditingController();

  DateTime _data = DateTime.now();
  String _combustivel = 'Gasolina';
  bool _saving = false;

  List<Abastecimento> _historico = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _initTable();
  }

  @override
  void dispose() {
    _tab.dispose();
    _veiculoCtrl.dispose();
    _litrosCtrl.dispose();
    _valorCtrl.dispose();
    _kmCtrl.dispose();
    _postoCtrl.dispose();
    super.dispose();
  }

  Future<void> _initTable() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS abastecimento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        veiculo TEXT NOT NULL,
        data TEXT NOT NULL,
        litros REAL NOT NULL,
        valor_total REAL NOT NULL,
        km_atual INTEGER NOT NULL,
        tipo_combustivel TEXT NOT NULL,
        posto TEXT
      )
    ''');
    await _loadHistorico();
  }

  Future<void> _loadHistorico() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('abastecimento', orderBy: 'data DESC, id DESC');
    setState(() {
      _historico = rows.map(Abastecimento.fromMap).toList();
      _loading = false;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      final a = Abastecimento(
        veiculo: _veiculoCtrl.text.trim(),
        data: _data,
        litros: double.parse(_litrosCtrl.text.replaceAll(',', '.')),
        valorTotal: double.parse(_valorCtrl.text.replaceAll(',', '.')),
        kmAtual: int.parse(_kmCtrl.text),
        tipoCombustivel: _combustivel,
        posto: _postoCtrl.text.trim().isEmpty ? null : _postoCtrl.text.trim(),
      );

      final db = await DatabaseHelper.instance.database;
      await db.insert('abastecimento', a.toMap());
      await _loadHistorico();

      _veiculoCtrl.clear();
      _litrosCtrl.clear();
      _valorCtrl.clear();
      _kmCtrl.clear();
      _postoCtrl.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Abastecimento registrado!'),
          backgroundColor: AppTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        _tab.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  // 1. MENU SUPERIOR INFERIOR (OPÇÕES)
  void _mostrarOpcoes(Abastecimento a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
                title: const Text('Editar abastecimento'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirFormularioEdicao(a);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.red),
                title: const Text('Excluir registro', style: TextStyle(color: AppTheme.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarExclusao(a);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 2. DIÁLOGO COM FORMULÁRIO COMPLETO PARA EDIÇÃO
  void _abrirFormularioEdicao(Abastecimento a) {
    final eVeiculoCtrl = TextEditingController(text: a.veiculo);
    final eLitrosCtrl = TextEditingController(text: a.litros.toString());
    final eValorCtrl = TextEditingController(text: a.valorTotal.toString());
    final eKmCtrl = TextEditingController(text: a.kmAtual.toString());
    final ePostoCtrl = TextEditingController(text: a.posto ?? '');
    String eCombustivel = a.tipoCombustivel;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Abastecimento'),
          content: Form(
            key: _editFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: eVeiculoCtrl,
                    decoration: const InputDecoration(labelText: 'Veículo'),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o veículo' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: eLitrosCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Litros'),
                          validator: (v) => v == null || v.isEmpty ? 'Informe os litros' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: eValorCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Total (R\$)'),
                          validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: eKmCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'KM atual'),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o KM' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: eCombustivel,
                    decoration: const InputDecoration(labelText: 'Combustível'),
                    items: ['Gasolina', 'Etanol', 'Diesel', 'GNV']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => eCombustivel = v!),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: ePostoCtrl,
                    decoration: const InputDecoration(labelText: 'Posto (opcional)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_editFormKey.currentState!.validate()) return;
                Navigator.pop(context);
                setState(() => _loading = true);

                try {
                  final db = await DatabaseHelper.instance.database;
                  await db.update(
                    'abastecimento',
                    {
                      'veiculo': eVeiculoCtrl.text.trim(),
                      'litros': double.parse(eLitrosCtrl.text.replaceAll(',', '.')),
                      'valor_total': double.parse(eValorCtrl.text.replaceAll(',', '.')),
                      'km_atual': int.parse(eKmCtrl.text),
                      'tipo_combustivel': eCombustivel,
                      'posto': ePostoCtrl.text.trim().isEmpty ? null : ePostoCtrl.text.trim(),
                    },
                    where: 'id = ?',
                    whereArgs: [a.id],
                  );
                  await _loadHistorico();
                } catch (e) {
                  setState(() => _loading = false);
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // 3. CONFIRMAÇÃO DE EXCLUSÃO NO SQLITE
  Future<void> _confirmarExclusao(Abastecimento a) async {
    if (a.id == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Abastecimento?'),
        content: const Text('Tem certeza que deseja apagar esse registro de combustível?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _loading = true);

              final db = await DatabaseHelper.instance.database;
              await db.delete('abastecimento', where: 'id = ?', whereArgs: [a.id]);

              await _loadHistorico();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  double get _consumoMedio {
    if (_historico.length < 2) return 0;
    double totalKm = 0;
    double totalLitros = 0;
    for (int i = 0; i < _historico.length - 1; i++) {
      final diff = _historico[i].kmAtual - _historico[i + 1].kmAtual;
      if (diff > 0) {
        totalKm += diff;
        totalLitros += _historico[i + 1].litros; // 👈 era _historico[i].litros
      }
    }
    return totalLitros > 0 ? totalKm / totalLitros : 0;
  }

  double get _totalGasto =>
      _historico.fold(0.0, (sum, a) => sum + a.valorTotal);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceAlt,
      appBar: AppBar(
        title: const Text('Combustível'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Registrar'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [_buildForm(), _buildHistorico()],
      ),
    );
  }

  Widget _buildForm() {
    final litros = double.tryParse(_litrosCtrl.text.replaceAll(',', '.')) ?? 0;
    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;
    final precoPorLitro = litros > 0 && valor > 0 ? valor / litros : 0.0;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_consumoMedio > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _consumoStat('${_consumoMedio.toStringAsFixed(1)} km/L', 'Consumo médio'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _consumoStat('R\$ ${_totalGasto.toStringAsFixed(0)}', 'Total gasto'),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _consumoStat('${_historico.length}', 'Abastecimentos'),
                ],
              ),
            ),
          TextFormField(
            controller: _veiculoCtrl,
            decoration: const InputDecoration(
              labelText: 'Veículo',
              hintText: 'Ex: HB20 — ABC-1234',
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Informe o veículo' : null,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _litrosCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Litros',
                    prefixIcon: Icon(Icons.local_gas_station_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => v == null || v.isEmpty ? 'Informe os litros' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor total (R\$)',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => v == null || v.isEmpty ? 'Informe o valor' : null,
                ),
              ),
            ],
          ),
          if (precoPorLitro > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate_outlined, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Preço por litro: R\$ ${precoPorLitro.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: _kmCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'KM atual',
              prefixIcon: Icon(Icons.speed_outlined),
            ),
            validator: (v) => v == null || v.isEmpty ? 'Informe o KM' : null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _combustivel,
            decoration: const InputDecoration(
              labelText: 'Combustível',
              prefixIcon: Icon(Icons.local_fire_department_outlined),
            ),
            items: ['Gasolina', 'Etanol', 'Diesel', 'GNV']
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _combustivel = v!),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _postoCtrl,
            decoration: const InputDecoration(
              labelText: 'Posto (opcional)',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _salvar,
              icon: _saving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.local_gas_station_rounded),
              label: Text(_saving ? 'Salvando...' : 'Registrar abastecimento'),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _consumoStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11)),
      ],
    );
  }

  Widget _buildHistorico() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_historico.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_gas_station_outlined,
                size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Nenhum abastecimento registrado',
                style: TextStyle(fontSize: 16, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _historico.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final a = _historico[i];
        double? consumo;
        if (i < _historico.length - 1) {
          final diff = a.kmAtual - _historico[i + 1].kmAtual;
          if (diff > 0) consumo = diff / _historico[i + 1].litros;
        }

        return InkWell(
          onTap: () => _mostrarOpcoes(a), // 👈 Ativa o clique para Editar/Deletar
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_gas_station_rounded, color: AppTheme.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${a.tipoCombustivel} · ${a.litros.toStringAsFixed(1)}L',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '${a.veiculo} · ${_fmtDate(a.data)}${a.posto != null ? ' · ${a.posto}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Text(
                        'R\$ ${a.precoPorLitro.toStringAsFixed(2)}/L · ${a.kmAtual} km',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$ ${a.valorTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    if (consumo != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: consumo >= 10 ? AppTheme.greenLight : AppTheme.amberLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${consumo.toStringAsFixed(1)} km/L',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: consumo >= 10 ? AppTheme.green : AppTheme.amber,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}