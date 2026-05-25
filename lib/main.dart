import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme/app_theme.dart';
import 'views/home_view.dart';
import 'views/cadastro_view.dart';
import 'views/lista_view.dart';
import 'views/abastecimento_view.dart';
import 'views/relatorio_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ManutencaoApp());
}

class ManutencaoApp extends StatelessWidget {
  const ManutencaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Manutenção',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const MainShell(),
      routes: {
        '/lista': (context) => const ListaView(),
        '/abastecimento': (context) => const AbastecimentoView(),
        '/relatorio': (context) => const RelatorioView(),
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // GlobalKey para acessar o _load() da HomeView após salvar
  final GlobalKey<HomeViewState> _homeKey = GlobalKey<HomeViewState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeView(key: _homeKey),
      const ListaView(),
      CadastroView(onSaved: _aoSalvar),
      const AbastecimentoView(),
      const RelatorioView(),
    ];
  }

  // Chamado pelo CadastroView após salvar com sucesso
  void _aoSalvar() {
    // Recarrega a lista da HomeView
    _homeKey.currentState?.load();
    // Volta para a aba Home
    setState(() => _currentIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build_rounded),
              label: 'Manutenções',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              activeIcon: Icon(Icons.add_circle_rounded),
              label: 'Cadastrar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_gas_station_outlined),
              activeIcon: Icon(Icons.local_gas_station_rounded),
              label: 'Combustível',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart_rounded),
              label: 'Relatórios',
            ),
          ],
        ),
      ),
    );
  }
}