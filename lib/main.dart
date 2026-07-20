import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/analyzer_screen.dart';
import 'screens/receiver_screen.dart';
import 'screens/sender_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'theme/colors.dart';
import 'theme/cyber_theme.dart';
import 'theme/fonts.dart';
import 'widgets/cyber_background.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const HoloRadioApp(),
    ),
  );
}

class HoloRadioApp extends StatelessWidget {
  const HoloRadioApp({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Material You when enabled and the platform provides a scheme,
        // otherwise the neon cyberpunk scheme.
        final ColorScheme scheme = (app.materialYou && darkDynamic != null)
            ? darkDynamic
            : CyberTheme.neonScheme(app.accent);

        return MaterialApp(
          title: 'HoloRadio',
          debugShowCheckedModeBanner: false,
          theme: CyberTheme.theme(scheme, app.accent),
          home: const HomeShell(),
        );
      },
    );
  }
}

/// Bottom-navigation shell hosting the four screens.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const List<Widget> _screens = <Widget>[
    SenderScreen(),
    ReceiverScreen(),
    AnalyzerScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final AppState app = context.watch<AppState>();

    return CyberBackground(
      gridEnabled: app.grid,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'HOLORADIO',
                style: CyberFonts.display(size: 20, color: app.accent),
              ),
              Text(
                'AUDIO DATA MODEM // v1.0',
                style: CyberFonts.terminal(
                  size: 10,
                  letterSpacing: 3,
                  color: CyberColors.textDim,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: app.accent,
                    boxShadow: CyberColors.glow(app.accent, blur: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(index: _index, children: _screens),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (int i) => setState(() => _index = i),
          destinations: const <NavigationDestination>[
            NavigationDestination(icon: Icon(Icons.podcasts), label: 'SENDER'),
            NavigationDestination(icon: Icon(Icons.hearing), label: 'RECEIVER'),
            NavigationDestination(
              icon: Icon(Icons.graphic_eq),
              label: 'ANALYZER',
            ),
            NavigationDestination(icon: Icon(Icons.tune), label: 'SETTINGS'),
          ],
        ),
      ),
    );
  }
}
