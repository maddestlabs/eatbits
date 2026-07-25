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
      decoration: const BoxDecoration(
        color: DawTheme.panelHeader,
        border: Border(bottom: BorderSide(color: Color(0xFF2B3245), width: 1)),
      ),
      child: Row(
        children: [
          // Logo Badge Icon Only
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DawTheme.primaryCyan.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: DawTheme.primaryCyan.withOpacity(0.5)),
            ),
            child: const Icon(Icons.graphic_eq, color: DawTheme.primaryCyan, size: 20),
          ),

          const SizedBox(width: 12),

          // Transport Controls: Play, Stop
          IconButton(
            onPressed: dawState.togglePlay,
            icon: Icon(
              dawState.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: dawState.isPlaying ? DawTheme.accentGreen : DawTheme.primaryCyan,
              size: 34,
            ),
            tooltip: dawState.isPlaying ? 'Pause' : 'Play',
          ),
          IconButton(
            onPressed: dawState.stop,
            icon: const Icon(Icons.stop, color: DawTheme.textSecondary, size: 24),
            tooltip: 'Stop',
          ),

          const SizedBox(width: 8),

          // BPM & Tap Tempo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: DawTheme.controlBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('BPM', style: TextStyle(color: DawTheme.textSecondary, fontSize: 8)),
                    Text(
                      dawState.bpm.toStringAsFixed(0),
                      style: const TextStyle(
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
            icon: const Icon(Icons.download, color: DawTheme.primaryCyan, size: 22),
            tooltip: 'Export Song WAV',
          ),
        ],
      ),
    );
  }

  Widget _buildMeterBar(String label, double level) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: DawTheme.textMuted, fontSize: 8)),
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
