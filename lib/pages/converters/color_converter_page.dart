import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'color_palette_picker.dart';

class ColorConverterPage extends StatefulWidget {
  const ColorConverterPage({super.key});

  @override
  State<ColorConverterPage> createState() => _ColorConverterPageState();
}

class _ColorConverterPageState extends State<ColorConverterPage> {
  final TextEditingController _inputController = TextEditingController();
  _ColorResult? _result;
  String? _errorText;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleConvert() {
    final input = _inputController.text.trim();

    if (input.isEmpty) {
      setState(() {
        _result = null;
        _errorText = '请先输入 HEX、RGB/RGBA 或 Flutter Color 文本。';
      });
      return;
    }

    try {
      final colorValue = _parseColor(input);

      setState(() {
        _result = _ColorResult.fromValue(colorValue, statusText: '转换完成。');
        _errorText = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _errorText = error.message;
      });
    }
  }

  void _handleClear() {
    setState(() {
      _inputController.clear();
      _result = null;
      _errorText = null;
    });
  }

  void _handlePaletteColorSelected(Color color) {
    final value = _ColorValue.fromColor(color);

    setState(() {
      _inputController.text = value.inputHexText;
      _result = _ColorResult.fromValue(value, statusText: '已从颜色盘选取。');
      _errorText = null;
    });
  }

  Future<void> _handleCopyValue(String value, String statusText) async {
    await Clipboard.setData(ClipboardData(text: value));

    if (!mounted) {
      return;
    }

    setState(() {
      final current = _result;

      if (current == null) {
        return;
      }

      _result = current.copyWith(statusText: statusText);
      _errorText = null;
    });
  }

  _ColorValue _parseColor(String input) {
    final normalized = input.trim();

    if (normalized.startsWith('#')) {
      return _parseHexColor(normalized.substring(1));
    }

    final flutterMatch = RegExp(
      r'^Color\s*\(\s*0x([0-9a-fA-F]{8})\s*\)$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (flutterMatch != null) {
      return _parseArgbHex(flutterMatch.group(1)!);
    }

    final rgbMatch = RegExp(
      r'^rgba?\s*\((.*)\)$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (rgbMatch != null) {
      return _parseRgbFunction(rgbMatch.group(1)!);
    }

    throw const FormatException(
      '无法识别颜色格式，请使用 #RRGGBB、#RRGGBBAA、rgb(...)、rgba(...) 或 Color(0xAARRGGBB)。',
    );
  }

  _ColorValue _parseHexColor(String hexText) {
    if (!_isHexText(hexText)) {
      throw const FormatException('HEX 颜色只能包含 0-9、A-F。');
    }

    if (hexText.length == 6) {
      final rgb = int.parse(hexText, radix: 16);
      return _ColorValue(
        alpha: 255,
        red: (rgb >> 16) & 0xFF,
        green: (rgb >> 8) & 0xFF,
        blue: rgb & 0xFF,
      );
    }

    if (hexText.length == 8) {
      if (hexText.startsWith(RegExp('ff|00', caseSensitive: false))) {
        return _parseArgbHex(hexText);
      }

      return _parseRgbaHex(hexText);
    }

    throw const FormatException('HEX 颜色长度需要是 6 位 RGB 或 8 位 RGBA。');
  }

  _ColorValue _parseRgbaHex(String hexText) {
    final rgba = int.parse(hexText, radix: 16);

    return _ColorValue(
      alpha: rgba & 0xFF,
      red: (rgba >> 24) & 0xFF,
      green: (rgba >> 16) & 0xFF,
      blue: (rgba >> 8) & 0xFF,
    );
  }

  _ColorValue _parseArgbHex(String hexText) {
    if (!_isHexText(hexText)) {
      throw const FormatException('HEX 颜色只能包含 0-9、A-F。');
    }

    if (hexText.length != 8) {
      throw const FormatException('ARGB HEX 颜色长度需要是 8 位。');
    }

    final argb = int.parse(hexText, radix: 16);

    return _ColorValue(
      alpha: (argb >> 24) & 0xFF,
      red: (argb >> 16) & 0xFF,
      green: (argb >> 8) & 0xFF,
      blue: argb & 0xFF,
    );
  }

  _ColorValue _parseRgbFunction(String channelText) {
    final parts = channelText.split(',').map((item) => item.trim()).toList();

    if (parts.length != 3 && parts.length != 4) {
      throw const FormatException('RGB/RGBA 需要 3 个或 4 个通道值。');
    }

    final red = _parseByteChannel(parts[0], 'R');
    final green = _parseByteChannel(parts[1], 'G');
    final blue = _parseByteChannel(parts[2], 'B');
    final alpha = parts.length == 4 ? _parseAlphaChannel(parts[3]) : 255;

    return _ColorValue(alpha: alpha, red: red, green: green, blue: blue);
  }

