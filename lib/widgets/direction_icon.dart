import 'package:flutter/material.dart';

import '../models/direction.dart';

class DirectionIcon extends StatelessWidget {
  const DirectionIcon({super.key, required this.type, this.size = 28});

  final DirectionType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      type.iconAsset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
