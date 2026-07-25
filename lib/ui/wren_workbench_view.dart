import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../theme/daw_theme.dart';
import '../wren/wren_preset_library.dart';

class WrenWorkbenchView extends StatefulWidget {
  final DawState dawState;

  const WrenWorkbenchView({super.key, required this.dawState});

  @override
  State<WrenWorkbenchView> createState() => _WrenWorkbenchViewState();
}

class _WrenWorkbenchViewState extends State<WrenWorkbenchView> {
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.dawState.wrenCode);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.dawState.compilationResult;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: DawTheme.panelHeader,
            child: Row(
              children: [
                const Icon(Icons.code, color: DawTheme.accentGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  'SCRIPTS (WREN DSP ENGINE)',
                  style: TextStyle(
                    color: DawTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),

                // Preset Loader Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: DawTheme.controlBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<WrenPreset>(
                      hint: Text('LOAD PRESET', style: TextStyle(color: DawTheme.textSecondary, fontSize: 11)),
                      dropdownColor: DawTheme.panelBackground,
                      items: WrenPresetLibrary.presets.map((preset) {
                        return DropdownMenuItem<WrenPreset>(
                          value: preset,
                          child: Text(
                            preset.name,
                            style: TextStyle(color: DawTheme.textPrimary, fontSize: 11),
                          ),
                        );
                      }).toList(),
                      onChanged: (preset) {
                        if (preset != null) {
                          setState(() {
                            _codeController.text = preset.code;
                          });
                          widget.dawState.loadWrenPreset(preset);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Compile & Run Button
                ElevatedButton.icon(
                  onPressed: () {
                    widget.dawState.compileWrenCode(_codeController.text);
                  },
                  icon: Icon(Icons.play_arrow, size: 16, color: DawTheme.backgroundDark),
                  label: Text('COMPILE DSP', style: TextStyle(color: DawTheme.backgroundDark, fontWeight: FontWeight.bold, fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DawTheme.accentGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Real-time Audio Waveform Display
                Container(
                  height: 60,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: DawTheme.backgroundDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DawTheme.accentGreen.withOpacity(0.4)),
                  ),
                  child: CustomPaint(
                    painter: WaveformPainter(timeData: widget.dawState.audioEngine.waveformTimeData),
                  ),
                ),

                const SizedBox(height: 12),

                // Code Editor Container
                Container(
                  decoration: BoxDecoration(
                    color: DawTheme.panelBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2B3245)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: DawTheme.panelHeader,
                        child: Row(
                          children: [
                            Icon(Icons.terminal, size: 14, color: DawTheme.textMuted),
                            const SizedBox(width: 6),
                            Text('WREN SOURCE SCRIPT (LIVELINK)', style: TextStyle(color: DawTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      TextField(
                        controller: _codeController,
                        maxLines: 12,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: DawTheme.textPrimary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(12),
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Compiler Status & Output Console
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: result.isSuccess ? DawTheme.accentGreen.withOpacity(0.1) : DawTheme.muteColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: result.isSuccess ? DawTheme.accentGreen.withOpacity(0.5) : DawTheme.muteColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        result.isSuccess ? Icons.check_circle : Icons.error_outline,
                        color: result.isSuccess ? DawTheme.accentGreen : DawTheme.muteColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.errorMessage,
                          style: TextStyle(
                            color: result.isSuccess ? DawTheme.accentGreen : DawTheme.muteColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Dynamic Wren Interactive Parameter Controls
                if (result.params.isNotEmpty) ...[
                  Text(
                    'DYNAMIC SCRIPT PARAMETERS',
                    style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: result.params.map((param) {
                      final activeTrack = widget.dawState.activeTrack;
                      final currentVal = activeTrack.wrenParams[param.name] ?? param.defaultValue;

                      return Container(
                        width: 170,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: DawTheme.panelBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: DawTheme.primaryCyan.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  param.name,
                                  style: TextStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                                Text(
                                  currentVal.toStringAsFixed(1),
                                  style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              ],
                            ),
                            Slider(
                              value: currentVal.clamp(param.min, param.max),
                              min: param.min,
                              max: param.max,
                              activeColor: DawTheme.primaryCyan,
                              onChanged: (val) {
                                widget.dawState.updateWrenParam(param.name, val);
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<int> timeData;

  WaveformPainter({required this.timeData});

  @override
  void paint(Canvas canvas, Size size) {
    if (timeData.isEmpty) return;

    final paint = Paint()
      ..color = DawTheme.accentGreen
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final sliceWidth = size.width / timeData.length;

    double x = 0;
    for (int i = 0; i < timeData.length; i++) {
      final v = timeData[i] / 128.0;
      final y = v * size.height / 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      x += sliceWidth;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) => true;
}
