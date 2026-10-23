import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tool_catalog.dart';
import 'tool_sidebar.dart';

import '../converters/color_converter_page.dart';
import '../converters/crc_calculator_page.dart';
import '../converters/encoding_converter_page.dart';
import '../converters/hash_calculator_page.dart';
import '../converters/radix_converter_page.dart';
import '../converters/timestamp_converter_page.dart';
import '../generator/random_string_generator_page.dart';
import '../media/image_info_page.dart';
import '../media/media_info_page.dart';
import '../mobile/ipa_app_info.dart';
import '../mobile/ipa_unpack_page.dart';
import '../mobile/mobileprovision_profile_page.dart';
import '../mobile/plist_document_page.dart';
import '../preview/lottie_preview_page.dart';
import '../preview/svg_preview_page.dart';
import '../qr/qr_code_tool_page.dart';
import '../text/json_formatter_page.dart';
import '../text/jwt_decoder_page.dart';
import '../text/regex_tester_page.dart';
import '../text/text_diff_page.dart';

export 'tool_catalog.dart' show ToolItem;

const bool _logToolSelections = bool.fromEnvironment(
  'MYTOOLS_LOG_TOOL_SELECTIONS',
);

class ToolShellPage extends StatefulWidget {
  const ToolShellPage({
    super.key,
    this.initialTool = ToolItem.svgPreview,
    this.initialIpaAppInfo,
  });

  final ToolItem initialTool;
  final IpaAppInfo? initialIpaAppInfo;

  @override
  State<ToolShellPage> createState() => _ToolShellPageState();
}

class _ToolShellPageState extends State<ToolShellPage> {
  final _sidebarKey = GlobalKey<ToolSidebarState>();
  late ToolItem _selectedTool;
  String? _plistInitialPath;
  IpaAppInfo? _profileInitialAppInfo;

  @override
  void initState() {
    super.initState();
    _selectedTool = widget.initialTool;
  }

  void _handleToolSelected(ToolItem tool) {
    _logToolSelected(tool);

    setState(() {
      _selectedTool = tool;
      _plistInitialPath = null;
      _profileInitialAppInfo = null;
    });
  }

  void _logToolSelected(ToolItem tool) {
    if (!_logToolSelections) {
      return;
    }

    final definition = definitionFor(tool);

    debugPrint(
      'lib/pages/shell/tool_shell_page.dart#_ToolShellPageState._handleToolSelected: '
      'opened ${definition.title} -> '
      '${definition.pageFile}#${definition.pageClass}',
    );
  }

  void _handleOpenInfoPlist(String path) {
    setState(() {
      _selectedTool = ToolItem.plistDocument;
      _plistInitialPath = path;
      _profileInitialAppInfo = null;
    });
  }

  void _handleOpenEmbeddedProfile(IpaAppInfo appInfo) {
    setState(() {
      _selectedTool = ToolItem.mobileProvisionProfile;
      _plistInitialPath = null;
      _profileInitialAppInfo = appInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
            _sidebarKey.currentState?.focusSearch(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ToolSidebar(
                    key: _sidebarKey,
                    selectedTool: _selectedTool,
                    onToolSelected: _handleToolSelected,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: DecoratedBox(
                      key: const ValueKey('tool-workspace'),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD8E2E8)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x140F172A),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildDetailPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPage() {
    switch (_selectedTool) {
      case ToolItem.svgPreview:
        return const SvgPreviewPage();
      case ToolItem.radixConverter:
        return const RadixConverterPage();
      case ToolItem.encodingConverter:
        return const EncodingConverterPage();
      case ToolItem.jsonFormatter:
        return const JsonFormatterPage();
      case ToolItem.timestampConverter:
        return const TimestampConverterPage();
      case ToolItem.colorConverter:
        return const ColorConverterPage();
      case ToolItem.hashCalculator:
        return const HashCalculatorPage();
      case ToolItem.crcCalculator:
        return const CrcCalculatorPage();
      case ToolItem.imageInfo:
        return const ImageInfoPage();
      case ToolItem.mediaInfo:
        return const MediaInfoPage();
      case ToolItem.jwtDecoder:
        return const JwtDecoderPage();
      case ToolItem.qrCodeTool:
        return const QrCodeToolPage();
      case ToolItem.mobileProvisionProfile:
        return MobileProvisionProfilePage(
          initialInfo: _profileInitialAppInfo?.embeddedProfileInfo,
          initialPath: _profileInitialAppInfo?.embeddedProfileInfo == null
              ? _profileInitialAppInfo?.embeddedProfilePath
              : null,
        );
      case ToolItem.plistDocument:
        return PlistDocumentPage(initialPath: _plistInitialPath);
      case ToolItem.randomStringGenerator:
        return const RandomStringGeneratorPage();
      case ToolItem.regexTester:
        return const RegexTesterPage();
      case ToolItem.textDiff:
        return const TextDiffPage();
      case ToolItem.lottiePreview:
        return const LottiePreviewPage();
      case ToolItem.ipaUnpack:
        return IpaUnpackPage(
          initialAppInfo: widget.initialIpaAppInfo,
          onOpenInfoPlist: _handleOpenInfoPlist,
          onOpenEmbeddedProfile: _handleOpenEmbeddedProfile,
        );
    }
  }
}
