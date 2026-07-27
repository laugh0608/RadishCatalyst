# UI Fonts

`NotoSansSC-wght.ttf` 是工程统一使用的简体中文 UI 字体。

- 字体族：Noto Sans SC
- 来源：`google/fonts/ofl/notosanssc/NotoSansSC[wght].ttf`
- 上游源码提交：`523d033d6cb47f4a80c58a35753646f5c3608a78`
- SHA-256：`a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da`
- 许可证：SIL Open Font License 1.1，见 `OFL.txt`

工程直接携带字体，不使用 `SystemFont`，以确保 headless 检查、CI、macOS
和 Windows 使用相同的中文字形。
