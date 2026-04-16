# MyTools

MyTools 是一个基于 Flutter 的桌面工具集合项目，目前主要面向 macOS 使用场景。

## 当前功能

- SVG 预览：支持手动输入 SVG 内容并即时预览
- 文件导入：支持打开本地文本/SVG/XML/JSON 等文件进行预览
- 拖拽导入：支持将文件直接拖入窗口导入
- 剪贴板粘贴：支持从剪贴板快速导入 SVG 内容
- 历史记录：支持恢复最近导入或生成的内容

## 技术栈

- Flutter
- Dart
- macOS desktop

## 项目结构

```text
lib/
  app.dart
  main.dart
  pages/
    svg_preview_page.dart
    tool_shell_page.dart
```

## 本地运行

```bash
flutter pub get
flutter run -d macos
```

## 说明

- 当前仓库默认忽略构建产物、CocoaPods 生成目录以及锁文件
- 如果后续需要稳定依赖版本，可再评估是否纳入 `pubspec.lock` 或 `macos/Podfile.lock`
