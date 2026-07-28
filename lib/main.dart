import 'package:flutter/material.dart';

import 'models/daw_state.dart';
import 'theme/daw_theme.dart';
import 'ui/arranger_view.dart';
import 'ui/edit_view.dart';
import 'ui/lua_workbench_view.dart';
import 'ui/mixer_view.dart';
import 'ui/track_inspector_view.dart';
import 'ui/transport_header.dart';
import 'ui/widgets/skeuomorphic_hardware_button.dart';

void main() {
  runApp(const WrenDawApp());
}

class WrenDawApp extends StatelessWidget {
  const WrenDawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eatbits',
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
        final isGrungy = DawTheme.currentPreset == DawThemePreset.grungyHardware;

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
                      LuaWorkbenchView(dawState: _dawState),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hardware Mechanical Navigation Control Strip
          bottomNavigationBar: CustomPaint(
            painter: _HardwareNoisePainter(isGrungy: isGrungy),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isGrungy ? const Color(0xFF26211D).withOpacity(0.9) : DawTheme.panelHeader,
                border: Border(
                  top: BorderSide(
                    color: isGrungy ? const Color(0xFF423B33) : const Color(0xFF2B3245),
                    width: 1.5,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavButton(0, 'ARRANGER', Icons.view_timeline),
                  _buildNavButton(1, 'EDIT', Icons.edit_note),
                  _buildNavButton(2, 'TRACK', Icons.settings_input_component),
                  _buildNavButton(3, 'MIXER', Icons.equalizer),
                  _buildNavButton(4, 'SCRIPTS', Icons.code),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavButton(int index, String label, IconData icon) {
    final isSelected = _dawState.activeTabIndex == index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: SkeuomorphicHardwareButton(
          label: label,
          icon: icon,
          isActive: isSelected,
          activeColor: DawTheme.primaryCyan,
          onTap: () => setState(() => _dawState.activeTabIndex = index),
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        ),
      ),
    );
  }
}

class _HardwareNoisePainter extends CustomPainter {
  final bool isGrungy;

  _HardwareNoisePainter({required this.isGrungy});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isGrungy) return;

    final grainPaint = Paint()
      ..color = const Color(0xFF5A5044).withOpacity(0.08)
      ..strokeWidth = 1.0;

    for (double y = 2.0; y < size.height; y += 3.5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grainPaint);
    }

    final dotPaint = Paint()..color = const Color(0xFF8C7E6C).withOpacity(0.12);
    final darkDotPaint = Paint()..color = Colors.black.withOpacity(0.2);

    for (double x = 4.0; x < size.width; x += 14.0) {
      final y1 = (x * 7.3) % size.height;
      final y2 = (x * 13.1) % size.height;
      canvas.drawCircle(Offset(x, y1), 0.8, dotPaint);
      canvas.drawCircle(Offset(x + 5, y2), 1.0, darkDotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HardwareNoisePainter oldDelegate) => oldDelegate.isGrungy != isGrungy;
}
