import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:pasteboard/pasteboard.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zxing2/qrcode.dart';

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
  final _QrImageDecoder _decoder = const _QrImageDecoder();
  bool _urlEncodeContent = false;
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

  void _handleClearInput() {
    setState(() {
      _inputController.clear();
      _generateStatusText = null;
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

    if (saveLocation == null) {
      return;
    }

    try {
      final painter = QrPainter(
        data: _qrContent,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        gapless: false,
      );
      final imageData = await painter.toImageData(
        720,
        format: ui.ImageByteFormat.png,
      );

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

  Future<void> _handlePickImage() async {
    final file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[_imageTypeGroup],
    );

    if (file == null) {
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
    final sources = <_ClipboardImageSource>[];
    final imageBytes = await Pasteboard.image;

    if (imageBytes != null && imageBytes.isNotEmpty) {
      sources.add(_ClipboardImageSource.bytes('剪贴板图片', imageBytes));
    }

    final files = await Pasteboard.files();
    for (final file in files) {
      sources.add(_ClipboardImageSource.path(file));
    }

    final text = await Pasteboard.text;
    final textPath = _resolveClipboardTextPath(text);

    if (textPath != null) {
      sources.add(_ClipboardImageSource.path(textPath));
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

  String? _resolveClipboardTextPath(String? text) {
    final value = text?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);

    if (uri != null && uri.isScheme('file')) {
      return uri.toFilePath();
    }

    if (File(value).existsSync()) {
      return value;
    }

    return null;
  }

  Future<void> _decodeClipboardSources(
    List<_ClipboardImageSource> sources,
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
            _decodeStatusText = _looksLikeUrl(result)
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
        _decodeStatusText = _looksLikeUrl(result)
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

  void _handleClearDecodeResult() {
    setState(() {
      _decodeResultController.clear();
      _lastDecodedSource = null;
      _decodeStatusText = null;
      _decodeErrorText = null;
    });
  }

  bool _looksLikeUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

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
                  statusText: _generateErrorText ?? _generateStatusText,
                  isError: _generateErrorText != null,
                  onInputChanged: _handleInputChanged,
                  onUrlEncodeChanged: _handleUrlEncodeChanged,
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

class _QrImageDecoder {
  const _QrImageDecoder();

  String decode(Uint8List bytes) {
    final image = image_lib.decodeImage(bytes);

    if (image == null) {
      throw const FormatException('无法读取图片，请选择 PNG、JPG、WebP 等常见图片格式。');
    }

    try {
      final source = RGBLuminanceSource(
        image.width,
        image.height,
        _buildArgbPixels(image),
      );
      final bitmap = BinaryBitmap(HybridBinarizer(source));
      final result = QRCodeReader().decode(bitmap);

      if (result.text.trim().isEmpty) {
        throw const FormatException('图片中没有识别到二维码内容。');
      }

      return result.text;
    } on ReaderException {
      throw const FormatException('图片中没有识别到二维码内容。');
    } on FormatException {
      rethrow;
    } catch (error) {
      throw const FormatException('二维码解析失败，请换一张更清晰的图片。');
    }
  }

  Int32List _buildArgbPixels(image_lib.Image image) {
    final pixels = Int32List(image.width * image.height);
    var index = 0;

    for (var y = 0; y < image.height; y += 1) {
      for (var x = 0; x < image.width; x += 1) {
        final pixel = image.getPixel(x, y);
        final alpha = pixel.aNormalized;
        final red = _blendOnWhite(pixel.r.toInt(), alpha);
        final green = _blendOnWhite(pixel.g.toInt(), alpha);
        final blue = _blendOnWhite(pixel.b.toInt(), alpha);

        pixels[index] = 0xFF000000 | (red << 16) | (green << 8) | blue;
        index += 1;
      }
    }

    return pixels;
  }

  int _blendOnWhite(int channel, num alpha) {
    return (channel * alpha + 255 * (1 - alpha)).round().clamp(0, 255);
  }
}

class _ClipboardImageSource {
  const _ClipboardImageSource._({
    required this.label,
    required this.bytes,
    required this.path,
  });

  factory _ClipboardImageSource.bytes(String label, Uint8List bytes) {
    return _ClipboardImageSource._(label: label, bytes: bytes, path: null);
  }

  factory _ClipboardImageSource.path(String path) {
    return _ClipboardImageSource._(label: path, bytes: null, path: path);
  }

  final String label;
  final Uint8List? bytes;
  final String? path;

  Future<Uint8List> readBytes() async {
    final directBytes = bytes;

    if (directBytes != null) {
      return directBytes;
    }

    final filePath = path;

    if (filePath == null || !File(filePath).existsSync()) {
      throw const FormatException('剪贴板中的图片文件不存在。');
    }

    return File(filePath).readAsBytes();
  }
}

class _QrGeneratePanel extends StatelessWidget {
  const _QrGeneratePanel({
    required this.controller,
    required this.qrContent,
    required this.canGenerate,
    required this.urlEncodeContent,
    required this.statusText,
    required this.isError,
    required this.onInputChanged,
    required this.onUrlEncodeChanged,
    required this.onCopyContent,
    required this.onSaveImage,
    required this.onClear,
  });

  final TextEditingController controller;
  final String qrContent;
  final bool canGenerate;
  final bool urlEncodeContent;
  final String? statusText;
  final bool isError;
  final ValueChanged<String> onInputChanged;
  final ValueChanged<bool> onUrlEncodeChanged;
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
                          child: QrImageView(
                            data: qrContent,
                            version: QrVersions.auto,
                            errorCorrectionLevel: QrErrorCorrectLevel.M,
                            size: 240,
                            backgroundColor: Colors.white,
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
