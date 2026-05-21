import 'package:flutter/material.dart';
import '../app_theme/app_theme.dart';
import '../controllers/manutencao_controller.dart';
import '../models/manutencao.dart';
import 'cadastro_view.dart';

class ListaView extends StatefulWidget {
  const ListaView({super.key});

  @override
  State<ListaView> createState() => _ListaViewState();
}

class _ListaViewState extends State<ListaView> {
  final ManutencaoController _controller = ManutencaoController();
  List<Manutencao> _all = [];
  List<Manutencao> _filtered = [];
  String _filterStatus = 'todos';
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _controller.listar();
    setState(() {
      _all = data;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    _filtered = _all.where((m) {
      final matchStatus =
          _filterStatus == 'todos' || m.status == _filterStatus;
      final matchSearch = _search.isEmpty ||
          m.descricao.toLowerCase().contains(_search.toLowerCase()) ||
          m.veiculo.toLowerCase().contains(_search.toLowerCase());
      return matchStatus && matchSearch;
    }).toList()
      ..sort((a, b) => b.data.compareTo(a.data));
  }

  Future<void> _delete(Manutencao m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir registro',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Deseja excluir "${m.descricao}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir',
                style: TextStyle(color: AppTheme.red)),
          ),
        ],
      ),
    );
    if (confirm == true && m.id != null) {
      await _controller.deletar(m.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceAlt,
      appBar: AppBar(
        title: const Text('Manutenções'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () async {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CadastroView()));
                _load();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Nova'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? _buildEmpty()
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _buildItem(_filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        onChanged: (v) => setState(() {
          _search = v;
          _applyFilter();
        }),
        decoration: const InputDecoration(
          hintText: 'Buscar por veículo ou serviço...',
          prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const filters = [
      ('todos', 'Todos'),
      ('pendente', 'Pendentes'),
      ('concluido', 'Concluídos'),
    ];
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: filters.map((f) {
          final selected = _filterStatus == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() {
                _filterStatus = f.$1;
                _applyFilter();
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primary : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? AppTheme.primary : AppTheme.border),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildItem(Manutencao m) {
    final isPendente = m.status == 'pendente';
    return Dismissible(
      key: Key(m.id?.toString() ?? m.descricao),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        await _delete(m);
        return false;
      },
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
                color: isPendente ? AppTheme.amberLight : AppTheme.greenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.build_rounded,
                color: isPendente ? AppTheme.amber : AppTheme.green,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.descricao,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    '${m.veiculo} · ${_formatDate(m.data)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  if (m.km != null) ...[
                    const SizedBox(height: 2),
                    Text('${m.km} km',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (m.custo != null)
                  Text(
                    'R\$ ${m.custo!.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.car_repair_rounded,
              size: 64, color: AppTheme.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('Nenhum registro encontrado',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          const Text('Cadastre a primeira manutenção',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
