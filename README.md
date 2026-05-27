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
- Lottie 预览
  - 支持选择多个 JSON 文件或拖拽导入
  - 支持多动画叠加预览、选择、反选、清空
  - 支持拖拽调整图层顺序
- IPA 解析
  - 支持选择或拖拽 `.ipa` 文件
  - 自动解压到临时目录并打开输出目录
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

## 项目结构

```text
lib/
  app.dart
  main.dart
  pages/
    encoding_converter_page.dart
    ipa_unpack_page.dart
    json_formatter_page.dart
    lottie_preview_page.dart
    radix_converter_page.dart
    svg_preview_page.dart
    timestamp_converter_page.dart
    tool_shell_page.dart
```

## 后续工具候选

这些工具和当前项目定位比较契合，单个功能边界清晰，适合逐步补充：

1. Hash 计算
   - 可沿着编码转换继续补充 MD5、SHA-1、SHA-256 等摘要输出
   - 适合支持批量输入和一键复制
2. 颜色格式转换
   - 支持 HEX、RGB、ARGB、Flutter `Color(0x...)` 互转
   - 适合移动端 UI 开发场景
3. 图片尺寸 / 文件信息查看
   - 支持拖入图片查看宽高、格式、大小、透明通道
   - 可作为后续压缩、重命名、批量处理的入口
4. Plist / Info.plist 查看器
   - 和 IPA 解析场景强相关
   - 后续可从解包结果里直接读取 Bundle ID、Version、Display Name

推荐优先级：

1. 颜色格式转换工具：适合移动端 UI 开发场景
2. Hash 计算工具：可直接增强编码转换能力
3. IPA 信息查看增强：沿着已有 IPA 解析继续深化，能形成特色

## 本地运行

```bash
flutter pub get
flutter run -d macos
```

## 说明

- 当前仓库默认忽略构建产物、CocoaPods 生成目录以及锁文件
- 如果后续需要稳定依赖版本，可再评估是否纳入 `pubspec.lock` 或 `macos/Podfile.lock`
