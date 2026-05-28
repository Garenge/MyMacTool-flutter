# MyTools

MyTools 是一个基于 Flutter 的桌面工具集合项目，目前主要面向 macOS 使用场景。

## 项目定位

MyTools 适合承载日常开发、设计协作、移动端包体排查相关的小工具。当前应用采用左侧工具导航 + 右侧工作区的结构，适合继续按独立页面追加功能。

## 当前功能

- SVG 预览
  - 支持手动输入、打开文件、拖拽导入、剪贴板粘贴
  - 支持即时渲染、缩放预览、另存为 SVG、浏览器打开
  - 支持最近记录恢复
- 进制换算
  - 支持十六进制、十进制无符号、十进制有符号、二进制互转
  - 支持自动忽略空格、逗号、下划线等分隔符
  - 支持按字节、位宽、千分位格式化输出
- 编码转换
  - 支持普通文本、URL 编码、Unicode 转义、UTF-8 十六进制、Base64 互转
  - 支持从任意一侧输入并选择来源格式转换到另一侧
  - 支持 URL `%xx`、Unicode `\u4E2D` / `\u{1F600}`、Hex 字节分组输入
- JSON 格式化
  - 支持 JSON 格式化、压缩、校验
  - 支持 2 / 4 空格缩进和 key 排序
  - 支持复制结果、结果转输入、解析错误行列提示
- 时间戳转换
  - 支持秒 / 毫秒时间戳、本地时间、UTC 时间、ISO 时间互转
  - 支持当前时间快捷填充
  - 支持单项结果复制
- 颜色转换
  - 支持 HEX、ARGB HEX、RGB、RGBA、Flutter `Color(0x...)` 互转
  - 支持颜色预览、通道值展示、单项结果复制
- Hash 计算
  - 支持对文本计算 MD5、SHA-1、SHA-256、SHA-512 摘要
  - 支持单项结果复制
- 图片信息
  - 支持选择或拖拽图片查看宽高、格式、文件大小、帧数
  - 支持透明通道和透明像素判断、复制图片路径
- JWT 解析
  - 支持 Header / Payload 解码和 JSON 格式化展示
  - 支持 exp、iat、nbf 本地时间转换和过期状态提示
- Lottie 预览
  - 支持选择多个 JSON 文件或拖拽导入
  - 支持多动画叠加预览、选择、反选、清空
  - 支持拖拽调整图层顺序
- IPA 解析
  - 支持选择或拖拽 `.ipa` 文件
  - 自动解压到临时目录并打开输出目录
  - 支持读取 Info.plist 中的 App 名称、Bundle ID、版本号等信息
  - 支持解析记录、复制输出路径、重新打开目录

## 技术栈

- Flutter
- Dart
- macOS desktop
- `desktop_drop`：桌面拖拽导入
- `file_selector`：文件选择与保存
- `flutter_svg`：SVG 渲染
- `lottie`：Lottie 动画预览
- `archive`：IPA ZIP 解包
- `crypto`：Hash 摘要计算
- `image`：图片信息解析

## 项目结构

```text
lib/
  app.dart
  main.dart
  pages/
    encoding_converter_page.dart
    hash_calculator_page.dart
    image_file_info.dart
    image_info_page.dart
    ipa_app_info.dart
    ipa_unpack_page.dart
    json_formatter_page.dart
    jwt_decoder_page.dart
    lottie_preview_page.dart
    radix_converter_page.dart
    svg_preview_page.dart
    timestamp_converter_page.dart
    color_converter_page.dart
    tool_shell_page.dart
```

## 后续工具候选

这些工具和当前项目定位比较契合，单个功能边界清晰，适合逐步补充：

1. Plist / Info.plist 查看器
   - 和 IPA 解析场景强相关
   - 后续可从解包结果里直接读取 Bundle ID、Version、Display Name
2. URL Query 格式化工具
   - 支持参数解析、排序、复制单项参数和重新组装 URL
3. UUID / 随机字符串生成器
   - 支持 UUID v4、指定长度随机串和批量生成

推荐优先级：

1. URL Query 格式化工具：可和编码转换能力互补
2. Plist / Info.plist 查看器：延续 IPA 解析能力，强化 iOS 工具特色
3. UUID / 随机字符串生成器：实现轻量，适合日常调试

## 本地运行

```bash
flutter pub get
flutter run -d macos
```

## 说明

- 当前仓库默认忽略构建产物、CocoaPods 生成目录以及锁文件
- 如果后续需要稳定依赖版本，可再评估是否纳入 `pubspec.lock` 或 `macos/Podfile.lock`
