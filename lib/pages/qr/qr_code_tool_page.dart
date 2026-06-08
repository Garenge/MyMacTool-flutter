import 'dart:io';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'qr_code_decode_source.dart';
import 'qr_code_image_decoder.dart';
import 'qr_code_logo_info.dart';

class QrCodeToolPage extends StatefulWidget {
  const QrCodeToolPage({super.key});

  @override
  State<QrCodeToolPage> createState() => _QrCodeToolPageState();
}

class _QrCodeToolPageState extends State<QrCodeToolPage> {
  static const XTypeGroup _imageTypeGroup = XTypeGroup(
    label: 'images',
    extensions: <String>['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
    mimeTypes: <String>['image/*'],
  );

  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _decodeResultController = TextEditingController();
  final FocusNode _decodeFocusNode = FocusNode();
  final QrCodeImageDecoder _decoder = const QrCodeImageDecoder();
  final QrCodeLogoLoader _logoLoader = const QrCodeLogoLoader();
  bool _urlEncodeContent = false;
  int _errorCorrectionLevel = QrErrorCorrectLevel.M;
  QrEyeShape _eyeShape = QrEyeShape.square;
  QrDataModuleShape _dataModuleShape = QrDataModuleShape.square;
  int _qrImageSize = 720;
  double _logoScale = 0.18;
  Color _foregroundColor = Colors.black;
  Color _backgroundColor = Colors.white;
  QrCodeLogoInfo? _logoInfo;
  bool _isDraggingFile = false;
  bool _isDecoding = false;
  String? _generateStatusText;
  String? _generateErrorText;
  String? _decodeStatusText;
  String? _decodeErrorText;
  String? _lastDecodedSource;

  @override
  void dispose() {
    _inputController.dispose();
    _decodeResultController.dispose();
    _decodeFocusNode.dispose();
    super.dispose();
  }

  String get _rawContent => _inputController.text;

  String get _qrContent {
    if (!_urlEncodeContent) {
      return _rawContent;
    }

    return Uri.encodeComponent(_rawContent);
  }

  bool get _canGenerate => _rawContent.trim().isNotEmpty;

  void _handleInputChanged(String _) {
    setState(() {
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  void _handleUrlEncodeChanged(bool value) {
    setState(() {
      _urlEncodeContent = value;
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  void _handleErrorCorrectionLevelChanged(int value) {
    setState(() {
      _errorCorrectionLevel = value;
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  void _handleEyeShapeChanged(QrEyeShape value) {
    setState(() {
      _eyeShape = value;
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  void _handleDataModuleShapeChanged(QrDataModuleShape value) {
    setState(() {
      _dataModuleShape = value;
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  void _handleQrImageSizeChanged(double value) {
    setState(() {
      _qrImageSize = value.round();
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  void _handleLogoScaleChanged(double value) {
    setState(() {
      _logoScale = value;
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  void _handleForegroundColorChanged(Color value) {
    setState(() {
      _foregroundColor = value;
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  void _handleBackgroundColorChanged(Color value) {
    setState(() {
      _backgroundColor = value;
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  void _handleClearInput() {
    setState(() {
      _inputController.clear();
      _generateStatusText = null;
      _generateErrorText = null;
    });
  }

  Future<void> _handlePickLogoImage() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_imageTypeGroup],
    );

    if (file == null || !mounted) {
      return;
    }

    try {
      final logoInfo = await _logoLoader.load(file.path);

      if (!mounted) {
        return;
      }

      setState(() {
        _logoInfo = logoInfo;
        _errorCorrectionLevel = QrErrorCorrectLevel.H;
        _generateStatusText = '已添加 Logo，并自动切换到纠错 H。';
        _generateErrorText = null;
      });
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generateErrorText = error.message;
        _generateStatusText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generateErrorText = '读取 Logo 图片失败，请重新选择。';
        _generateStatusText = null;
      });
    }
  }

  void _handleClearLogoImage() {
    setState(() {
      _logoInfo = null;
      _generateStatusText = '已移除 Logo。';
      _generateErrorText = null;
    });
  }

  Future<void> _handleCopyGeneratedContent() async {
    if (!_canGenerate) {
      setState(() {
        _generateErrorText = '请先输入要生成二维码的内容。';
        _generateStatusText = null;
      });
      return;
    }

    await Clipboard.setData(ClipboardData(text: _qrContent));

    if (!mounted) {
      return;
    }

    setState(() {
      _generateStatusText = _urlEncodeContent ? '已复制 URL 编码后的内容。' : '已复制原始内容。';
      _generateErrorText = null;
    });
  }

  Future<void> _handleSaveQrImage() async {
    if (!_canGenerate) {
      setState(() {
        _generateErrorText = '请先输入要生成二维码的内容。';
        _generateStatusText = null;
      });
      return;
    }

    final saveLocation = await getSaveLocation(
      suggestedName: 'mytools_qrcode.png',
      acceptedTypeGroups: const <XTypeGroup>[
        XTypeGroup(label: 'png', extensions: <String>['png']),
      ],
    );

    if (saveLocation == null || !mounted) {
      return;
    }

    try {
      final painter = QrPainter(
        data: _qrContent,
        version: QrVersions.auto,
        errorCorrectionLevel: _errorCorrectionLevel,
        gapless: false,
        eyeStyle: QrEyeStyle(eyeShape: _eyeShape, color: _foregroundColor),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: _dataModuleShape,
          color: _foregroundColor,
        ),
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final imageSize = _qrImageSize.toDouble();
      final imageRect = Rect.fromLTWH(0, 0, imageSize, imageSize);
      canvas.drawRect(imageRect, Paint()..color = _backgroundColor);
      painter.paint(canvas, Size.square(imageSize));
      await _paintLogo(canvas, imageSize);
      final picture = recorder.endRecording();
      final image = await picture.toImage(_qrImageSize, _qrImageSize);
      final imageData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (imageData == null) {
        throw const FormatException('二维码图片生成失败。');
      }

      await File(
        saveLocation.path,
      ).writeAsBytes(imageData.buffer.asUint8List());

      if (!mounted) {
        return;
      }

      setState(() {
        _generateStatusText = '二维码图片已保存。';
        _generateErrorText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _generateErrorText = '保存二维码图片失败，请稍后重试。';
        _generateStatusText = null;
      });
    }
  }

  Future<void> _paintLogo(Canvas canvas, double qrSize) async {
    final logoInfo = _logoInfo;

    if (logoInfo == null) {
      return;
    }

    final logoCodec = await ui.instantiateImageCodec(logoInfo.bytes);
    final logoFrame = await logoCodec.getNextFrame();
    final logoImage = logoFrame.image;
    final logoBoxSize = qrSize * _logoScale;
    final logoRect = Rect.fromCenter(
      center: Offset(qrSize / 2, qrSize / 2),
      width: logoBoxSize,
      height: logoBoxSize,
    );
    final backgroundRect = logoRect.inflate(qrSize * 0.018);
    final radius = Radius.circular(qrSize * 0.035);

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, radius),
      Paint()..color = _backgroundColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (qrSize * 0.006).clamp(1, 8).toDouble()
        ..color = _backgroundColor.withValues(alpha: 0.92),
    );
    paintImage(
      canvas: canvas,
      rect: logoRect,
      image: logoImage,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }

  Future<void> _handlePickImage() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_imageTypeGroup],
    );

    if (file == null || !mounted) {
      return;
    }

    await _decodeImageFile(file.path);
  }

  Future<void> _handleDropFiles(List<DropItem> files) async {
    final path = files
        .map((DropItem item) => item.path)
        .whereType<String>()
        .cast<String?>()
        .firstWhere(
          (String? value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        );

    if (path == null) {
      setState(() {
        _decodeErrorText = '请拖入一个图片文件。';
        _decodeStatusText = null;
      });
      return;
    }

    await _decodeImageFile(path);
  }

  Future<void> _handlePasteImage() async {
    final sources = <QrDecodeImageSource>[];
    final imageBytes = await Pasteboard.image;

    if (imageBytes != null && imageBytes.isNotEmpty) {
      sources.add(QrDecodeImageSource.bytes('剪贴板图片', imageBytes));
    }

    final files = await Pasteboard.files();
    for (final file in files) {
      sources.add(QrDecodeImageSource.path(file));
    }

    final text = await Pasteboard.text;
    final textPath = resolveQrClipboardTextPath(text);

    if (!mounted) {
      return;
    }

    if (textPath != null) {
      sources.add(QrDecodeImageSource.path(textPath));
    }

    if (sources.isEmpty) {
      setState(() {
        _decodeErrorText = text == null || text.trim().isEmpty
            ? '剪贴板中没有可解析的图片或图片文件。'
            : '剪贴板是文本内容，请粘贴图片或复制图片文件后再解析。';
        _decodeStatusText = null;
      });
      return;
    }

    await _decodeClipboardSources(sources);
  }

  Future<void> _decodeClipboardSources(
    List<QrDecodeImageSource> sources,
  ) async {
    if (_isDecoding) {
      return;
    }

    setState(() {
      _isDecoding = true;
      _decodeStatusText = '正在解析剪贴板二维码...';
      _decodeErrorText = null;
    });

    var lastErrorText = '剪贴板中的图片没有识别到二维码内容。';

    try {
      for (final source in sources) {
        try {
          final bytes = await source.readBytes();
          final result = _decoder.decode(bytes);

          if (!mounted) {
            return;
          }

          setState(() {
            _decodeResultController.text = result;
            _lastDecodedSource = source.label;
            _decodeStatusText = looksLikeWebUrl(result)
                ? '解析完成，内容看起来是 URL。'
                : '二维码解析完成。';
            _decodeErrorText = null;
          });
          return;
        } on FormatException catch (error) {
          lastErrorText = error.message;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _decodeErrorText = lastErrorText;
        _decodeStatusText = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDecoding = false;
        });
      }
    }
  }

  Future<void> _decodeImageFile(String path) async {
    final file = File(path);

    if (!file.existsSync()) {
      setState(() {
        _decodeErrorText = '图片文件不存在，请重新选择。';
        _decodeStatusText = null;
      });
      return;
    }

    await _decodeImageBytes(await file.readAsBytes(), source: path);
  }

  Future<void> _decodeImageBytes(
    Uint8List bytes, {
    required String source,
  }) async {
    if (_isDecoding) {
      return;
    }

    setState(() {
      _isDecoding = true;
      _decodeStatusText = '正在解析二维码...';
      _decodeErrorText = null;
    });

    try {
      final result = _decoder.decode(bytes);

      if (!mounted) {
        return;
      }

      setState(() {
        _decodeResultController.text = result;
        _lastDecodedSource = source;
        _decodeStatusText = looksLikeWebUrl(result)
            ? '解析完成，内容看起来是 URL。'
            : '二维码解析完成。';
        _decodeErrorText = null;
      });
    } on FormatException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _decodeErrorText = error.message;
        _decodeStatusText = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDecoding = false;
        });
      }
    }
  }

  Future<void> _handleCopyDecodedResult() async {
    final text = _decodeResultController.text;

    if (text.trim().isEmpty) {
      setState(() {
        _decodeErrorText = '当前没有可复制的解析结果。';
        _decodeStatusText = null;
      });
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));

    if (!mounted) {
      return;
    }

    setState(() {
      _decodeStatusText = '已复制解析结果。';
      _decodeErrorText = null;
    });
  }

  Future<void> _handleCopyUrlEncodedDecodedResult() async {
    final text = _decodeResultController.text;

    if (text.trim().isEmpty) {
      setState(() {
        _decodeErrorText = '当前没有可编码的解析结果。';
        _decodeStatusText = null;
      });
      return;
    }

    await Clipboard.setData(ClipboardData(text: Uri.encodeComponent(text)));

    if (!mounted) {
      return;
    }

    setState(() {
      _decodeStatusText = '已复制 URL 编码后的解析结果。';
      _decodeErrorText = null;
    });
  }

  Future<void> _handleOpenDecodedUrl() async {
    final text = _decodeResultController.text.trim();

    if (!looksLikeWebUrl(text)) {
      setState(() {
        _decodeErrorText = '解析结果不是可打开的 URL。';
        _decodeStatusText = null;
      });
      return;
    }

    try {
      final result = await Process.run('open', <String>[text]);

      if (result.exitCode != 0) {
        throw ProcessException('open', <String>[text], '${result.stderr}');
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _decodeStatusText = '已打开解析出的 URL。';
        _decodeErrorText = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _decodeErrorText = '打开 URL 失败，请检查内容是否有效。';
        _decodeStatusText = null;
      });
    }
  }

  void _handleClearDecodeResult() {
    setState(() {
      _decodeResultController.clear();
      _lastDecodedSource = null;
      _decodeStatusText = null;
      _decodeErrorText = null;
    });
  }

  bool get _canOpenDecodedUrl => looksLikeWebUrl(_decodeResultController.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '二维码工具',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF23313C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '支持从字符串生成二维码，也支持粘贴、拖拽或选择图片解析二维码内容。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF607180),
            ),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8E2E8)),
            ),
            child: TabBar(
              onTap: (int index) {
                if (index == 1) {
                  _decodeFocusNode.requestFocus();
                }
              },
              labelColor: const Color(0xFF0F766E),
              unselectedLabelColor: const Color(0xFF607180),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: '生成二维码', icon: Icon(Icons.qr_code_2_rounded)),
                Tab(text: '解析二维码', icon: Icon(Icons.document_scanner_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                _QrGeneratePanel(
                  controller: _inputController,
                  qrContent: _qrContent,
                  canGenerate: _canGenerate,
                  urlEncodeContent: _urlEncodeContent,
                  errorCorrectionLevel: _errorCorrectionLevel,
                  eyeShape: _eyeShape,
                  dataModuleShape: _dataModuleShape,
                  qrImageSize: _qrImageSize,
                  foregroundColor: _foregroundColor,
                  backgroundColor: _backgroundColor,
                  logoInfo: _logoInfo,
                  logoScale: _logoScale,
                  statusText: _generateErrorText ?? _generateStatusText,
                  isError: _generateErrorText != null,
                  onInputChanged: _handleInputChanged,
                  onUrlEncodeChanged: _handleUrlEncodeChanged,
                  onErrorCorrectionLevelChanged:
                      _handleErrorCorrectionLevelChanged,
                  onEyeShapeChanged: _handleEyeShapeChanged,
                  onDataModuleShapeChanged: _handleDataModuleShapeChanged,
                  onQrImageSizeChanged: _handleQrImageSizeChanged,
                  onLogoScaleChanged: _handleLogoScaleChanged,
                  onForegroundColorChanged: _handleForegroundColorChanged,
                  onBackgroundColorChanged: _handleBackgroundColorChanged,
                  onPickLogoImage: _handlePickLogoImage,
                  onClearLogoImage: _handleClearLogoImage,
                  onCopyContent: _handleCopyGeneratedContent,
                  onSaveImage: _handleSaveQrImage,
                  onClear: _handleClearInput,
                ),
                _QrDecodeShortcutScope(
                  focusNode: _decodeFocusNode,
                  onPasteImage: _handlePasteImage,
                  child: _QrDecodePanel(
                    controller: _decodeResultController,
                    isDraggingFile: _isDraggingFile,
                    isDecoding: _isDecoding,
                    source: _lastDecodedSource,
                    statusText: _decodeErrorText ?? _decodeStatusText,
                    isError: _decodeErrorText != null,
                    onDragEntered: () {
                      setState(() {
                        _isDraggingFile = true;
                      });
                    },
                    onDragExited: () {
                      setState(() {
                        _isDraggingFile = false;
                      });
                    },
                    onDropFiles: (List<DropItem> files) async {
                      setState(() {
                        _isDraggingFile = false;
                      });
                      await _handleDropFiles(files);
                    },
                    onPickImage: _handlePickImage,
                    onPasteImage: _handlePasteImage,
                    onCopyResult: _handleCopyDecodedResult,
                    onCopyUrlEncodedResult: _handleCopyUrlEncodedDecodedResult,
                    onOpenUrl: _handleOpenDecodedUrl,
                    canOpenUrl: _canOpenDecodedUrl,
                    onClear: _handleClearDecodeResult,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrGeneratePanel extends StatelessWidget {
  const _QrGeneratePanel({
    required this.controller,
    required this.qrContent,
    required this.canGenerate,
    required this.urlEncodeContent,
    required this.errorCorrectionLevel,
    required this.eyeShape,
    required this.dataModuleShape,
    required this.qrImageSize,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.logoInfo,
    required this.logoScale,
    required this.statusText,
    required this.isError,
    required this.onInputChanged,
    required this.onUrlEncodeChanged,
    required this.onErrorCorrectionLevelChanged,
    required this.onEyeShapeChanged,
    required this.onDataModuleShapeChanged,
    required this.onQrImageSizeChanged,
    required this.onLogoScaleChanged,
    required this.onForegroundColorChanged,
    required this.onBackgroundColorChanged,
    required this.onPickLogoImage,
    required this.onClearLogoImage,
    required this.onCopyContent,
    required this.onSaveImage,
    required this.onClear,
  });

  final TextEditingController controller;
  final String qrContent;
  final bool canGenerate;
  final bool urlEncodeContent;
  final int errorCorrectionLevel;
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;
  final int qrImageSize;
  final Color foregroundColor;
  final Color backgroundColor;
  final QrCodeLogoInfo? logoInfo;
  final double logoScale;
  final String? statusText;
  final bool isError;
  final ValueChanged<String> onInputChanged;
  final ValueChanged<bool> onUrlEncodeChanged;
  final ValueChanged<int> onErrorCorrectionLevelChanged;
  final ValueChanged<QrEyeShape> onEyeShapeChanged;
  final ValueChanged<QrDataModuleShape> onDataModuleShapeChanged;
  final ValueChanged<double> onQrImageSizeChanged;
  final ValueChanged<double> onLogoScaleChanged;
  final ValueChanged<Color> onForegroundColorChanged;
  final ValueChanged<Color> onBackgroundColorChanged;
  final VoidCallback onPickLogoImage;
  final VoidCallback onClearLogoImage;
  final VoidCallback onCopyContent;
  final VoidCallback onSaveImage;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Text(
              '生成二维码',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF23313C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              minLines: 4,
              maxLines: 5,
              onChanged: onInputChanged,
              decoration: const InputDecoration(
                labelText: '字符串',
                hintText: 'https://example.com/path?name=MyTools',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              value: urlEncodeContent,
              onChanged: onUrlEncodeChanged,
              contentPadding: EdgeInsets.zero,
              title: const Text('生成前先 URL 编码'),
            ),
            _QrGenerateOptions(
              errorCorrectionLevel: errorCorrectionLevel,
              eyeShape: eyeShape,
              dataModuleShape: dataModuleShape,
              qrImageSize: qrImageSize,
              foregroundColor: foregroundColor,
              backgroundColor: backgroundColor,
              logoInfo: logoInfo,
              logoScale: logoScale,
              onErrorCorrectionLevelChanged: onErrorCorrectionLevelChanged,
              onEyeShapeChanged: onEyeShapeChanged,
              onDataModuleShapeChanged: onDataModuleShapeChanged,
              onQrImageSizeChanged: onQrImageSizeChanged,
              onLogoScaleChanged: onLogoScaleChanged,
              onForegroundColorChanged: onForegroundColorChanged,
              onBackgroundColorChanged: onBackgroundColorChanged,
              onPickLogoImage: onPickLogoImage,
              onClearLogoImage: onClearLogoImage,
            ),
            const SizedBox(height: 12),
            if (statusText != null) ...[
              _QrMessageBanner(message: statusText!, isError: isError),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 290,
              child: Center(
                child: canGenerate
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD8E2E8)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: _QrPreview(
                            qrContent: qrContent,
                            errorCorrectionLevel: errorCorrectionLevel,
                            eyeShape: eyeShape,
                            dataModuleShape: dataModuleShape,
                            foregroundColor: foregroundColor,
                            backgroundColor: backgroundColor,
                            logoInfo: logoInfo,
                            logoScale: logoScale,
                          ),
                        ),
                      )
                    : const _QrEmptyState(message: '输入字符串后会在这里生成二维码。'),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onCopyContent,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('复制内容'),
                ),
                OutlinedButton.icon(
                  onPressed: onSaveImage,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('保存PNG'),
                ),
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                  label: const Text('清空'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QrGenerateOptions extends StatelessWidget {
  const _QrGenerateOptions({
    required this.errorCorrectionLevel,
    required this.eyeShape,
    required this.dataModuleShape,
    required this.qrImageSize,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.logoInfo,
    required this.logoScale,
    required this.onErrorCorrectionLevelChanged,
    required this.onEyeShapeChanged,
    required this.onDataModuleShapeChanged,
    required this.onQrImageSizeChanged,
    required this.onLogoScaleChanged,
    required this.onForegroundColorChanged,
    required this.onBackgroundColorChanged,
    required this.onPickLogoImage,
    required this.onClearLogoImage,
  });

  static const List<_QrCorrectionLevelOption> _levelOptions = [
    _QrCorrectionLevelOption('L', QrErrorCorrectLevel.L),
    _QrCorrectionLevelOption('M', QrErrorCorrectLevel.M),
    _QrCorrectionLevelOption('Q', QrErrorCorrectLevel.Q),
    _QrCorrectionLevelOption('H', QrErrorCorrectLevel.H),
  ];

  static const List<_QrEyeShapeOption> _eyeShapeOptions = [
    _QrEyeShapeOption('方形', QrEyeShape.square),
    _QrEyeShapeOption('圆形', QrEyeShape.circle),
  ];

  static const List<_QrDataModuleShapeOption> _dataModuleShapeOptions = [
    _QrDataModuleShapeOption('方形', QrDataModuleShape.square),
    _QrDataModuleShapeOption('圆点', QrDataModuleShape.circle),
  ];

  static const List<Color> _foregroundOptions = [
    Colors.black,
    Color(0xFF0F766E),
    Color(0xFF1D4ED8),
    Color(0xFF7C2D12),
    Color(0xFF831843),
  ];

  static const List<Color> _backgroundOptions = [
    Colors.white,
    Color(0xFFF7FAFB),
    Color(0xFFFFF7ED),
    Color(0xFFEFF6FF),
    Color(0xFFFDF2F8),
  ];

  final int errorCorrectionLevel;
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;
  final int qrImageSize;
  final Color foregroundColor;
  final Color backgroundColor;
  final QrCodeLogoInfo? logoInfo;
  final double logoScale;
  final ValueChanged<int> onErrorCorrectionLevelChanged;
  final ValueChanged<QrEyeShape> onEyeShapeChanged;
  final ValueChanged<QrDataModuleShape> onDataModuleShapeChanged;
  final ValueChanged<double> onQrImageSizeChanged;
  final ValueChanged<double> onLogoScaleChanged;
  final ValueChanged<Color> onForegroundColorChanged;
  final ValueChanged<Color> onBackgroundColorChanged;
  final VoidCallback onPickLogoImage;
  final VoidCallback onClearLogoImage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '生成设置',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF23313C),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _levelOptions
                  .map(
                    (_QrCorrectionLevelOption option) => ChoiceChip(
                      label: Text('纠错 ${option.label}'),
                      selected: errorCorrectionLevel == option.value,
                      onSelected: (_) =>
                          onErrorCorrectionLevelChanged(option.value),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            _QrShapeOptionRow<QrEyeShape, _QrEyeShapeOption>(
              label: '定位点',
              options: _eyeShapeOptions,
              selectedValue: eyeShape,
              valueOf: (_QrEyeShapeOption option) => option.value,
              labelOf: (_QrEyeShapeOption option) => option.label,
              onChanged: onEyeShapeChanged,
            ),
            const SizedBox(height: 10),
            _QrShapeOptionRow<QrDataModuleShape, _QrDataModuleShapeOption>(
              label: '码点',
              options: _dataModuleShapeOptions,
              selectedValue: dataModuleShape,
              valueOf: (_QrDataModuleShapeOption option) => option.value,
              labelOf: (_QrDataModuleShapeOption option) => option.label,
              onChanged: onDataModuleShapeChanged,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '导出尺寸',
                    style: TextStyle(
                      color: Color(0xFF607180),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${qrImageSize}px',
                  style: const TextStyle(
                    color: Color(0xFF23313C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Slider(
              value: qrImageSize.toDouble(),
              min: 256,
              max: 1024,
              divisions: 6,
              onChanged: onQrImageSizeChanged,
            ),
            _QrColorOptionRow(
              label: '前景色',
              selectedColor: foregroundColor,
              colors: _foregroundOptions,
              onChanged: onForegroundColorChanged,
            ),
            const SizedBox(height: 10),
            _QrColorOptionRow(
              label: '背景色',
              selectedColor: backgroundColor,
              colors: _backgroundOptions,
              onChanged: onBackgroundColorChanged,
            ),
            const SizedBox(height: 12),
            _QrLogoOptions(
              logoInfo: logoInfo,
              logoScale: logoScale,
              onLogoScaleChanged: onLogoScaleChanged,
              onPickLogoImage: onPickLogoImage,
              onClearLogoImage: onClearLogoImage,
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPreview extends StatelessWidget {
  const _QrPreview({
    required this.qrContent,
    required this.errorCorrectionLevel,
    required this.eyeShape,
    required this.dataModuleShape,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.logoInfo,
    required this.logoScale,
  });

  final String qrContent;
  final int errorCorrectionLevel;
  final QrEyeShape eyeShape;
  final QrDataModuleShape dataModuleShape;
  final Color foregroundColor;
  final Color backgroundColor;
  final QrCodeLogoInfo? logoInfo;
  final double logoScale;

  @override
  Widget build(BuildContext context) {
    final logo = logoInfo;

    return SizedBox.square(
      dimension: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: qrContent,
            version: QrVersions.auto,
            errorCorrectionLevel: errorCorrectionLevel,
            size: 240,
            backgroundColor: backgroundColor,
            eyeStyle: QrEyeStyle(eyeShape: eyeShape, color: foregroundColor),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: dataModuleShape,
              color: foregroundColor,
            ),
          ),
          if (logo != null)
            _QrLogoOverlay(
              logo: logo,
              logoSize: 240 * logoScale,
              backgroundColor: backgroundColor,
            ),
        ],
      ),
    );
  }
}

class _QrLogoOverlay extends StatelessWidget {
  const _QrLogoOverlay({
    required this.logo,
    required this.logoSize,
    required this.backgroundColor,
  });

  final QrCodeLogoInfo logo;
  final double logoSize;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: backgroundColor, width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Image.memory(
          logo.bytes,
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _QrLogoOptions extends StatelessWidget {
  const _QrLogoOptions({
    required this.logoInfo,
    required this.logoScale,
    required this.onLogoScaleChanged,
    required this.onPickLogoImage,
    required this.onClearLogoImage,
  });

  final QrCodeLogoInfo? logoInfo;
  final double logoScale;
  final ValueChanged<double> onLogoScaleChanged;
  final VoidCallback onPickLogoImage;
  final VoidCallback onClearLogoImage;

  @override
  Widget build(BuildContext context) {
    final logo = logoInfo;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E2E8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Logo',
                    style: TextStyle(
                      color: Color(0xFF23313C),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${(logoScale * 100).round()}%',
                  style: const TextStyle(
                    color: Color(0xFF607180),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (logo == null)
              const _MutedQrText('可选嵌入 Logo，建议使用纠错 H 并控制在 24% 以内。')
            else
              _QrLogoSummary(logo: logo),
            Slider(
              value: logoScale,
              min: 0.12,
              max: 0.24,
              divisions: 6,
              onChanged: logo == null ? null : onLogoScaleChanged,
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPickLogoImage,
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                  label: Text(logo == null ? '选择Logo' : '更换Logo'),
                ),
                OutlinedButton.icon(
                  onPressed: logo == null ? null : onClearLogoImage,
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('移除Logo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QrLogoSummary extends StatelessWidget {
  const _QrLogoSummary({required this.logo});

  final QrCodeLogoInfo logo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            logo.bytes,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                logo.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF23313C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                logo.sizeLabel,
                style: const TextStyle(
                  color: Color(0xFF607180),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MutedQrText extends StatelessWidget {
  const _MutedQrText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: const Color(0xFF607180)),
    );
  }
}

class _QrColorOptionRow extends StatelessWidget {
  const _QrColorOptionRow({
    required this.label,
    required this.selectedColor,
    required this.colors,
    required this.onChanged,
  });

  final String label;
  final Color selectedColor;
  final List<Color> colors;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF607180),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors
                .map(
                  (Color color) => Tooltip(
                    message:
                        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                    child: InkWell(
                      onTap: () => onChanged(color),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedColor == color
                                ? const Color(0xFF0F766E)
                                : const Color(0xFFD8E2E8),
                            width: selectedColor == color ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _QrShapeOptionRow<T, O> extends StatelessWidget {
  const _QrShapeOptionRow({
    required this.label,
    required this.options,
    required this.selectedValue,
    required this.valueOf,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final List<O> options;
  final T selectedValue;
  final T Function(O option) valueOf;
  final String Function(O option) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF607180),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options
                .map(
                  (O option) => ChoiceChip(
                    label: Text(labelOf(option)),
                    selected: selectedValue == valueOf(option),
                    onSelected: (_) => onChanged(valueOf(option)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _QrCorrectionLevelOption {
  const _QrCorrectionLevelOption(this.label, this.value);

  final String label;
  final int value;
}

class _QrEyeShapeOption {
  const _QrEyeShapeOption(this.label, this.value);

  final String label;
  final QrEyeShape value;
}

class _QrDataModuleShapeOption {
  const _QrDataModuleShapeOption(this.label, this.value);

  final String label;
  final QrDataModuleShape value;
}

class _QrDecodePanel extends StatelessWidget {
  const _QrDecodePanel({
    required this.controller,
    required this.isDraggingFile,
    required this.isDecoding,
    required this.source,
    required this.statusText,
    required this.isError,
    required this.onDragEntered,
    required this.onDragExited,
    required this.onDropFiles,
    required this.onPickImage,
    required this.onPasteImage,
    required this.onCopyResult,
    required this.onCopyUrlEncodedResult,
    required this.onOpenUrl,
    required this.canOpenUrl,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool isDraggingFile;
  final bool isDecoding;
  final String? source;
  final String? statusText;
  final bool isError;
  final VoidCallback onDragEntered;
  final VoidCallback onDragExited;
  final ValueChanged<List<DropItem>> onDropFiles;
  final VoidCallback onPickImage;
  final VoidCallback onPasteImage;
  final VoidCallback onCopyResult;
  final VoidCallback onCopyUrlEncodedResult;
  final VoidCallback onOpenUrl;
  final bool canOpenUrl;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDraggingFile
        ? const Color(0xFF0F766E)
        : const Color(0xFFD8E2E8);

    return DropTarget(
      onDragEntered: (_) => onDragEntered(),
      onDragExited: (_) => onDragExited(),
      onDragDone: (DropDoneDetails details) => onDropFiles(details.files),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: borderColor,
            width: isDraggingFile ? 1.4 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '解析二维码',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF23313C),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isDecoding ? '正在解析图片...' : '支持粘贴、拖拽或选择二维码图片。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF607180),
                ),
              ),
              const SizedBox(height: 12),
              if (statusText != null) ...[
                _QrMessageBanner(message: statusText!, isError: isError),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: true,
                  minLines: null,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    labelText: '解析结果',
                    hintText: '解析出的二维码内容会显示在这里',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              if (source != null) ...[
                const SizedBox(height: 8),
                Text(
                  '来源：$source',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF607180),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onPasteImage,
                    icon: const Icon(Icons.content_paste_rounded, size: 18),
                    label: const Text('粘贴解析'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onPickImage,
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('选择图片'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onCopyResult,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('复制结果'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onCopyUrlEncodedResult,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: const Text('复制URL编码'),
                  ),
                  OutlinedButton.icon(
                    onPressed: canOpenUrl ? onOpenUrl : null,
                    icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                    label: const Text('打开URL'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                    label: const Text('清空'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrDecodeShortcutScope extends StatefulWidget {
  const _QrDecodeShortcutScope({
    required this.focusNode,
    required this.onPasteImage,
    required this.child,
  });

  final FocusNode focusNode;
  final VoidCallback onPasteImage;
  final Widget child;

  @override
  State<_QrDecodeShortcutScope> createState() => _QrDecodeShortcutScopeState();
}

class _QrDecodeShortcutScopeState extends State<_QrDecodeShortcutScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.focusNode.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            const _PasteQrImageIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PasteQrImageIntent: CallbackAction<_PasteQrImageIntent>(
            onInvoke: (_) {
              widget.onPasteImage();
              return null;
            },
          ),
        },
        child: Focus(
          focusNode: widget.focusNode,
          autofocus: true,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PasteQrImageIntent extends Intent {
  const _PasteQrImageIntent();
}

class _QrMessageBanner extends StatelessWidget {
  const _QrMessageBanner({required this.message, required this.isError});

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

class _QrEmptyState extends StatelessWidget {
  const _QrEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF607180)),
    );
  }
}
