import 'dart:typed_data';

class AudioEngineWebImpl {
  bool get isInitialized => false;
  double get currentTime => 0.0;

  void ensureContextRunning() {}
  void setMasterVolume(double volume) {}
  String createNode(String type, Map<String, dynamic> config) => 'node_stub';
  void connect(String sourceId, String targetId, [int outputIndex = 0, int inputIndex = 0]) {}
  void connectToParam(String sourceId, String targetNodeId, String paramName) {}
  void disconnect(String nodeId) {}
  void scheduleParamOp({
    required String nodeId,
    required String paramName,
    required String method,
    required double value,
    required double scheduledTime,
    double? timeConstant,
  }) {}
  void updateMeters(Uint8List timeData, Function(double l, double r) setPeaks) {}
  void playPcmBuffer(List<double> samples, double volume, double pan, [double? scheduledTime]) {}
}
