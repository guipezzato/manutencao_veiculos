import 'package:flutter/material.dart';
import '../app_theme/app_theme.dart';
import '../controllers/manutencao_controller.dart';
import '../models/manutencao.dart';
import '../database/database_helper.dart';

class RelatorioView extends StatefulWidget {
  const RelatorioView({super.key});

  @override
  State<RelatorioView> createState() => _RelatorioViewState();
}

class _RelatorioViewState extends State<RelatorioView> {
  final ManutencaoController _controller = ManutencaoController();

  List<Manutencao> _manutencoes = [];
  List<Map<String, dynamic>> _abastecimentos = [];
  bool _loading = true;
  int _mesSel = DateTime.now().month;
  int _anoSel = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final man = await _controller.listar();
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> abast = [];
    try {
      abast = await db.query('abastecimento', orderBy: 'data DESC');
    } catch (_) {}
    setState(() {
      _manutencoes = man;
      _abastecimentos = abast;
      _loading = false;
    });
  }

  List<Manutencao> get _manMes => _manutencoes
      .where((m) => m.data.month == _mesSel && m.data.year == _anoSel)
      .toList();

  List<Map<String, dynamic>> get _abastMes => _abastecimentos.where((a) {
    final d = DateTime.parse(a['data']);
    return d.month == _mesSel && d.year == _anoSel;
  }).toList();

  double get _totalManutencao =>
      _manMes.fold(0.0, (s, m) => s + (m.custo ?? 0));

  double get _totalCombustivel => _abastMes.fold(
      0.0, (s, a) => s + ((a['valor_total'] as num?)?.toDouble() ?? 0));

  double get _totalGeral => _totalManutencao + _totalCombustivel;

  // Dados dos últimos 6 meses
  List<_MesData> get _historico6Meses {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      final man = _manutencoes
          .where((m) => m.data.month == d.month && m.data.year == d.year)
          .fold(0.0, (s, m) => s + (m.custo ?? 0));
      final abast = _abastecimentos.where((a) {
        final dt = DateTime.parse(a['data']);
        return dt.month == d.month && dt.year == d.year;
      }).fold(0.0, (s, a) => s + ((a['valor_total'] as num?)?.toDouble() ?? 0));
      return _MesData(d, man + abast);
    }).reversed.toList();
  }

  static const _meses = [
    'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
    'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceAlt,
      appBar: AppBar(title: const Text('Relatórios')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 20),
            _buildTotais(),
            const SizedBox(height: 24),
            _buildGrafico(),
            const SizedBox(height: 24),
            _buildCategoria(),
            const SizedBox(height: 24),
            _buildDetalhes(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              setState(() {
                if (_mesSel == 1) {
                  _mesSel = 12;
                  _anoSel--;
                } else {
                  _mesSel--;
                }
              });
            },
          ),
          Text(
            '${_meses[_mesSel - 1]} $_anoSel',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              final now = DateTime.now();
              if (_anoSel < now.year ||
                  (_anoSel == now.year && _mesSel < now.month)) {
                setState(() {
                  if (_mesSel == 12) {
                    _mesSel = 1;
                    _anoSel++;
                  } else {
                    _mesSel++;
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTotais() {
    return Row(
      children: [
        _totalCard('Total do mês', 'R\$ ${_totalGeral.toStringAsFixed(2).replaceAll('.', ',')}',
            AppTheme.primary, AppTheme.primaryLight, true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              _miniCard('Manutenção', 'R\$ ${_totalManutencao.toStringAsFixed(2).replaceAll('.', ',')}',
                  AppTheme.amber,
                  AppTheme.amberLight),
              const SizedBox(height: 8),
              _miniCard('Combustível', 'R\$ ${_totalCombustivel.toStringAsFixed(2).replaceAll('.', ',')}',
                blue,
                const Color(0xFFDBEAFE),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const Color blue = Color(0xFF3B82F6);

  Widget _totalCard(String label, String value, Color color, Color bg,
      bool isMain) {
    return Expanded(
      flex: isMain ? 1 : 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }

  Widget _miniCard(String label, String value, Color color, Color bg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildGrafico() {
    final hist = _historico6Meses;
    final maxVal =
    hist.fold(0.0, (m, d) => d.total > m ? d.total : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Histórico 6 meses',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: hist.map((d) {
                    final isSel = d.data.month == _mesSel &&
                        d.data.year == _anoSel;
                    final height = maxVal > 0
                        ? (d.total / maxVal) * 100
                        : 0.0;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _mesSel = d.data.month;
                          _anoSel = d.data.year;
                        }),
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (d.total > 0)
                                Text(
                                  'R\$${d.total.toStringAsFixed(0)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: isSel ? AppTheme.primary : AppTheme.textSecondary,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w400,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                height: height.clamp(4, 100),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppTheme.primary
                                      : AppTheme.primaryLight,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: hist.map((d) {
                  final isSel = d.data.month == _mesSel &&
                      d.data.year == _anoSel;
                  return Expanded(
                    child: Text(
                      _meses[d.data.month - 1],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSel
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        fontWeight: isSel
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoria() {
    if (_totalGeral == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Distribuição por categoria',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _barraCategoria(
                  'Combustível',
                  _totalCombustivel,
                  _totalGeral,
                  AppTheme.primary),
              const SizedBox(height: 12),
              _barraCategoria(
                  'Manutenção',
                  _totalManutencao,
                  _totalGeral,
                  AppTheme.amber),
            ],
          ),
        ),
      ],
    );
  }

  Widget _barraCategoria(
      String label, double val, double total, Color color) {
    final pct = total > 0 ? val / total : 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary)),
            Text(
              'R\$ ${val.toStringAsFixed(2).replaceAll('.', ',')} (${(pct * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildDetalhes() {
    final allItems = [
      ..._manMes.map((m) => _ItemRelatorio(
        descricao: m.descricao,
        detalhe: m.veiculo,
        valor: m.custo ?? 0,
        cor: AppTheme.amber,
        icon: Icons.build_rounded,
      )),
      ..._abastMes.map((a) => _ItemRelatorio(
        descricao: '${a['tipo_combustivel']} · ${a['litros']}L',
        detalhe: a['veiculo'],
        valor: (a['valor_total'] as num?)?.toDouble() ?? 0,
        cor: AppTheme.primary,
        icon: Icons.local_gas_station_rounded,
      )),
    ]..sort((a, b) => b.valor.compareTo(a.valor));

    if (allItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Text('Nenhum lançamento neste mês',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 14)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Detalhamento',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            Text('${allItems.length} lançamentos',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              ...allItems.asMap().entries.map((e) {
                final item = e.value;
                final isLast = e.key == allItems.length - 1;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: isLast
                        ? null
                        : const Border(
                        bottom: BorderSide(
                            color: AppTheme.border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.cor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon,
                            color: item.cor, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.descricao,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textPrimary)),
                            Text(item.detalhe,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Text(
                        'R\$ ${item.valor.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                );
              }),
              // Total row
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                  border: const Border(
                    top: BorderSide(color: AppTheme.border),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary)),
                    Text(
                      'R\$ ${_totalGeral.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MesData {
  final DateTime data;
  final double total;
  _MesData(this.data, this.total);
}

class _ItemRelatorio {
  final String descricao;
  final String detalhe;
  final double valor;
  final Color cor;
  final IconData icon;
  _ItemRelatorio({
    required this.descricao,
    required this.detalhe,
    required this.valor,
    required this.cor,
    required this.icon,
  });
}
