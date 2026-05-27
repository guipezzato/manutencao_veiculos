import 'package:flutter/material.dart';
import '../app_theme/app_theme.dart';
import '../controllers/manutencao_controller.dart';
import '../models/manutencao.dart';
import 'veiculo_view.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<HomeView> {
  final ManutencaoController _controller = ManutencaoController();
  List<Manutencao> _manutencoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await _controller.listar();
    if (mounted) {
      setState(() {
        _manutencoes = data;
        _loading = false;
      });
    }
  }

  Future<void> _confirmarConclusao(Manutencao m) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Concluir Serviço?'),
        content: Text('Deseja marcar "${m.descricao}" como concluída?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _loading = true);
              m.status = 'concluido';
              await _controller.atualizar(m);
              await load();
            },
            child: const Text('Concluir'),
          ),
        ],
      ),
    );
  }

  void _mostrarOpcoesManutencao(Manutencao m) {
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
                title: const Text('Editar manutenção'),
                onTap: () {
                  Navigator.pop(context);
                  _abrirFormularioEdicao(m);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppTheme.red),
                title: const Text('Excluir registro', style: TextStyle(color: AppTheme.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarExclusao(m);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _abrirFormularioEdicao(Manutencao m) {
    final descController = TextEditingController(text: m.descricao);
    final custoController = TextEditingController(text: m.custo?.toStringAsFixed(0) ?? '');
    final veiculoController = TextEditingController(text: m.veiculo);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Manutenção'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Descrição/Serviço'),
              ),
              TextField(
                controller: veiculoController,
                decoration: const InputDecoration(labelText: 'Veículo'),
              ),
              TextField(
                controller: custoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Custo (R\$)'),
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
              if (descController.text.isEmpty || veiculoController.text.isEmpty) return;
              Navigator.pop(context);
              setState(() => _loading = true);

              m.descricao = descController.text;
              m.veiculo = veiculoController.text;
              m.custo = double.tryParse(custoController.text) ?? m.custo;

              await _controller.atualizar(m);
              await load();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarExclusao(Manutencao m) async {
    if (m.id == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Registro?'),
        content: Text('Tem certeza que deseja apagar "${m.descricao}"? Essa ação não pode ser desfeita.'),
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
              await _controller.deletar(m.id!);
              await load();
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  List<Manutencao> get _urgentes => _manutencoes
      .where((m) => m.status == 'pendente')
      .toList()
    ..sort((a, b) {
      if (a.data == null) return 1;
      if (b.data == null) return -1;
      return a.data.compareTo(b.data);
    });

  double get _totalMes {
    final now = DateTime.now();
    return _manutencoes
        .where((m) => m.data != null && m.data.month == now.month && m.data.year == now.year)
        .fold(0.0, (sum, m) => sum + (m.custo ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceAlt,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: load,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildGraficoGastos(),
                  const SizedBox(height: 24),
                  _buildAlertas(),
                  const SizedBox(height: 24),
                  _buildRecentes(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primary, AppTheme.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Olá, motorista! 👋',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Controle de Manutenção',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const VeiculoView()),
                          ).then((_) => load());
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.directions_car_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final urgentCount = _urgentes.length;
    final totalCount = _manutencoes.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _summaryCard(
          icon: Icons.build_circle_rounded,
          iconColor: AppTheme.primary,
          iconBg: AppTheme.primaryLight,
          label: 'Total registros',
          value: '$totalCount',
        ),
        _summaryCard(
          icon: Icons.warning_amber_rounded,
          iconColor: AppTheme.red,
          iconBg: AppTheme.redLight,
          label: 'Pendentes',
          value: '$urgentCount',
        ),
        _summaryCard(
          icon: Icons.attach_money_rounded,
          iconColor: AppTheme.green,
          iconBg: AppTheme.greenLight,
          label: 'Gasto este mês',
          value: 'R\$ ${_totalMes.toStringAsFixed(2).replaceAll('.', ',')}',
        ),
        _summaryCard(
          icon: Icons.check_circle_rounded,
          iconColor: AppTheme.amber,
          iconBg: AppTheme.amberLight,
          label: 'Concluídos',
          value: '${totalCount - urgentCount}',
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoGastos() {
    final pendentes = _urgentes.length;
    final concluidos = _manutencoes.length - pendentes;

    if (_manutencoes.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Proporção de Serviços',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(
                    color: AppTheme.red,
                    value: pendentes.toDouble() == 0 && concluidos.toDouble() == 0 ? 1 : pendentes.toDouble(),
                    title: pendentes > 0 ? '$pendentes' : '',
                    radius: 35,
                    titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  PieChartSectionData(
                    color: AppTheme.green,
                    value: concluidos.toDouble(),
                    title: concluidos > 0 ? '$concluidos' : '',
                    radius: 35,
                    titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendaItem('Pendentes', AppTheme.red),
              const SizedBox(width: 24),
              _buildLegendaItem('Concluídos', AppTheme.green),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendaItem(String nome, Color cor) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(nome, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAlertas() {
    if (_urgentes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Atenção necessária',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ..._urgentes.take(3).map((m) => _alertaItem(m)),
      ],
    );
  }

  Widget _alertaItem(Manutencao m) {
    return InkWell(
      onTap: () => _confirmarConclusao(m),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.redLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppTheme.red, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.descricao,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(
                    '${m.veiculo} · ${_formatDate(m.data)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            if (m.custo != null)
              Text('R\$ ${m.custo!.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentes() {
    final recentes = _manutencoes
        .where((m) => m.status == 'concluido')
        .toList()
      ..sort((a, b) {
        if (a.data == null) return 1;
        if (b.data == null) return -1;
        return b.data.compareTo(a.data);
      });

    final items = recentes.take(5).toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Últimas manutenções',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ...items.map((m) => _recenteItem(m)),
      ],
    );
  }

  Widget _recenteItem(Manutencao m) {
    final isPendente = m.status == 'pendente';
    return InkWell(
      onTap: () => _mostrarOpcoesManutencao(m),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPendente ? AppTheme.amberLight : AppTheme.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPendente ? Icons.schedule_rounded : Icons.check_circle_rounded,
                color: isPendente ? AppTheme.amber : AppTheme.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.descricao,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  Text(
                    '${m.veiculo} · ${_formatDate(m.data)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (m.custo != null)
                  Text('R\$ ${m.custo!.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isPendente ? AppTheme.amberLight : AppTheme.greenLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPendente ? 'Pendente' : 'Concluído',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isPendente ? AppTheme.amber : AppTheme.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '--/--/----';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
