import 'package:flutter/material.dart';
import '../../models/daw_state.dart';
import '../../models/track_model.dart';
import 'track_properties_dialog.dart';

Future<void> showRenameTrackDialog(BuildContext context, DawState dawState, TrackChannel track) async {
  return showTrackPropertiesDialog(context, dawState, track);
}
