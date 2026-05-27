import 'package:flutter/material.dart';
import '../app_theme/app_theme.dart';
import '../database/database_helper.dart';
import '../models/veiculo.dart';

class VeiculoView extends StatefulWidget {
  const VeiculoView({super.key});

  @override
  State<VeiculoView> createState() => _VeiculoViewState();
}

class _VeiculoViewState extends State<VeiculoView> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _ipvaCtrl = TextEditingController();

  String _licenciamento = 'Pendente';
  bool _ipvaPago = false;

  List<Veiculo> _veiculos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVeiculos();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _placaCtrl.dispose();
    _ipvaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVeiculos() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('veiculo', orderBy: 'id DESC');

    setState(() {
      _veiculos = rows.map((e) => Veiculo.fromMap(e)).toList();
      _loading = false;
    });
  }

  Future<void> _salvarVeiculo() async {
    if (!_formKey.currentState!.validate()) return;

    final novoCarro = Veiculo(
      nome: _nomeCtrl.text.trim(),
      placa: _placaCtrl.text.trim().toUpperCase(),
      valorIpva: double.tryParse(_ipvaCtrl.text.replaceAll(',', '.')) ?? 0.0,
      pagoIpva: _ipvaPago,
      statusLicenciamento: _licenciamento,
    );

    final db = await DatabaseHelper.instance.database;
    await db.insert('veiculo', novoCarro.toMap());

    _nomeCtrl.clear();
    _placaCtrl.clear();
    _ipvaCtrl.clear();
    _ipvaPago = false;
    _licenciamento = 'Pendente';

    Navigator.pop(context);
    _loadVeiculos();
  }
  void _editarDebitosVeiculo(Veiculo v) {
    final eIpvaCtrl = TextEditingController(text: v.valorIpva.toString());
    bool eIpvaPago = v.pagoIpva;
    String eLicenciamento = v.statusLicenciamento;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Atualizar Débitos — ${v.nome}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: eIpvaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Valor do IPVA (R\$)'),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('IPVA Pago?'),
                  value: eIpvaPago,
                  activeColor: AppTheme.green,
                  onChanged: (value) => setDialogState(() => eIpvaPago = value),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: eLicenciamento,
                  decoration: const InputDecoration(labelText: 'Licenciamento'),
                  items: ['Pago', 'Pendente']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) => setDialogState(() => eLicenciamento = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _loading = true);

                final db = await DatabaseHelper.instance.database;
                await db.update(
                  'veiculo',
                  {
                    'valor_ipva': double.tryParse(eIpvaCtrl.text.replaceAll(',', '.')) ?? 0.0,
                    'pago_ipva': eIpvaPago ? 1 : 0,
                    'status_licenciamento': eLicenciamento,
                  },
                  where: 'id = ?',
                  whereArgs: [v.id],
                );
                _loadVeiculos();
              },
              child: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
  void _mostrarOpcoesVeiculo(Veiculo v) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: AppTheme.primary),
              title: const Text('Editar débitos'),
              onTap: () {
                Navigator.pop(context);
                _editarDebitosVeiculo(v);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.red),
              title: const Text('Excluir veículo', style: TextStyle(color: AppTheme.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmarExclusaoVeiculo(v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusaoVeiculo(Veiculo v) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Veículo?'),
        content: Text('Deseja apagar "${v.nome}"? Essa ação não pode ser desfeita.'),
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
              await db.delete('veiculo', where: 'id = ?', whereArgs: [v.id]);
              _loadVeiculos();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _abrirCadastroCarro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adicionar Novo Veículo',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Modelo/Nome do Carro', prefixIcon: Icon(Icons.directions_car)),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o modelo' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _placaCtrl,
                    decoration: const InputDecoration(labelText: 'Placa (Ex: ABC-1234)', prefixIcon: Icon(Icons.badge_outlined)),
                    validator: (v) => v == null || v.isEmpty ? 'Informe a placa' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ipvaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor do IPVA (R\$)', prefixIcon: Icon(Icons.attach_money)),
                    validator: (v) => v == null || v.isEmpty ? 'Informe o valor do IPVA' : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('IPVA Pago?'),
                    subtitle: Text(_ipvaPago ? 'Sim, está quitado' : 'Não, está em aberto', style: const TextStyle(fontSize: 12)),
                    value: _ipvaPago,
                    activeColor: AppTheme.green,
                    onChanged: (v) => setModalState(() => _ipvaPago = v),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _licenciamento,
                    decoration: const InputDecoration(labelText: 'Status do Licenciamento', prefixIcon: Icon(Icons.text_snippet_outlined)),
                    items: ['Pago', 'Pendente']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModalState(() => _licenciamento = v!),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _salvarVeiculo,
                      child: const Text('Salvar Veículo'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceAlt,
      appBar: AppBar(
        title: const Text('Meus Veículos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 28),
            onPressed: _abrirCadastroCarro,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _veiculos.isEmpty
          ? _buildEmptyState()
          : Column(
        children: [
          if (_veiculos.isNotEmpty)
            _buildCarroAtivoCard(_veiculos.first),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Gerenciar Garagem',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
            ),
          ),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _veiculos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) return const SizedBox.shrink();
                return _buildCarroItemRow(_veiculos[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarroAtivoCard(Veiculo v) {
    return InkWell(
      onTap: () => _editarDebitosVeiculo(v), 
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
            ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VEÍCULO ATIVO', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    Text(v.nome, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  child: Text(v.placa, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 1)),
                )
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),

            _rowDebitoDetail(
                icon: Icons.monetization_on_outlined,
                label: 'IPVA (R\$ ${v.valorIpva.toStringAsFixed(2)})',
                statusText: v.pagoIpva ? 'PAGO' : 'PENDENTE',
                isPago: v.pagoIpva
            ),
            const SizedBox(height: 12),
            _rowDebitoDetail(
                icon: Icons.text_snippet_outlined,
                label: 'Licenciamento Anual',
                statusText: v.statusLicenciamento.toUpperCase(),
                isPago: v.statusLicenciamento.toLowerCase() == 'pago'
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowDebitoDetail({required IconData icon, required String label, required String statusText, required bool isPago}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isPago ? Colors.green.withOpacity(0.3) : Colors.amber.withOpacity(0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(statusText, style: TextStyle(color: isPago ? Colors.greenAccent : Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildCarroItemRow(Veiculo v) {
    final todosDebitosPagos = v.pagoIpva && v.statusLicenciamento.toLowerCase() == 'pago';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _mostrarOpcoesVeiculo(v),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryLight,
              child: const Icon(Icons.directions_car_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                  Text('Placa: ${v.placa}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: todosDebitosPagos ? AppTheme.greenLight : AppTheme.redLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                todosDebitosPagos ? 'Regularizado' : 'Possui Débitos',
                style: TextStyle(color: todosDebitosPagos ? AppTheme.green : AppTheme.red, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_filled_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Nenhum carro na garagem', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _abrirCadastroCarro, child: const Text('Cadastrar Primeiro Carro')),
        ],
      ),
    );
  }
}
