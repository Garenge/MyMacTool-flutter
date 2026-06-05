import 'package:flutter/material.dart';

import 'color_converter_page.dart';
import 'encoding_converter_page.dart';
import 'hash_calculator_page.dart';
import 'image_info_page.dart';
import 'ipa_unpack_page.dart';
import 'json_formatter_page.dart';
import 'jwt_decoder_page.dart';
import 'lottie_preview_page.dart';
import 'mobileprovision_profile_page.dart';
import 'qr_code_tool_page.dart';
import 'radix_converter_page.dart';
import 'svg_preview_page.dart';
import 'timestamp_converter_page.dart';

enum ToolItem {
  svgPreview,
  radixConverter,
  encodingConverter,
  jsonFormatter,
  timestampConverter,
  colorConverter,
  hashCalculator,
  imageInfo,
  jwtDecoder,
  qrCodeTool,
  mobileProvisionProfile,
  lottiePreview,
  ipaUnpack,
}

class _ToolDefinition {
  const _ToolDefinition({
    required this.tool,
    required this.title,
    required this.icon,
  });

  final ToolItem tool;
  final String title;
  final IconData icon;
}

const List<_ToolDefinition> _toolDefinitions = [
  _ToolDefinition(
    tool: ToolItem.svgPreview,
    title: 'SVG预览',
    icon: Icons.image_search_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.radixConverter,
    title: '进制换算',
    icon: Icons.calculate_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.encodingConverter,
    title: '编码转换',
    icon: Icons.code_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.jsonFormatter,
    title: 'JSON格式化',
    icon: Icons.data_object_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.timestampConverter,
    title: '时间戳转换',
    icon: Icons.schedule_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.colorConverter,
    title: '颜色转换',
    icon: Icons.palette_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.hashCalculator,
    title: 'Hash计算',
    icon: Icons.tag_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.imageInfo,
    title: '图片信息',
    icon: Icons.photo_size_select_large_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.jwtDecoder,
    title: 'JWT解析',
    icon: Icons.key_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.qrCodeTool,
    title: '二维码工具',
    icon: Icons.qr_code_2_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.mobileProvisionProfile,
    title: 'Profile解析',
    icon: Icons.verified_user_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.lottiePreview,
    title: 'Lottie预览',
    icon: Icons.movie_filter_rounded,
  ),
  _ToolDefinition(
    tool: ToolItem.ipaUnpack,
    title: 'IPA解析',
    icon: Icons.folder_zip_rounded,
  ),
];

class ToolShellPage extends StatefulWidget {
  const ToolShellPage({super.key});

  @override
  State<ToolShellPage> createState() => _ToolShellPageState();
}

class _ToolShellPageState extends State<ToolShellPage> {
  ToolItem _selectedTool = ToolItem.svgPreview;

  void _handleToolSelected(ToolItem tool) {
    setState(() {
      _selectedTool = tool;
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
      case ToolItem.jwtDecoder:
        return const JwtDecoderPage();
      case ToolItem.qrCodeTool:
        return const QrCodeToolPage();
      case ToolItem.mobileProvisionProfile:
        return const MobileProvisionProfilePage();
      case ToolItem.lottiePreview:
        return const LottiePreviewPage();
      case ToolItem.ipaUnpack:
        return const IpaUnpackPage();
    }
  }
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
