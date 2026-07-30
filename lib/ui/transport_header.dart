import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daw_state.dart';
import '../theme/daw_theme.dart';
import '../utils/eats_file_helper.dart';
import 'widgets/skeuomorphic_hardware_button.dart';
import 'widgets/glowing_nixie_display.dart';
import 'widgets/compact_value_dialog.dart';

class TransportHeader extends StatelessWidget {
  final DawState dawState;

  const TransportHeader({super.key, required this.dawState});

  @override
  Widget build(BuildContext context) {
    final isGrungy = DawTheme.currentPreset == DawThemePreset.grungyHardware;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isGrungy ? const Color(0xFF24201C) : DawTheme.panelHeader,
        border: Border(
          bottom: BorderSide(
            color: isGrungy ? const Color(0xFF4A423A) : const Color(0xFF2B3245),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // EatsBits Monster Icon drawn directly on background
          Tooltip(
            message: 'Eatsbits Settings',
            child: InkWell(
              onTap: () => _showSettingsDialog(context),
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: EatsBitsMonsterIcon(size: 28),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Transport Play / Stop Mechanical Button (no LED dot)
          SkeuomorphicHardwareButton(
            label: dawState.isPlaying ? 'STOP' : 'PLAY',
            icon: dawState.isPlaying ? Icons.stop : Icons.play_arrow,
            isActive: dawState.isPlaying,
            activeColor: dawState.isPlaying ? DawTheme.muteColor : const Color(0xFF00FF66),
            onTap: dawState.isPlaying ? dawState.stop : dawState.togglePlay,
            height: 38,
            showLed: false,
          ),

          const SizedBox(width: 10),

          // BPM Glowing Nixie Display & Tap Tempo Button (no LED dot)
          GestureDetector(
            onLongPress: () => _showBpmEditDialog(context),
            child: Row(
              children: [
                GlowingNixieDisplay(
                  label: '',
                  valueText: dawState.bpm.toStringAsFixed(0),
                  unit: 'BPM',
                  fontSize: 14,
                  glowColor: DawTheme.accentGold,
                ),
                const SizedBox(width: 6),
                SkeuomorphicHardwareButton(
                  label: 'TAP',
                  isActive: false,
                  activeColor: DawTheme.accentGold,
                  onTap: dawState.tapTempo,
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  showLed: false,
                ),
              ],
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

          // Save .eats.lua Button
          IconButton(
            onPressed: () => _handleSave(context),
            icon: Icon(Icons.save, color: DawTheme.accentGold, size: 20),
            tooltip: 'Save Project (.eats.lua)',
          ),

          // Load .eats.lua Button
          IconButton(
            onPressed: () => _handleLoad(context),
            icon: Icon(Icons.folder_open, color: DawTheme.primaryCyan, size: 20),
            tooltip: 'Load Project (.eats.lua)',
          ),

          // Code View / Share Button
          IconButton(
            onPressed: () => _showCodeViewDialog(context),
            icon: Icon(Icons.code, color: DawTheme.textSecondary, size: 20),
            tooltip: 'View / Paste .eats.lua Script',
          ),

          // Export WAV Icon Button
          IconButton(
            onPressed: dawState.exportWavSong,
            icon: Icon(Icons.download, color: DawTheme.primaryCyan, size: 20),
            tooltip: 'Export Song WAV',
          ),
        ],
      ),
    );
  }

  void _handleSave(BuildContext context) {
    final code = dawState.exportToEatsLua();
    final fileName = '${dawState.projectName.toLowerCase().replaceAll(' ', '_')}.eats.lua';
    EatsFileHelper.saveEatsLuaFile(code, fileName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved project as "$fileName"'),
        backgroundColor: DawTheme.panelBackground,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleLoad(BuildContext context) {
    if (kIsWeb) {
      EatsFileHelper.pickEatsLuaFileWeb((content, fileName) {
        dawState.loadFromEatsLua(content);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded project "$fileName"'),
            backgroundColor: DawTheme.panelBackground,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    } else {
      _showCodeViewDialog(context);
    }
  }

  void _showCodeViewDialog(BuildContext context) {
    final controller = TextEditingController(text: dawState.exportToEatsLua());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DawTheme.panelBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.code, color: DawTheme.primaryCyan),
              const SizedBox(width: 8),
              Text(
                'EATS.LUA SCRIPT',
                style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: SizedBox(
            width: 600,
            height: 400,
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70),
              decoration: InputDecoration(
                fillColor: Colors.black45,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: controller.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied .eats.lua to clipboard!')),
                );
              },
              child: Text('COPY CODE', style: TextStyle(color: DawTheme.accentGold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: DawTheme.primaryCyan),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  dawState.loadFromEatsLua(controller.text);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Loaded project from .eats.lua script!')),
                  );
                }
              },
              child: const Text('LOAD SCRIPT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
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
              const EatsBitsMonsterIcon(size: 28),
              const SizedBox(width: 10),
              Text(
                'EATSBITS SETTINGS',
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
                  if (preset == DawThemePreset.grungyHardware) title = 'Grungy Vintage Hardware (SILT / Analog Rack)';

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

                Text(
                  'PROJECT MANAGEMENT (.EATS.LUA)',
                  style: TextStyle(color: DawTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DawTheme.accentGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _handleSave(context);
                        },
                        icon: const Icon(Icons.save, size: 16),
                        label: const Text('SAVE (.EATS.LUA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DawTheme.primaryCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _handleLoad(context);
                        },
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('LOAD (.EATS.LUA)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
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
    showCompactValueEditDialog(
      context: context,
      title: 'Tempo (BPM)',
      initialValue: dawState.bpm.toStringAsFixed(0),
      minMaxHint: 'Range: 40 - 240 BPM',
      accentColor: DawTheme.accentGold,
      onResetDefault: () => dawState.setBpm(120.0),
      onSubmit: (text) {
        final val = double.tryParse(text);
        if (val != null) {
          dawState.setBpm(val);
        }
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

// Custom EatsBits Monster Icon Widget
class EatsBitsMonsterIcon extends StatelessWidget {
  final double size;
  const EatsBitsMonsterIcon({super.key, this.size = 24.0});

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
          painter: _EatsBitsMonsterPainter(),
        ),
      ),
    );
  }
}

class _EatsBitsMonsterPainter extends CustomPainter {
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
