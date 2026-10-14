# MyTools 项目协作规则

## macOS 打包与安装

- 用户只说“打包”时，执行 `flutter build macos --release` 生成 macOS `.app`。打包成功后告知产物路径，并询问是否覆盖安装到 `/Applications/mytools.app`；得到明确同意前不要安装。
- 用户在同一请求中明确要求打包并安装时，可直接安装到 `/Applications/mytools.app`；若目标应用正在运行，先正常退出，安装并验证后重新启动。
- 默认不生成 DMG；只有用户明确需要 DMG 时才额外制作。
