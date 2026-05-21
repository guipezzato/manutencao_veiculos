import 'package:flutter/material.dart';
import '../app_theme/app_theme.dart';
import '../controllers/manutencao_controller.dart';
import '../models/manutencao.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ManutencaoController _controller = ManutencaoController();
  List<Manutencao> _manutencoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _controller.listar();
    setState(() {
      _manutencoes = data;
      _loading = false;
    });
  }

  List<Manutencao> get _urgentes => _manutencoes
      .where((m) => m.status == 'pendente')
      .toList()
    ..sort((a, b) => a.data.compareTo(b.data));

  double get _totalMes {
    final now = DateTime.now();
    return _manutencoes
        .where((m) => m.data.month == now.month && m.data.year == now.year)
        .fold(0.0, (sum, m) => sum + (m.custo ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceAlt,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummaryCards(),
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
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.directions_car_rounded,
                            color: Colors.white, size: 24),
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
          value: 'R\$ ${_totalMes.toStringAsFixed(0)}',
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
    return Container(
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
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          if (m.custo != null)
            Text('R\$ ${m.custo!.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.red)),
        ],
      ),
    );
  }

  Widget _buildRecentes() {
    final recentes = [..._manutencoes]
      ..sort((a, b) => b.data.compareTo(a.data));
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
    return Container(
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
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
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
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
