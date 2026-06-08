import 'package:flutter/material.dart';

class ColorPalettePicker extends StatefulWidget {
  const ColorPalettePicker({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  final Color initialColor;
  final ValueChanged<Color> onColorSelected;

  @override
  State<ColorPalettePicker> createState() => _ColorPalettePickerState();
}

class _ColorPalettePickerState extends State<ColorPalettePicker> {
  late HSVColor _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = HSVColor.fromColor(widget.initialColor);
  }

  @override
  void didUpdateWidget(ColorPalettePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initialColor.toARGB32() == oldWidget.initialColor.toARGB32()) {
      return;
    }

    _selectedColor = HSVColor.fromColor(widget.initialColor);
  }

  void _handleSaturationValueChanged(Offset position, Size size) {
    final saturation = (position.dx / size.width).clamp(0.0, 1.0);
    final value = (1 - position.dy / size.height).clamp(0.0, 1.0);

    _selectColor(_selectedColor.withSaturation(saturation).withValue(value));
  }

  void _handleHueChanged(Offset position, Size size) {
    final hue = (position.dy / size.height).clamp(0.0, 1.0) * 360;

    _selectColor(_selectedColor.withHue(hue));
  }

  void _handleAlphaChanged(Offset position, Size size) {
    final alpha = (1 - position.dy / size.height).clamp(0.0, 1.0);

    _selectColor(_selectedColor.withAlpha(alpha));
  }

  void _selectColor(HSVColor color) {
    setState(() {
      _selectedColor = color;
    });

    widget.onColorSelected(color.toColor());
  }

  @override
  Widget build(BuildContext context) {
    final color = _selectedColor.toColor();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 168,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ColorPlane(
                color: _selectedColor,
                onChanged: _handleSaturationValueChanged,
              ),
              const SizedBox(width: 12),
              _VerticalColorStrip(
                key: const ValueKey('color-palette-hue-strip'),
                value: _selectedColor.hue / 360,
                painter: const _HueStripPainter(),
                onChanged: _handleHueChanged,
                tooltip: '色相',
              ),
              const SizedBox(width: 10),
              _VerticalColorStrip(
                key: const ValueKey('color-palette-alpha-strip'),
                value: 1 - _selectedColor.alpha,
                painter: _AlphaStripPainter(color: _selectedColor.withAlpha(1)),
                onChanged: _handleAlphaChanged,
                tooltip: '透明度',
              ),
              const SizedBox(width: 14),
              Expanded(child: _PaletteSummary(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPlane extends StatelessWidget {
  const _ColorPlane({required this.color, required this.onChanged});

  final HSVColor color;
  final _PalettePositionChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: _PaletteGestureArea(
        key: const ValueKey('color-palette-saturation-value-area'),
        tooltip: '颜色盘',
        onChanged: onChanged,
        child: CustomPaint(
          painter: _SaturationValuePainter(hue: color.hue),
          foregroundPainter: _SelectionRingPainter(
            position: Offset(color.saturation, 1 - color.value),
          ),
        ),
      ),
    );
  }
}

class _VerticalColorStrip extends StatelessWidget {
  const _VerticalColorStrip({
    super.key,
    required this.value,
    required this.painter,
    required this.onChanged,
    required this.tooltip,
  });

  final double value;
  final CustomPainter painter;
  final _PalettePositionChanged onChanged;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: _PaletteGestureArea(
        tooltip: tooltip,
        onChanged: onChanged,
        child: CustomPaint(
          painter: painter,
          foregroundPainter: _StripThumbPainter(value: value),
        ),
      ),
    );
  }
}

class _PaletteGestureArea extends StatelessWidget {
  const _PaletteGestureArea({
    super.key,
    required this.tooltip,
    required this.onChanged,
    required this.child,
  });

  final String tooltip;
  final _PalettePositionChanged onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails details) {
              onChanged(details.localPosition, size);
            },
            onPanUpdate: (DragUpdateDetails details) {
              onChanged(details.localPosition, size);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

class _PaletteSummary extends StatelessWidget {
  const _PaletteSummary({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorText = _formatColorText(color);
    final channelText = _formatChannelText(color);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '颜色盘',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF23313C),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x22000000)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          colorText,
          key: const ValueKey('color-palette-selected-text'),
          style: const TextStyle(
            color: Color(0xFF23313C),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          channelText,
          style: const TextStyle(
            color: Color(0xFF607180),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SaturationValuePainter extends CustomPainter {
  const _SaturationValuePainter({required this.hue});

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final hueColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: <Color>[Colors.white, hueColor],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Colors.transparent, Colors.black],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SaturationValuePainter oldDelegate) {
    return hue != oldDelegate.hue;
  }
}

class _HueStripPainter extends CustomPainter {
  const _HueStripPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = List<Color>.generate(7, (int index) {
      return HSVColor.fromAHSV(1, index * 60, 1, 1).toColor();
    });

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_HueStripPainter oldDelegate) {
    return false;
  }
}

class _AlphaStripPainter extends CustomPainter {
  const _AlphaStripPainter({required this.color});

  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const checker = _CheckerPainter();

    checker.paint(canvas, size);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[color.toColor(), color.withAlpha(0).toColor()],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_AlphaStripPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class _CheckerPainter extends CustomPainter {
  const _CheckerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const tileSize = 8.0;
    final lightPaint = Paint()..color = const Color(0xFFF7FAFB);
    final darkPaint = Paint()..color = const Color(0xFFE1E8ED);

    for (var y = 0.0; y < size.height; y += tileSize) {
      for (var x = 0.0; x < size.width; x += tileSize) {
        final isDark = ((x / tileSize).floor() + (y / tileSize).floor()).isOdd;
        canvas.drawRect(
          Rect.fromLTWH(x, y, tileSize, tileSize),
          isDark ? darkPaint : lightPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CheckerPainter oldDelegate) {
    return false;
  }
}

class _SelectionRingPainter extends CustomPainter {
  const _SelectionRingPainter({required this.position});

  final Offset position;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(position.dx * size.width, position.dy * size.height);

    canvas
      ..drawCircle(center, 7, Paint()..color = Colors.white)
      ..drawCircle(
        center,
        7,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF11212D),
      );
  }

  @override
  bool shouldRepaint(_SelectionRingPainter oldDelegate) {
    return position != oldDelegate.position;
  }
}

class _StripThumbPainter extends CustomPainter {
  const _StripThumbPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final y = value.clamp(0.0, 1.0) * size.height;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, y),
      width: size.width + 6,
      height: 8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF11212D),
    );
  }

  @override
  bool shouldRepaint(_StripThumbPainter oldDelegate) {
    return value != oldDelegate.value;
  }
}

typedef _PalettePositionChanged = void Function(Offset position, Size size);

String _formatColorText(Color color) {
  final value = color.toARGB32();
  final alpha = _formatHexByte((value >> 24) & 0xFF);
  final red = _formatHexByte((value >> 16) & 0xFF);
  final green = _formatHexByte((value >> 8) & 0xFF);
  final blue = _formatHexByte(value & 0xFF);

  if (alpha == 'FF') {
    return '#$red$green$blue';
  }

  return '#$red$green$blue$alpha';
}

String _formatChannelText(Color color) {
  final value = color.toARGB32();
  final alpha = (value >> 24) & 0xFF;
  final red = (value >> 16) & 0xFF;
  final green = (value >> 8) & 0xFF;
  final blue = value & 0xFF;

  return 'A $alpha  R $red  G $green  B $blue';
}

String _formatHexByte(int value) {
  return value.toRadixString(16).padLeft(2, '0').toUpperCase();
}
