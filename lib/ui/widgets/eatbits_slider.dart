import 'package:flutter/material.dart';
import '../../theme/daw_theme.dart';
import 'skeuomorphic_hardware_slider.dart';

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
    return SkeuomorphicHardwareSlider(
      value: value,
      min: min,
      max: max,
      defaultValue: defaultValue,
      label: label,
      onChanged: onChanged,
      activeColor: activeColor ?? DawTheme.primaryCyan,
      formatValue: formatValue,
    );
  }
}
