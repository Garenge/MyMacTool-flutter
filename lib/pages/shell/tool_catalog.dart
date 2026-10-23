import 'package:flutter/material.dart';

enum ToolCategory {
  text('文本与数据'),
  conversion('转换与校验'),
  media('图像与媒体'),
  apple('Apple 开发'),
  generator('生成工具');

  const ToolCategory(this.title);
  final String title;
}

enum ToolItem {
  svgPreview,
  radixConverter,
  encodingConverter,
  jsonFormatter,
  timestampConverter,
  colorConverter,
  hashCalculator,
  crcCalculator,
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

class ToolDefinition {
  const ToolDefinition({
    required this.tool,
    required this.title,
    required this.category,
    required this.keywords,
    required this.icon,
    required this.pageFile,
    required this.pageClass,
  });

  final ToolItem tool;
  final String title;
  final ToolCategory category;
  final String keywords;
  final IconData icon;
  final String pageFile;
  final String pageClass;
}

const List<ToolDefinition> toolDefinitions = [
  ToolDefinition(
    tool: ToolItem.jsonFormatter,
    category: ToolCategory.text,
    keywords: 'json 格式化 压缩',
    title: 'JSON格式化',
    icon: Icons.data_object_rounded,
    pageFile: 'lib/pages/text/json_formatter_page.dart',
    pageClass: 'JsonFormatterPage',
  ),
  ToolDefinition(
    tool: ToolItem.encodingConverter,
    category: ToolCategory.text,
    keywords: 'base64 url unicode utf8 hex 编码',
    title: '编码转换',
    icon: Icons.code_rounded,
    pageFile: 'lib/pages/converters/encoding_converter_page.dart',
    pageClass: 'EncodingConverterPage',
  ),
  ToolDefinition(
    tool: ToolItem.regexTester,
    category: ToolCategory.text,
    keywords: 'regex regexp 正则 替换',
    title: '正则测试',
    icon: Icons.manage_search_rounded,
    pageFile: 'lib/pages/text/regex_tester_page.dart',
    pageClass: 'RegexTesterPage',
  ),
  ToolDefinition(
    tool: ToolItem.textDiff,
    category: ToolCategory.text,
    keywords: 'diff 文本对比 差异',
    title: '文本Diff',
    icon: Icons.difference_rounded,
    pageFile: 'lib/pages/text/text_diff_page.dart',
    pageClass: 'TextDiffPage',
  ),
  ToolDefinition(
    tool: ToolItem.jwtDecoder,
    category: ToolCategory.text,
    keywords: 'jwt token 令牌',
    title: 'JWT解析',
    icon: Icons.key_rounded,
    pageFile: 'lib/pages/text/jwt_decoder_page.dart',
    pageClass: 'JwtDecoderPage',
  ),
  ToolDefinition(
    tool: ToolItem.timestampConverter,
    category: ToolCategory.conversion,
    keywords: 'timestamp unix utc 时间',
    title: '时间戳转换',
    icon: Icons.schedule_rounded,
    pageFile: 'lib/pages/converters/timestamp_converter_page.dart',
    pageClass: 'TimestampConverterPage',
  ),
  ToolDefinition(
    tool: ToolItem.radixConverter,
    category: ToolCategory.conversion,
    keywords: 'binary decimal hex 二进制 十六进制',
    title: '进制换算',
    icon: Icons.calculate_rounded,
    pageFile: 'lib/pages/converters/radix_converter_page.dart',
    pageClass: 'RadixConverterPage',
  ),
  ToolDefinition(
    tool: ToolItem.colorConverter,
    category: ToolCategory.conversion,
    keywords: 'color rgb rgba hex hsl hsv cmyk 颜色',
    title: '颜色转换',
    icon: Icons.palette_rounded,
    pageFile: 'lib/pages/converters/color_converter_page.dart',
    pageClass: 'ColorConverterPage',
  ),
  ToolDefinition(
    tool: ToolItem.hashCalculator,
    category: ToolCategory.conversion,
    keywords: 'hash md5 sha1 sha256 sha512 摘要',
    title: 'Hash计算',
    icon: Icons.tag_rounded,
    pageFile: 'lib/pages/converters/hash_calculator_page.dart',
    pageClass: 'HashCalculatorPage',
  ),
  ToolDefinition(
    tool: ToolItem.crcCalculator,
    category: ToolCategory.conversion,
    keywords: 'crc8 crc16 modbus 校验',
    title: 'CRC校验',
    icon: Icons.fact_check_rounded,
    pageFile: 'lib/pages/converters/crc_calculator_page.dart',
    pageClass: 'CrcCalculatorPage',
  ),
  ToolDefinition(
    tool: ToolItem.svgPreview,
    category: ToolCategory.media,
    keywords: 'svg 矢量',
    title: 'SVG预览',
    icon: Icons.image_search_rounded,
    pageFile: 'lib/pages/preview/svg_preview_page.dart',
    pageClass: 'SvgPreviewPage',
  ),
  ToolDefinition(
    tool: ToolItem.lottiePreview,
    category: ToolCategory.media,
    keywords: 'lottie 动画',
    title: 'Lottie预览',
    icon: Icons.movie_filter_rounded,
    pageFile: 'lib/pages/preview/lottie_preview_page.dart',
    pageClass: 'LottiePreviewPage',
  ),
  ToolDefinition(
    tool: ToolItem.imageInfo,
    category: ToolCategory.media,
    keywords: 'image png jpg gif webp 图片',
    title: '图片信息',
    icon: Icons.photo_size_select_large_rounded,
    pageFile: 'lib/pages/media/image_info_page.dart',
    pageClass: 'ImageInfoPage',
  ),
  ToolDefinition(
    tool: ToolItem.mediaInfo,
    category: ToolCategory.media,
    keywords: 'video audio ffprobe 视频 音频',
    title: '音视频信息',
    icon: Icons.perm_media_rounded,
    pageFile: 'lib/pages/media/media_info_page.dart',
    pageClass: 'MediaInfoPage',
  ),
  ToolDefinition(
    tool: ToolItem.ipaUnpack,
    category: ToolCategory.apple,
    keywords: 'ipa ios app 解包',
    title: 'IPA解析',
    icon: Icons.folder_zip_rounded,
    pageFile: 'lib/pages/mobile/ipa_unpack_page.dart',
    pageClass: 'IpaUnpackPage',
  ),
  ToolDefinition(
    tool: ToolItem.plistDocument,
    category: ToolCategory.apple,
    keywords: 'plist info.plist 配置',
    title: 'Plist查看',
    icon: Icons.account_tree_rounded,
    pageFile: 'lib/pages/mobile/plist_document_page.dart',
    pageClass: 'PlistDocumentPage',
  ),
  ToolDefinition(
    tool: ToolItem.mobileProvisionProfile,
    category: ToolCategory.apple,
    keywords: 'profile mobileprovision provisioning 签名 证书',
    title: 'Profile解析',
    icon: Icons.verified_user_rounded,
    pageFile: 'lib/pages/mobile/mobileprovision_profile_page.dart',
    pageClass: 'MobileProvisionProfilePage',
  ),
  ToolDefinition(
    tool: ToolItem.qrCodeTool,
    category: ToolCategory.generator,
    keywords: 'qr qrcode 二维码 扫码',
    title: '二维码工具',
    icon: Icons.qr_code_2_rounded,
    pageFile: 'lib/pages/qr/qr_code_tool_page.dart',
    pageClass: 'QrCodeToolPage',
  ),
  ToolDefinition(
    tool: ToolItem.randomStringGenerator,
    category: ToolCategory.generator,
    keywords: 'random uuid 随机 字符串',
    title: '随机生成',
    icon: Icons.password_rounded,
    pageFile: 'lib/pages/generator/random_string_generator_page.dart',
    pageClass: 'RandomStringGeneratorPage',
  ),
];

ToolDefinition definitionFor(ToolItem tool) {
  return toolDefinitions.firstWhere((definition) => definition.tool == tool);
}

List<ToolDefinition> matchingTools(ToolCategory category, String query) {
  final terms = query.trim().toLowerCase().split(RegExp(r'\s+'));
  return toolDefinitions.where((definition) {
    final text = '${definition.title} ${definition.keywords}'.toLowerCase();
    return definition.category == category && terms.every(text.contains);
  }).toList();
}
