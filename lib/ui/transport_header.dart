import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../theme/daw_theme.dart';


class TransportHeader extends StatelessWidget {
  final DawState dawState;

  const TransportHeader({super.key, required this.dawState});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DawTheme.panelHeader,
        border: const Border(bottom: BorderSide(color: Color(0xFF2B3245), width: 1)),
      ),
      child: Row(
        children: [
          // EatBits Top-Left App Icon with Settings Menu Trigger
          GestureDetector(
            onTap: () => _showSettingsDialog(context),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: DawTheme.primaryCyan.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: DawTheme.primaryCyan, width: 1.5),
                boxShadow: [
                  BoxShadow(color: DawTheme.primaryCyan.withOpacity(0.3), blurRadius: 6),
                ],
              ),
              child: const EatBitsMonsterIcon(size: 24),
            ),
          ),

          const SizedBox(width: 12),

          // Transport Control: Play / Stop Toggle Button
          IconButton(
            onPressed: dawState.isPlaying ? dawState.stop : dawState.togglePlay,
            icon: Icon(
              dawState.isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
              color: dawState.isPlaying ? DawTheme.muteColor : DawTheme.primaryCyan,
              size: 34,
            ),
            tooltip: dawState.isPlaying ? 'Stop' : 'Play',
          ),

          const SizedBox(width: 8),

          // BPM & Tap Tempo (Tap + Hold to open manual edit dialog)
          GestureDetector(
            onLongPress: () => _showBpmEditDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DawTheme.controlBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('BPM', style: TextStyle(color: DawTheme.textSecondary, fontSize: 8)),
                      Text(
                        dawState.bpm.toStringAsFixed(0),
                        style: DawTheme.getDisplayFontStyle(
                          color: DawTheme.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: dawState.tapTempo,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: DawTheme.accentGold.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: DawTheme.accentGold.withOpacity(0.6)),
                      ),
                      child: const Text(
                        'TAP',
                        style: TextStyle(color: DawTheme.accentGold, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Stereo Master Peak Meter
          SizedBox(
            width: 50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMeterBar('L', dawState.audioEngine.leftPeak),
                const SizedBox(height: 3),
                _buildMeterBar('R', dawState.audioEngine.rightPeak),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Export WAV Icon Button
          IconButton(
            onPressed: dawState.exportWavSong,
            icon: Icon(Icons.download, color: DawTheme.primaryCyan, size: 22),
            tooltip: 'Export Song WAV',
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DawTheme.panelBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const EatBitsMonsterIcon(size: 28),
              const SizedBox(width: 10),
              Text(
                'EATBITS SETTINGS',
                style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COLOR SCHEME & THEME PRESET',
                  style: TextStyle(color: DawTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                ),
                const SizedBox(height: 10),

                // Theme Presets Selector
                ...DawThemePreset.values.map((preset) {
                  final isSelected = DawTheme.currentPreset == preset;

                  String title = 'Cyberpunk Cyan (Default)';
                  if (preset == DawThemePreset.midnightOled) title = 'Midnight OLED (Pitch Black)';
                  if (preset == DawThemePreset.synthwavePurple) title = 'Synthwave Neon (Pink & Purple)';
                  if (preset == DawThemePreset.studioLight) title = 'Studio Light Mode';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? DawTheme.controlBackground : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSelected ? DawTheme.primaryCyan : Colors.white10),
                    ),
                    child: ListTile(
                      title: Text(title, style: TextStyle(color: isSelected ? DawTheme.primaryCyan : DawTheme.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      leading: Radio<DawThemePreset>(
                        value: preset,
                        groupValue: DawTheme.currentPreset,
                        activeColor: DawTheme.primaryCyan,
                        onChanged: (val) {
                          if (val != null) {
                            dawState.setThemePreset(val);
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      onTap: () {
                        dawState.setThemePreset(preset);
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                }).toList(),

                const SizedBox(height: 16),



                Text(
                  'AUDIO ENGINE CONFIG',
                  style: TextStyle(color: DawTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                ),

                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: DawTheme.controlBackground, borderRadius: BorderRadius.circular(6)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Clock: WebAudio Hardware Scheduler (Look-Ahead 120ms)', style: TextStyle(color: DawTheme.textPrimary, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text('• Sample Rate: 44.1 kHz / 48.0 kHz Hardware Native', style: TextStyle(color: DawTheme.textPrimary, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text('• Script Compiler: Embedded Lua 5.4 / LuaJIT Live Engine', style: TextStyle(color: DawTheme.textPrimary, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('CLOSE', style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showBpmEditDialog(BuildContext context) {
    final controller = TextEditingController(text: dawState.bpm.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DawTheme.panelBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white10),
          ),
          title: Text(
            'Edit BPM (Tempo)',
            style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Min: 40 BPM  |  Max: 240 BPM  |  Default: 120 BPM',
                style: TextStyle(color: DawTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: TextStyle(color: DawTheme.accentGold, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: DawTheme.controlBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: DawTheme.primaryCyan.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: DawTheme.primaryCyan, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            OutlinedButton(
              onPressed: () {
                dawState.setBpm(120.0);
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: DawTheme.accentOrange),
                foregroundColor: DawTheme.accentOrange,
              ),
              child: const Text('DEFAULT (120)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('CANCEL', style: TextStyle(color: DawTheme.textMuted, fontSize: 11)),
            ),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(controller.text);
                if (val != null) {
                  dawState.setBpm(val);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: DawTheme.primaryCyan, foregroundColor: Colors.black),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeterBar(String label, double level) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: DawTheme.textMuted, fontSize: 8)),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: level,
              backgroundColor: DawTheme.controlBackground,
              color: level > 0.85 ? DawTheme.muteColor : (level > 0.6 ? DawTheme.accentGold : DawTheme.accentGreen),
              minHeight: 6,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom EatBits Monster Icon Widget
class EatBitsMonsterIcon extends StatelessWidget {
  final double size;
  const EatBitsMonsterIcon({super.key, this.size = 24.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: DawTheme.primaryCyan,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.85, size * 0.85),
          painter: _EatBitsMonsterPainter(),
        ),
      ),
    );
  }
}

class _EatBitsMonsterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Monster head & open mouth
    final path = Path();
    path.moveTo(size.width * 0.15, size.height * 0.15);
    path.lineTo(size.width * 0.75, size.height * 0.15);
    path.lineTo(size.width * 0.75, size.height * 0.42);
    path.lineTo(size.width * 0.4, size.height * 0.42);
    path.lineTo(size.width * 0.4, size.height * 0.68);
    path.lineTo(size.width * 0.75, size.height * 0.68);
    path.lineTo(size.width * 0.75, size.height * 0.85);
    path.lineTo(size.width * 0.15, size.height * 0.85);
    path.close();
    canvas.drawPath(path, paint);

    // Eye
    final eyePaint = Paint()..color = DawTheme.primaryCyan;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.28), size.width * 0.08, eyePaint);

    // Eating bits
    final bitPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(size.width * 0.82, size.height * 0.45, size.width * 0.12, size.width * 0.12), bitPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.82, size.height * 0.65, size.width * 0.1, size.width * 0.1), bitPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
