import 'package:flutter/material.dart';

import '../converters/color_converter_page.dart';
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

const bool _logToolSelections = bool.fromEnvironment(
  'MYTOOLS_LOG_TOOL_SELECTIONS',
);

enum ToolItem {
  svgPreview,
  radixConverter,
  encodingConverter,
  jsonFormatter,
  timestampConverter,
  colorConverter,
  hashCalculator,
  imageInfo,
  mediaInfo,
  jwtDecoder,
  qrCodeTool,
  mobileProvisionProfile,
  plistDocument,
  randomStringGenerator,
  regexTester,
  textDiff,
  lottiePreview,
  ipaUnpack,
}

class _ToolDefinition {
  const _ToolDefinition({
    required this.tool,
    required this.title,
    required this.icon,
    required this.pageFile,
    required this.pageClass,
  });

  final ToolItem tool;
  final String title;
  final IconData icon;
  final String pageFile;
  final String pageClass;
}

const List<_ToolDefinition> _toolDefinitions = [
  _ToolDefinition(
    tool: ToolItem.svgPreview,
    title: 'SVG预览',
    icon: Icons.image_search_rounded,
    pageFile: 'lib/pages/preview/svg_preview_page.dart',
    pageClass: 'SvgPreviewPage',
  ),
  _ToolDefinition(
    tool: ToolItem.radixConverter,
    title: '进制换算',
    icon: Icons.calculate_rounded,
    pageFile: 'lib/pages/converters/radix_converter_page.dart',
    pageClass: 'RadixConverterPage',
  ),
  _ToolDefinition(
    tool: ToolItem.encodingConverter,
    title: '编码转换',
    icon: Icons.code_rounded,
    pageFile: 'lib/pages/converters/encoding_converter_page.dart',
    pageClass: 'EncodingConverterPage',
  ),
  _ToolDefinition(
    tool: ToolItem.jsonFormatter,
    title: 'JSON格式化',
    icon: Icons.data_object_rounded,
    pageFile: 'lib/pages/text/json_formatter_page.dart',
    pageClass: 'JsonFormatterPage',
  ),
  _ToolDefinition(
    tool: ToolItem.timestampConverter,
    title: '时间戳转换',
    icon: Icons.schedule_rounded,
    pageFile: 'lib/pages/converters/timestamp_converter_page.dart',
    pageClass: 'TimestampConverterPage',
  ),
  _ToolDefinition(
    tool: ToolItem.colorConverter,
    title: '颜色转换',
    icon: Icons.palette_rounded,
    pageFile: 'lib/pages/converters/color_converter_page.dart',
    pageClass: 'ColorConverterPage',
  ),
  _ToolDefinition(
    tool: ToolItem.hashCalculator,
    title: 'Hash计算',
    icon: Icons.tag_rounded,
    pageFile: 'lib/pages/converters/hash_calculator_page.dart',
    pageClass: 'HashCalculatorPage',
  ),
  _ToolDefinition(
    tool: ToolItem.imageInfo,
    title: '图片信息',
    icon: Icons.photo_size_select_large_rounded,
    pageFile: 'lib/pages/media/image_info_page.dart',
    pageClass: 'ImageInfoPage',
  ),
  _ToolDefinition(
    tool: ToolItem.mediaInfo,
    title: '音视频信息',
    icon: Icons.perm_media_rounded,
    pageFile: 'lib/pages/media/media_info_page.dart',
    pageClass: 'MediaInfoPage',
  ),
  _ToolDefinition(
    tool: ToolItem.jwtDecoder,
    title: 'JWT解析',
    icon: Icons.key_rounded,
    pageFile: 'lib/pages/text/jwt_decoder_page.dart',
    pageClass: 'JwtDecoderPage',
  ),
  _ToolDefinition(
    tool: ToolItem.qrCodeTool,
    title: '二维码工具',
    icon: Icons.qr_code_2_rounded,
    pageFile: 'lib/pages/qr/qr_code_tool_page.dart',
    pageClass: 'QrCodeToolPage',
  ),
  _ToolDefinition(
    tool: ToolItem.mobileProvisionProfile,
    title: 'Profile解析',
    icon: Icons.verified_user_rounded,
    pageFile: 'lib/pages/mobile/mobileprovision_profile_page.dart',
    pageClass: 'MobileProvisionProfilePage',
  ),
  _ToolDefinition(
    tool: ToolItem.plistDocument,
    title: 'Plist查看',
    icon: Icons.account_tree_rounded,
    pageFile: 'lib/pages/mobile/plist_document_page.dart',
    pageClass: 'PlistDocumentPage',
  ),
  _ToolDefinition(
    tool: ToolItem.randomStringGenerator,
    title: '随机生成',
    icon: Icons.password_rounded,
    pageFile: 'lib/pages/generator/random_string_generator_page.dart',
    pageClass: 'RandomStringGeneratorPage',
  ),
  _ToolDefinition(
    tool: ToolItem.regexTester,
    title: '正则测试',
    icon: Icons.manage_search_rounded,
    pageFile: 'lib/pages/text/regex_tester_page.dart',
    pageClass: 'RegexTesterPage',
  ),
  _ToolDefinition(
    tool: ToolItem.textDiff,
    title: '文本Diff',
    icon: Icons.difference_rounded,
    pageFile: 'lib/pages/text/text_diff_page.dart',
    pageClass: 'TextDiffPage',
  ),
  _ToolDefinition(
    tool: ToolItem.lottiePreview,
    title: 'Lottie预览',
    icon: Icons.movie_filter_rounded,
    pageFile: 'lib/pages/preview/lottie_preview_page.dart',
    pageClass: 'LottiePreviewPage',
  ),
  _ToolDefinition(
    tool: ToolItem.ipaUnpack,
    title: 'IPA解析',
    icon: Icons.folder_zip_rounded,
    pageFile: 'lib/pages/mobile/ipa_unpack_page.dart',
    pageClass: 'IpaUnpackPage',
  ),
];

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

    final definition = _definitionFor(tool);

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _ToolSidebar(
                selectedTool: _selectedTool,
                onToolSelected: _handleToolSelected,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: DecoratedBox(
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

_ToolDefinition _definitionFor(ToolItem tool) {
  return _toolDefinitions.firstWhere(
    (_ToolDefinition definition) => definition.tool == tool,
  );
}

class _ToolSidebar extends StatelessWidget {
  const _ToolSidebar({
    required this.selectedTool,
    required this.onToolSelected,
  });

  final ToolItem selectedTool;
  final ValueChanged<ToolItem> onToolSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11212D),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListView.separated(
        itemCount: _toolDefinitions.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int index) {
          final tool = _toolDefinitions[index];

          return _ToolSidebarItem(
            title: tool.title,
            icon: tool.icon,
            selected: selectedTool == tool.tool,
            onTap: () => onToolSelected(tool.tool),
          );
        },
      ),
    );
  }
}

class _ToolSidebarItem extends StatelessWidget {
  const _ToolSidebarItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected
        ? const Color(0xFF11212D)
        : const Color(0xFFE5EDF3);
    final backgroundColor = selected
        ? const Color(0xFFEAF7F6)
        : const Color(0xFF1A2E3B);

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: foregroundColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
