import 'package:flutter/material.dart';
import '../models/daw_state.dart';
import '../models/track_model.dart';
import '../theme/daw_theme.dart';

class ArrangerView extends StatefulWidget {
  final DawState dawState;

  const ArrangerView({super.key, required this.dawState});

  @override
  State<ArrangerView> createState() => _ArrangerViewState();
}

class _ArrangerViewState extends State<ArrangerView> {
  static const double barWidth = 60.0;
  static const double trackRowHeight = 72.0;
  static const int totalBars = 32;

  final ScrollController _horizontalScroll = ScrollController();
  final ScrollController _verticalScroll = ScrollController();

  @override
  Widget build(BuildContext context) {
    final tracks = widget.dawState.activePattern.tracks;

    return Column(
      children: [
        // Sub-Header Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: DawTheme.panelHeader,
          child: Row(
            children: [
              const Icon(Icons.view_timeline, color: DawTheme.primaryCyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                'MULTITRACK DAW ARRANGER',
                style: TextStyle(
                  color: DawTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  final activeTrack = widget.dawState.activeTrack;
                  widget.dawState.addClipToTrack(activeTrack, 0);
                },
                icon: const Icon(Icons.add, size: 14, color: DawTheme.backgroundDark),
                label: const Text('ADD CLIP', style: TextStyle(color: DawTheme.backgroundDark, fontWeight: FontWeight.bold, fontSize: 10)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DawTheme.primaryCyan,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ),

        // Multitrack Grid & Track Panels
        Expanded(
          child: Row(
            children: [
              // Left Panel: Vertical Track Control Strips (Pixel-Aligned)
              SizedBox(
                width: 140,
                child: ListView.builder(
                  controller: _verticalScroll,
                  itemCount: tracks.length,
                  itemBuilder: (context, trackIdx) {
                    final track = tracks[trackIdx];
                    final isSelected = trackIdx == widget.dawState.activeTrackIndex;

                    return GestureDetector(
                      onTap: () {
                        widget.dawState.activeTrackIndex = trackIdx;
                      },
                      onDoubleTap: () {
                        // DOUBLE-TAP TRACK HEADER: Navigate to Track Inspector tab
                        widget.dawState.activeTrackIndex = trackIdx;
                        widget.dawState.activeTabIndex = 2; // Track section
                      },
                      child: Container(
                        height: trackRowHeight,
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected ? DawTheme.controlBackground : DawTheme.panelBackground,
                          border: Border(
                            left: BorderSide(color: track.color, width: 4),
                            bottom: const BorderSide(color: Color(0xFF1B202D), width: 1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              track.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? DawTheme.primaryCyan : DawTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildMuteButton(track),
                                const SizedBox(width: 4),
                                _buildSoloButton(track),
                                const Spacer(),
                                SizedBox(
                                  width: 45,
                                  height: 20,
                                  child: Slider(
                                    value: track.volume,
                                    min: 0.0,
                                    max: 1.5,
                                    activeColor: track.color,
                                    onChanged: (val) => widget.dawState.setTrackVolume(track, val),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Right Multitrack Timeline Grid (Pixel-Aligned)
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalScroll,
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalBars * barWidth,
                    child: SingleChildScrollView(
                      controller: _verticalScroll,
                      child: Column(
                        children: List.generate(tracks.length, (trackIdx) {
                          final track = tracks[trackIdx];

                          return Container(
                            height: trackRowHeight,
                            margin: const EdgeInsets.only(bottom: 2),
                            decoration: const BoxDecoration(
                              color: DawTheme.backgroundDark,
                              border: Border(bottom: BorderSide(color: Color(0xFF1B202D), width: 1)),
                            ),
                            child: Stack(
                              children: [
                                // Bar Grid Lines
                                Row(
                                  children: List.generate(totalBars, (barIdx) {
                                    return GestureDetector(
                                      onTap: () {
                                        widget.dawState.activeTrackIndex = trackIdx;
                                        widget.dawState.addClipToTrack(track, barIdx);
                                      },
                                      child: Container(
                                        width: barWidth,
                                        height: trackRowHeight,
                                        decoration: BoxDecoration(
                                          border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
                                        ),
                                      ),
                                    );
                                  }),
                                ),

                                // Per-track Pattern Clips with Drag & Resize
                                ...track.clips.map((clip) {
                                  return Positioned(
                                    left: clip.startBar * barWidth + 2,
                                    top: 6,
                                    width: (clip.barLength * barWidth) - 4,
                                    height: trackRowHeight - 12,
                                    child: GestureDetector(
                                      onDoubleTap: () {
                                        // DOUBLE-TAP CLIP: Open clip in Edit section (Piano Roll / Tracker View)
                                        widget.dawState.activeTrackIndex = trackIdx;
                                        widget.dawState.openClipInEditor(clip);
                                      },
                                      onTap: () {
                                        widget.dawState.activeTrackIndex = trackIdx;
                                        widget.dawState.selectClip(clip);
                                      },
                                      onHorizontalDragUpdate: (details) {
                                        // Move clip startBar by dragging
                                        final deltaBars = (details.delta.dx / barWidth).round();
                                        if (deltaBars != 0) {
                                          setState(() {
                                            clip.startBar = (clip.startBar + deltaBars).clamp(0, totalBars - clip.barLength);
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: track.color,
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(color: track.color.withOpacity(0.4), blurRadius: 6),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        clip.name,
                                                        style: const TextStyle(
                                                          color: DawTheme.backgroundDark,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      const Spacer(),
                                                      const Icon(Icons.drag_indicator, size: 10, color: DawTheme.backgroundDark),
                                                    ],
                                                  ),
                                                  const Spacer(),
                                                  // Mini note preview bars
                                                  Row(
                                                    children: List.generate(6, (i) {
                                                      return Expanded(
                                                        child: Container(
                                                          height: 3,
                                                          margin: const EdgeInsets.symmetric(horizontal: 1),
                                                          decoration: BoxDecoration(
                                                            color: DawTheme.backgroundDark.withOpacity(0.6),
                                                            borderRadius: BorderRadius.circular(1),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Right Edge Drag Handle to Resize Clip Length
                                            GestureDetector(
                                              onHorizontalDragUpdate: (details) {
                                                final deltaLength = (details.delta.dx / barWidth).round();
                                                if (deltaLength != 0) {
                                                  setState(() {
                                                    clip.barLength = (clip.barLength + deltaLength).clamp(1, totalBars - clip.startBar);
                                                  });
                                                }
                                              },
                                              child: Container(
                                                width: 14,
                                                height: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: DawTheme.backgroundDark.withOpacity(0.3),
                                                  borderRadius: const BorderRadius.only(
                                                    topRight: Radius.circular(4),
                                                    bottomRight: Radius.circular(4),
                                                  ),
                                                ),
                                                child: const Icon(Icons.code, size: 10, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMuteButton(TrackChannel track) {
    return GestureDetector(
      onTap: () => widget.dawState.toggleMute(track),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: track.isMuted ? DawTheme.muteColor : DawTheme.panelHeader,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text('M', style: TextStyle(color: track.isMuted ? Colors.white : DawTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSoloButton(TrackChannel track) {
    return GestureDetector(
      onTap: () => widget.dawState.toggleSolo(track),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: track.isSoloed ? DawTheme.soloColor : DawTheme.panelHeader,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text('S', style: TextStyle(color: track.isSoloed ? Colors.black : DawTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
