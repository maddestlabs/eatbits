import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';
import 'widgets/eatbits_slider.dart';

class MixerView extends StatefulWidget {
  final DawState dawState;

  const MixerView({super.key, required this.dawState});

  @override
  State<MixerView> createState() => _MixerViewState();
}

class _MixerViewState extends State<MixerView> {
  DateTime? _lastTapTime;
  int? _lastTapTrackIdx;

  @override
  Widget build(BuildContext context) {
    final pattern = widget.dawState.activePattern;

    return Column(
      children: [
        // Sub-header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: DawTheme.panelHeader,
          child: Row(
            children: [
              Text(
                'MULTI-CHANNEL AUDIO MIXER & FX RACK',
                style: TextStyle(
                  color: DawTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),

        // Mixer Channel Fader Strips
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Master Channel Strip
                _buildMasterChannelStrip(widget.dawState),
                const VerticalDivider(color: Color(0xFF2B3245), width: 24, thickness: 1.5),

                // Individual Track Strips
                ...List.generate(pattern.tracks.length, (tIdx) {
                  return _buildTrackStrip(context, widget.dawState, pattern.tracks[tIdx], tIdx);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMasterChannelStrip(DawState dawState) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: DawTheme.panelBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: DawTheme.primaryCyan.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'MASTER',
            style: TextStyle(color: DawTheme.primaryCyan, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),

          // Master Fader
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotatedBox(
                  quarterTurns: 3,
                  child: EatBitsSlider(
                    value: dawState.masterVolume,
                    min: 0.0,
                    max: 1.5,
                    defaultValue: 0.85,
                    label: 'Master Volume',
                    activeColor: DawTheme.primaryCyan,
                    onChanged: (val) => dawState.setMasterVolume(val),
                  ),
                ),

                // Peak Meter
                SizedBox(
                  width: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: dawState.audioEngine.leftPeak,
                      backgroundColor: DawTheme.controlBackground,
                      color: DawTheme.primaryCyan,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Text(
            '${(dawState.masterVolume * 100).toInt()}%',
            style: DawTheme.getDisplayFontStyle(color: DawTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackStrip(BuildContext context, DawState dawState, TrackChannel track, int trackIdx) {
    final isSelected = trackIdx == dawState.activeTrackIndex;

    return GestureDetector(
      onTapDown: (_) {
        final now = DateTime.now();
        final isDoubleTap = _lastTapTrackIdx == trackIdx &&
            _lastTapTime != null &&
            now.difference(_lastTapTime!).inMilliseconds < 300;
        _lastTapTime = now;
        _lastTapTrackIdx = trackIdx;

        dawState.activeTrackIndex = trackIdx;
        if (isDoubleTap) {
          dawState.activeTabIndex = 2; // Switch to TRACK section
        }
      },
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? DawTheme.controlBackground : DawTheme.panelBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? track.color : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            // Track Name & Color badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(color: track.color, borderRadius: BorderRadius.circular(4)),
              child: Text(
                track.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DawTheme.getPrimaryFontStyle(color: DawTheme.backgroundDark, fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
            const SizedBox(height: 6),

            // Mute & Solo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => dawState.toggleMute(track),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: track.isMuted ? DawTheme.muteColor : DawTheme.panelHeader,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'M',
                      style: DawTheme.getPrimaryFontStyle(color: track.isMuted ? Colors.white : DawTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => dawState.toggleSolo(track),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: track.isSoloed ? DawTheme.soloColor : DawTheme.panelHeader,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'S',
                      style: DawTheme.getPrimaryFontStyle(color: track.isSoloed ? Colors.black : DawTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Pan Knob
            Text('PAN', style: DawTheme.getPrimaryFontStyle(color: DawTheme.textMuted, fontSize: 8)),
            SizedBox(
              height: 24,
              child: EatBitsSlider(
                value: track.pan,
                min: -1.0,
                max: 1.0,
                defaultValue: 0.0,
                label: '${track.name} Pan',
                activeColor: track.color,
                onChanged: (val) => dawState.setTrackPan(track, val),
              ),
            ),

            const SizedBox(height: 8),

            // Vertical Volume Fader
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: EatBitsSlider(
                  value: track.volume,
                  min: 0.0,
                  max: 1.5,
                  defaultValue: 1.0,
                  label: '${track.name} Volume',
                  activeColor: track.color,
                  onChanged: (val) => dawState.setTrackVolume(track, val),
                ),
              ),
            ),

            const SizedBox(height: 6),
            Text(
              '${(track.volume * 100).toInt()}%',
              style: DawTheme.getDisplayFontStyle(color: DawTheme.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            // FX Insert Rack Trigger Button
            ElevatedButton(
              onPressed: () {
                _showFXRackDialog(context, dawState, track);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DawTheme.panelHeader,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                minimumSize: const Size(double.infinity, 24),
              ),
              child: Text('FX RACK', style: DawTheme.getPrimaryFontStyle(color: DawTheme.primaryCyan, fontSize: 9, fontWeight: FontWeight.bold)),
            ),

          ],
        ),
      ),
    );
  }

  void _showFXRackDialog(BuildContext context, DawState dawState, TrackChannel track) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: DawTheme.panelBackground,
          title: Text('FX INSERT RACK: ${track.name}', style: TextStyle(color: DawTheme.primaryCyan)),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Bitcrusher 8-Bit', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: Text('Sample reduction & bit depth', style: TextStyle(color: DawTheme.textMuted, fontSize: 10)),
                  trailing: Switch(
                    value: track.fxRack.any((f) => f.name == 'Bitcrusher'),
                    onChanged: (val) => dawState.toggleBitcrusher(track, val),
                  ),
                ),
                ListTile(
                  title: const Text('Tube Distortion', style: TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: Text('Soft clipping warmth', style: TextStyle(color: DawTheme.textMuted, fontSize: 10)),
                  trailing: Switch(
                    value: track.fxRack.any((f) => f.name == 'TubeDistortion'),
                    onChanged: (val) => dawState.toggleDistortion(track, val),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('CLOSE', style: TextStyle(color: DawTheme.primaryCyan)),
            ),
          ],
        );
      },
    );
  }
}