  int _parseByteChannel(String text, String label) {
    final value = int.tryParse(text);

    if (value == null || value < 0 || value > 255) {
      throw FormatException('$label 通道需要是 0 到 255 的整数。');
    }

    return value;
  }

  int _parseAlphaChannel(String text) {
    final numericValue = double.tryParse(text);

    if (numericValue == null) {
      throw const FormatException('Alpha 通道需要是 0 到 1 的小数，或 0 到 255 的整数。');
    }

    if (numericValue >= 0 && numericValue <= 1) {
      return (numericValue * 255).round();
    }

    if (numericValue % 1 == 0 && numericValue >= 0 && numericValue <= 255) {
      return numericValue.toInt();
    }

    throw const FormatException('Alpha 通道需要是 0 到 1 的小数，或 0 到 255 的整数。');
  }

  bool _isHexText(String text) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '颜色转换',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF23313C),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '支持 HEX、RGB、RGBA 和 Flutter Color 互转，适合快速整理 UI 标注颜色。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF607180),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD8E2E8)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _ColorInputBar(
                      controller: _inputController,
                      onConvert: _handleConvert,
                      onClear: _handleClear,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  SliverToBoxAdapter(
                    child: ColorPalettePicker(
                      initialColor:
                          result?.value.color ?? const Color(0xFF0F766E),
                      onColorSelected: _handlePaletteColorSelected,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  if (_errorText != null) ...[
                    SliverToBoxAdapter(
                      child: _ColorMessageBanner(
                        message: _errorText!,
                        isError: true,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  ] else if (result != null) ...[
                    SliverToBoxAdapter(
                      child: _ColorMessageBanner(
                        message: result.statusText,
                        isError: false,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                  ],
                  SliverFillRemaining(
                    hasScrollBody: result != null,
                    child: result == null
                        ? const _ColorEmptyState()
                        : _ColorResultView(
                            result: result,
                            onCopyValue: _handleCopyValue,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorValue {
  const _ColorValue({
    required this.alpha,
    required this.red,
    required this.green,
    required this.blue,
  });

  final int alpha;
  final int red;
  final int green;
  final int blue;

  Color get color => Color.fromARGB(alpha, red, green, blue);

  factory _ColorValue.fromColor(Color color) {
    final value = color.toARGB32();

    return _ColorValue(
      alpha: (value >> 24) & 0xFF,
      red: (value >> 16) & 0xFF,
      green: (value >> 8) & 0xFF,
      blue: value & 0xFF,
    );
  }

  String get inputHexText {
    final redText = _ColorResult._formatHexByte(red);
    final greenText = _ColorResult._formatHexByte(green);
    final blueText = _ColorResult._formatHexByte(blue);

    if (alpha == 255) {
      return '#$redText$greenText$blueText';
    }

    final alphaText = _ColorResult._formatHexByte(alpha);
    return '#$redText$greenText$blueText$alphaText';
  }
}

class _ColorResult {
  const _ColorResult({
    required this.value,
    required this.hex,
    required this.argbHex,
    required this.rgbaHex,
    required this.rgb,
    required this.rgba,
    required this.hsl,
    required this.hsv,
    required this.cmyk,
    required this.flutterColor,
    required this.cssVariable,
    required this.flutterConst,
    required this.swiftUIColor,
    required this.androidColor,
    required this.statusText,
  });

  factory _ColorResult.fromValue(
    _ColorValue value, {
    required String statusText,
  }) {
    final red = _formatHexByte(value.red);
    final green = _formatHexByte(value.green);
    final blue = _formatHexByte(value.blue);
    final alpha = _formatHexByte(value.alpha);

    return _ColorResult(
      value: value,
      hex: '#$red$green$blue',
      argbHex: '#$alpha$red$green$blue',
      rgbaHex: '#$red$green$blue$alpha',
      rgb: 'rgb(${value.red}, ${value.green}, ${value.blue})',
      rgba:
          'rgba(${value.red}, ${value.green}, ${value.blue}, ${_formatAlpha(value.alpha)})',
      hsl: _formatHsl(value),
      hsv: _formatHsv(value),
      cmyk: _formatCmyk(value),
      flutterColor: 'Color(0x$alpha$red$green$blue)',
      cssVariable: '--color-primary: #$red$green$blue;',
      flutterConst:
          'static const Color primary = Color(0x$alpha$red$green$blue);',
      swiftUIColor:
          'UIColor(red: ${_formatUnit(value.red)}, green: ${_formatUnit(value.green)}, blue: ${_formatUnit(value.blue)}, alpha: ${_formatAlpha(value.alpha)})',
      androidColor: '<color name="primary">#$alpha$red$green$blue</color>',
      statusText: statusText,
    );
  }

  final _ColorValue value;
  final String hex;
  final String argbHex;
  final String rgbaHex;
  final String rgb;
  final String rgba;
  final String hsl;
  final String hsv;
  final String cmyk;
  final String flutterColor;
  final String cssVariable;
  final String flutterConst;
  final String swiftUIColor;
  final String androidColor;
  final String statusText;

  _ColorResult copyWith({required String statusText}) {
    return _ColorResult(
      value: value,
      hex: hex,
      argbHex: argbHex,
      rgbaHex: rgbaHex,
      rgb: rgb,
      rgba: rgba,
      hsl: hsl,
      hsv: hsv,
      cmyk: cmyk,
      flutterColor: flutterColor,
      cssVariable: cssVariable,
      flutterConst: flutterConst,
      swiftUIColor: swiftUIColor,
      androidColor: androidColor,
      statusText: statusText,
    );
  }

  static String _formatHexByte(int value) {
    return value.toRadixString(16).padLeft(2, '0').toUpperCase();
  }

  static String _formatAlpha(int alpha) {
    if (alpha == 255) {
      return '1';
    }

    final alphaText = (alpha / 255).toStringAsFixed(3);
    return alphaText
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _formatUnit(int channel) {
    final valueText = (channel / 255).toStringAsFixed(3);
    return valueText
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _formatHsl(_ColorValue value) {
    final channels = _normalizedRgb(value);
    final maxValue = channels.reduce((double a, double b) => a > b ? a : b);
    final minValue = channels.reduce((double a, double b) => a < b ? a : b);
    final delta = maxValue - minValue;
    final lightness = (maxValue + minValue) / 2;
    final saturation = delta == 0
        ? 0.0
        : delta / (1 - (2 * lightness - 1).abs());

    return 'hsl(${_hueDegrees(channels, maxValue, delta)}, '
        '${_percent(saturation)}, ${_percent(lightness)})';
  }

  static String _formatHsv(_ColorValue value) {
    final channels = _normalizedRgb(value);
    final maxValue = channels.reduce((double a, double b) => a > b ? a : b);
    final minValue = channels.reduce((double a, double b) => a < b ? a : b);
    final delta = maxValue - minValue;
    final saturation = maxValue == 0 ? 0.0 : delta / maxValue;

    return 'hsv(${_hueDegrees(channels, maxValue, delta)}, '
        '${_percent(saturation)}, ${_percent(maxValue)})';
  }

  static String _formatCmyk(_ColorValue value) {
    final channels = _normalizedRgb(value);
    final maxValue = channels.reduce((double a, double b) => a > b ? a : b);
    final black = 1 - maxValue;

    if (black == 1) {
      return 'cmyk(0%, 0%, 0%, 100%)';
    }

    final cyan = (1 - channels[0] - black) / (1 - black);
    final magenta = (1 - channels[1] - black) / (1 - black);
    final yellow = (1 - channels[2] - black) / (1 - black);

    return 'cmyk(${_percent(cyan)}, ${_percent(magenta)}, '
        '${_percent(yellow)}, ${_percent(black)})';
  }

  static List<double> _normalizedRgb(_ColorValue value) {
    return <double>[value.red / 255, value.green / 255, value.blue / 255];
  }

  static int _hueDegrees(List<double> channels, double maxValue, double delta) {
    if (delta == 0) {
      return 0;
    }

    final red = channels[0];
    final green = channels[1];
    final blue = channels[2];
    final hue = switch (maxValue) {
      final value when value == red => ((green - blue) / delta) % 6,
      final value when value == green => (blue - red) / delta + 2,
      _ => (red - green) / delta + 4,
    };

    return (hue * 60).round() % 360;
  }

  static String _percent(double value) {
    return '${(value * 100).round()}%';
  }
}

class _ColorInputBar extends StatelessWidget {
  const _ColorInputBar({
    required this.controller,
    required this.onConvert,
    required this.onClear,
  });

  final TextEditingController controller;
  final VoidCallback onConvert;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: _buildActions()),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildTextField()),
            const SizedBox(width: 12),
            _buildActions(),
          ],
        );
      },
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: controller,
      onSubmitted: (_) => onConvert(),
      decoration: const InputDecoration(
        labelText: '颜色值',
        hintText: '#0F766E / rgba(15, 118, 110, 0.5) / Color(0xFF0F766E)',
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: onConvert,
          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
          label: const Text('转换'),
        ),
        OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.cleaning_services_rounded, size: 18),
          label: const Text('清空'),
        ),
      ],
    );
  }
}

