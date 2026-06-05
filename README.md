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
  - 支持 HEX、ARGB HEX、RGBA HEX、RGB、RGBA、HSL、HSV、CMYK、Flutter `Color(0x...)` 互转
  - 支持从 `rgba(...)` 或 CSS `#RRGGBBAA` 反推 RGB HEX、ARGB HEX 和 RGBA HEX
  - 支持用 Flutter `Color(0xAARRGGBB)` 明确输入 ARGB 颜色
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
- 二维码工具
  - 支持输入字符串生成二维码，可选择生成前 URL 编码
  - 支持配置纠错等级、导出尺寸、前景色和背景色
  - 支持粘贴、选择或拖拽图片解析二维码内容
  - 支持复制解析结果、复制 URL 编码结果，并在解析内容为 URL 时直接打开
- Provisioning Profile 解析
  - 支持选择或拖拽 `.mobileprovision` / `.provisionprofile` 文件
  - 支持展示 Profile 名称、UUID、Team ID、Bundle ID、平台、创建和过期时间
  - 支持展示 Entitlements、开发证书摘要、设备 UDID 列表和过期状态
  - 支持复制 Bundle ID 和 Profile 摘要
- Plist 查看
  - 支持选择或拖拽 XML plist / binary plist 文件
  - 支持将 plist 格式化为树形节点，展示 key、path、类型和值
  - 支持搜索 key、path 或 value，复制 plist 路径和 XML 内容
- 随机生成
  - 支持批量生成 UUID v4
  - 支持按长度批量生成随机字符串，可选择小写、大写、数字、符号
  - 支持复制单项结果和全部结果
- 正则测试
  - 支持输入正则表达式、测试文本和替换文本
  - 支持区分大小写、多行、DotAll、Unicode 开关
  - 支持展示全局匹配结果、捕获分组和替换预览
- 文本 Diff
  - 支持输入左右两段文本并进行行级对比
  - 支持展示相同、新增、删除行及左右行号
  - 支持复制 Diff 结果
- Lottie 预览
  - 支持选择多个 JSON 文件或拖拽导入
  - 支持多动画叠加预览、选择、反选、清空
  - 支持拖拽调整图层顺序
- IPA 解析
  - 支持选择或拖拽 `.ipa` 文件
  - 自动解压到临时目录并打开输出目录
  - 支持读取 Info.plist 中的 App 名称、Bundle ID、版本号等信息
  - 支持定位解包后的 Info.plist 和 embedded.mobileprovision
  - 支持读取 embedded.mobileprovision，展示 Profile 类型、Team ID、Bundle ID 匹配状态、设备和证书数量
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
- `qr_flutter`：二维码生成
- `pasteboard`：剪贴板图片读取
- `zxing2`：二维码图片解析
- `xml`：plist / mobileprovision XML 解析

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
    mobileprovision_profile_info.dart
    mobileprovision_profile_page.dart
    plist_document_info.dart
    plist_document_page.dart
    qr_code_tool_page.dart
    radix_converter_page.dart
    random_string_generator_page.dart
    regex_tester_page.dart
    svg_preview_page.dart
    text_diff_page.dart
    timestamp_converter_page.dart
    color_converter_page.dart
    tool_shell_page.dart
```

## 后续路线图

这些任务按“最能增强当前工具箱气质”和“实现后能复用能力”的顺序排列。已经实现的工具能力不再放入候选区，只在当前功能中维护。

### P0：移动端排查能力

1. IPA 与 Profile / Plist 联动
   - 支持从 IPA 解析页面直接打开 Info.plist 的 Plist 查看器视图
   - 支持从 IPA 解析页面直接打开 embedded.mobileprovision 的 Profile 解析视图
   - 展示更完整的签名证书主体、有效期和权限差异提示

### P1：开发日常高频工具

当前 P1 候选已实现，后续可根据使用频率补充新的轻量工具。

### P2：现有工具增强

1. 颜色转换增强
   - 增加设计标注常用格式复制模板
2. 二维码工具增强
   - 支持更多码点样式和 Logo 嵌入
3. 解析类工具体验增强
   - 给 IPA、Profile、图片信息等工具补充最近记录
   - 统一复制摘要、复制路径、清空结果等操作反馈

### P3：工程维护

1. 抽取通用文件导入组件
   - 将选择文件、拖拽文件、错误提示、复制结果等重复逻辑沉淀为共享组件
   - 优先服务 IPA、图片信息、Lottie、二维码、后续 plist/mobileprovision 页面
2. 拆分巨型页面
   - `svg_preview_page.dart`、`qr_code_tool_page.dart`、`ipa_unpack_page.dart`、`lottie_preview_page.dart` 已接近或超过 900 行
   - 后续修改相关页面时，优先拆出 parser、model、result view、toolbar 等私有模块
3. 拓展测试覆盖
   - 为解析类工具补充纯 Dart parser 单元测试
   - 为拖拽、粘贴、复制等桌面交互保留关键 widget 测试

## 本地运行

```bash
flutter pub get
flutter run -d macos
```

## 说明

- 当前仓库默认忽略构建产物、CocoaPods 生成目录以及锁文件
- 如果后续需要稳定依赖版本，可再评估是否纳入 `pubspec.lock` 或 `macos/Podfile.lock`
