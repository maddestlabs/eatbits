import 'package:flutter/material.dart';

import 'models/daw_state.dart';
import 'theme/daw_theme.dart';
import 'ui/arranger_view.dart';
import 'ui/edit_view.dart';
import 'ui/mixer_view.dart';
import 'ui/track_inspector_view.dart';
import 'ui/transport_header.dart';
import 'ui/wren_workbench_view.dart';

void main() {
  runApp(const WrenDawApp());
}

class WrenDawApp extends StatelessWidget {
  const WrenDawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wren DAW Mobile',
      debugShowCheckedModeBanner: false,
      theme: DawTheme.themeData,
      home: const DawMainShell(),
    );
  }
}

class DawMainShell extends StatefulWidget {
  const DawMainShell({super.key});

  @override
  State<DawMainShell> createState() => _DawMainShellState();
}

class _DawMainShellState extends State<DawMainShell> {
  final DawState _dawState = DawState();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dawState,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                // Top Transport Header (Always Visible)
                TransportHeader(dawState: _dawState),

                // Main Studio Workbench Body
                Expanded(
                  child: IndexedStack(
                    index: _dawState.activeTabIndex,
                    children: [
                      ArrangerView(dawState: _dawState),
                      EditView(dawState: _dawState),
                      TrackInspectorView(dawState: _dawState),
                      MixerView(dawState: _dawState),
                      WrenWorkbenchView(dawState: _dawState),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mobile-Focused Bottom Navigation Bar
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: DawTheme.panelHeader,
              border: Border(top: BorderSide(color: Color(0xFF2B3245), width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: _dawState.activeTabIndex,
              onTap: (index) {
                _dawState.activeTabIndex = index;
              },
              backgroundColor: DawTheme.panelHeader,
              selectedItemColor: DawTheme.primaryCyan,
              unselectedItemColor: DawTheme.textMuted,
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.view_timeline),
                  label: 'Arranger',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.edit_note),
                  label: 'Edit',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_input_component),
                  label: 'Track',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.equalizer),
                  label: 'Mixer',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.code),
                  label: 'Scripts',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
