import 'package:flutter/material.dart';
import '../../theme/daw_theme.dart';

class EatBitsSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final double defaultValue;
  final String? label;
  final ValueChanged<double> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final int? divisions;
  final String Function(double)? formatValue;

  const EatBitsSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.defaultValue,
    this.label,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.divisions,
    this.formatValue,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showManualEditDialog(context),
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
        ),
        child: Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: activeColor ?? DawTheme.primaryCyan,
          inactiveColor: inactiveColor ?? Colors.white10,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showManualEditDialog(BuildContext context) {
    final displayVal = formatValue != null ? formatValue!(value) : value.toStringAsFixed(2);
    final controller = TextEditingController(text: displayVal);

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
            label != null ? 'Edit $label' : 'Edit Value',
            style: TextStyle(
              color: DawTheme.primaryCyan,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Min: $min  |  Max: $max  |  Default: ${defaultValue.toStringAsFixed(2)}',
                style: TextStyle(color: DawTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                autofocus: true,
                style: TextStyle(color: DawTheme.accentGold, fontSize: 16, fontWeight: FontWeight.bold),
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
            // Default reset button
            OutlinedButton(
              onPressed: () {
                onChanged(defaultValue);
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: DawTheme.accentOrange),
                foregroundColor: DawTheme.accentOrange,
              ),
              child: const Text('DEFAULT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('CANCEL', style: TextStyle(color: DawTheme.textMuted, fontSize: 11)),
            ),
            ElevatedButton(
              onPressed: () {
                final double? parsed = double.tryParse(controller.text);
                if (parsed != null) {
                  onChanged(parsed.clamp(min, max));
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DawTheme.primaryCyan,
                foregroundColor: Colors.black,
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        );
      },
    );
  }
}
