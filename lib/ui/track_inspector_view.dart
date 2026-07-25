import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';

class TrackInspectorView extends StatelessWidget {
  final DawState dawState;

  const TrackInspectorView({super.key, required this.dawState});

  @override
  Widget build(BuildContext context) {
    final track = dawState.activeTrack;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Track Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DawTheme.panelBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: track.color, width: 2),
              boxShadow: [
                BoxShadow(color: track.color.withOpacity(0.2), blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 48,
                  decoration: BoxDecoration(color: track.color, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onDoubleTap: () {
                    // DOUBLE TAP TRACK TITLE: Navigate to Scripts Section (tab 4)
                    dawState.activeTabIndex = 4;
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name.toUpperCase(),
                        style: TextStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'TYPE: ${track.type.name.toUpperCase()} (DOUBLE-TAP FOR CODE)',
                        style: TextStyle(color: track.color, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Mute & Solo
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => dawState.toggleMute(track),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: track.isMuted ? DawTheme.muteColor : DawTheme.panelHeader,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('MUTE', style: TextStyle(color: track.isMuted ? Colors.white : DawTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => dawState.toggleSolo(track),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: track.isSoloed ? DawTheme.soloColor : DawTheme.panelHeader,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('SOLO', style: TextStyle(color: track.isSoloed ? Colors.black : DawTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Mixer Controls Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DawTheme.panelBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2B3245)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHANNEL MIXER SETTINGS', style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                const SizedBox(height: 12),

                // Volume Slider
                Row(
                  children: [
                    SizedBox(width: 70, child: Text('VOLUME', style: TextStyle(color: DawTheme.textSecondary, fontSize: 11))),
                    Expanded(
                      child: Slider(
                        value: track.volume,
                        min: 0.0,
                        max: 1.5,
                        activeColor: track.color,
                        onChanged: (val) => dawState.setTrackVolume(track, val),
                      ),
                    ),
                    SizedBox(width: 40, child: Text('${(track.volume * 100).toInt()}%', style: TextStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                ),

                // Pan Slider
                Row(
                  children: [
                    SizedBox(width: 70, child: Text('PAN', style: TextStyle(color: DawTheme.textSecondary, fontSize: 11))),
                    Expanded(
                      child: Slider(
                        value: track.pan,
                        min: -1.0,
                        max: 1.0,
                        activeColor: track.color,
                        onChanged: (val) => dawState.setTrackPan(track, val),
                      ),
                    ),
                    SizedBox(width: 40, child: Text(track.pan == 0 ? 'C' : (track.pan < 0 ? 'L${(track.pan.abs() * 100).toInt()}' : 'R${(track.pan * 100).toInt()}'), style: TextStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic Wren Script Parameters (Exposed by Code)
          if (track.type == TrackType.wrenScript || track.wrenParams.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DawTheme.panelBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DawTheme.accentGreen.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.code, color: DawTheme.accentGreen, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'DYNAMIC SCRIPT PARAMETERS (CODE DRIVEN)',
                        style: TextStyle(color: DawTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...track.wrenParams.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          SizedBox(width: 100, child: Text(entry.key, style: TextStyle(color: DawTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 11))),
                          Expanded(
                            child: Slider(
                              value: entry.value,
                              min: 0.0,
                              max: 10000.0, // Flexible parameter range
                              activeColor: DawTheme.accentGreen,
                              onChanged: (val) {
                                dawState.updateWrenParam(entry.key, val);
                              },
                            ),
                          ),
                          SizedBox(width: 50, child: Text(entry.value.toStringAsFixed(1), style: const TextStyle(color: DawTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 11))),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // FX Insert Rack
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DawTheme.panelBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2B3245)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FX INSERT RACK', style: TextStyle(color: DawTheme.secondaryMagenta, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Bitcrusher 8-Bit', style: TextStyle(color: Colors.white, fontSize: 12)),
                  subtitle: Text('Sample & bit depth reducer', style: TextStyle(color: DawTheme.textMuted, fontSize: 10)),
                  value: track.fxRack.any((f) => f.name == 'Bitcrusher'),
                  activeColor: DawTheme.secondaryMagenta,
                  onChanged: (val) => dawState.toggleBitcrusher(track, val),
                ),
                SwitchListTile(
                  title: const Text('Tube Distortion', style: TextStyle(color: Colors.white, fontSize: 12)),
                  subtitle: Text('Soft clipping saturation', style: TextStyle(color: DawTheme.textMuted, fontSize: 10)),
                  value: track.fxRack.any((f) => f.name == 'TubeDistortion'),
                  activeColor: DawTheme.secondaryMagenta,
                  onChanged: (val) => dawState.toggleDistortion(track, val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