class _ColorMessageBanner extends StatelessWidget {
  const _ColorMessageBanner({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final foreground = isError
        ? const Color(0xFF9F1239)
        : const Color(0xFF0F766E);
    final background = isError
        ? const Color(0xFFFFEEF2)
        : const Color(0xFFEAF7F6);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          message,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ColorEmptyState extends StatelessWidget {
  const _ColorEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '输入颜色值后点击转换，这里会显示预览色块和各格式结果。',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607180)),
      ),
    );
  }
}

class _ColorResultView extends StatelessWidget {
  const _ColorResultView({required this.result, required this.onCopyValue});

  final _ColorResult result;
  final Future<void> Function(String value, String statusText) onCopyValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ColorPreviewPanel(result: result),
        const SizedBox(width: 18),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ColorResultGroupTitle('常用格式'),
                _ColorResultTile(
                  label: 'HEX',
                  value: result.hex,
                  onCopy: () => onCopyValue(result.hex, '已复制 HEX。'),
                ),
                _ColorResultTile(
                  label: 'ARGB HEX',
                  value: result.argbHex,
                  onCopy: () => onCopyValue(result.argbHex, '已复制 ARGB HEX。'),
                ),
                _ColorResultTile(
                  label: 'RGBA HEX',
                  value: result.rgbaHex,
                  onCopy: () => onCopyValue(result.rgbaHex, '已复制 RGBA HEX。'),
                ),
                _ColorResultTile(
                  label: 'RGB',
                  value: result.rgb,
                  onCopy: () => onCopyValue(result.rgb, '已复制 RGB。'),
                ),
                _ColorResultTile(
                  label: 'RGBA',
                  value: result.rgba,
                  onCopy: () => onCopyValue(result.rgba, '已复制 RGBA。'),
                ),
                _ColorResultTile(
                  label: 'HSL',
                  value: result.hsl,
                  onCopy: () => onCopyValue(result.hsl, '已复制 HSL。'),
                ),
                _ColorResultTile(
                  label: 'HSV',
                  value: result.hsv,
                  onCopy: () => onCopyValue(result.hsv, '已复制 HSV。'),
                ),
                _ColorResultTile(
                  label: 'CMYK',
                  value: result.cmyk,
                  onCopy: () => onCopyValue(result.cmyk, '已复制 CMYK。'),
                ),
                _ColorResultTile(
                  label: 'Flutter',
                  value: result.flutterColor,
                  onCopy: () =>
                      onCopyValue(result.flutterColor, '已复制 Flutter Color。'),
                ),
                const SizedBox(height: 8),
                const _ColorResultGroupTitle('标注模板'),
                _ColorResultTile(
                  label: 'CSS 变量',
                  value: result.cssVariable,
                  onCopy: () => onCopyValue(result.cssVariable, '已复制 CSS 变量。'),
                ),
                _ColorResultTile(
                  label: 'Flutter 常量',
                  value: result.flutterConst,
                  onCopy: () =>
                      onCopyValue(result.flutterConst, '已复制 Flutter 常量。'),
                ),
                _ColorResultTile(
                  label: 'Swift UIColor',
                  value: result.swiftUIColor,
                  onCopy: () =>
                      onCopyValue(result.swiftUIColor, '已复制 Swift UIColor。'),
                ),
                _ColorResultTile(
                  label: 'Android XML',
                  value: result.androidColor,
                  onCopy: () =>
                      onCopyValue(result.androidColor, '已复制 Android XML。'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorResultGroupTitle extends StatelessWidget {
  const _ColorResultGroupTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: const Color(0xFF23313C),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ColorPreviewPanel extends StatelessWidget {
  const _ColorPreviewPanel({required this.result});

  final _ColorResult result;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8E2E8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: result.value.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x22000000)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                result.hex,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF23313C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A ${result.value.alpha}  R ${result.value.red}  G ${result.value.green}  B ${result.value.blue}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: const Color(0xFF607180)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorResultTile extends StatelessWidget {
  const _ColorResultTile({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD8E2E8)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF607180),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF23313C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                tooltip: '复制 $label',
                icon: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
