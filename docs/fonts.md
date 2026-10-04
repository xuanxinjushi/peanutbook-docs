# Cover fonts: current limits and expansion plan

## 问题结论

编辑页（例如 `/11/mortgage-markets-en/edit/`）的 **Title font** 下拉框不是
系统字体浏览器。它显示的是一组固定的、跨平台的“字体风格”选项。当前机器上
`fontconfig` 可以列出 444 个 font family，但下拉框只有 12 个选项（包括默认
项），这是应用层白名单造成的，不是系统字体安装失败。

## 当前实现

字体选择的完整链路如下：

1. `web/coverdesigner/models.py` 中的
   `TITLE_FONT_FAMILY_CHOICES` 定义下拉框选项。值是 `sans`、`slab`、
   `libertine`、`cabin`、`rounded`、`mono`、`impact`、`kai` 和
   `wqy-hei` 等短别名，而不是任意系统 family name。
2. 同一个 choices 列表被多个 `*_font_family` 字段复用，所以 Title、Subtitle、
   Author、背面文字和书脊文字保持一致。新增一个值会同时影响这些字段，而不只是
   Title。
3. `web/coverdesigner/forms.py` 使用模型字段
   自动生成 `<select>`，没有额外的动态字体扫描。
4. `cover/full_cover.py` 将别名映射到
   `cover/fonts.py` 中的字体栈。例如 `slab` 使用
   `Roboto Slab`/`PT Serif`，`mono` 使用 `Source Code Pro`/`Ubuntu Mono`，
   `rounded` 使用 `Comfortaa`/`Ubuntu`。
5. 字体栈按顺序寻找已安装的 family，并通过 `fontconfig` 得到真实文件路径。
   找不到首选字体时会继续回退；这避免了 matplotlib 对未知 family 静默替换为
   DejaVu 字体而导致多个选项实际长得一样。
6. 标题含 CJK 字符时，渲染器会改走 locale/CJK 字体映射，而不是直接使用
   Latin 字体栈。当前可区分的 CJK 变体主要是 Noto Sans CJK 的粗体/细体、
   AR PL UKai（楷体/书法感）、WenQuanYi Zen Hei 和 Noto Sans Mono；很多
   Latin 风格在 CJK 文本下会回到普通 CJK serif。

因此，简单地把 `fc-list` 的结果全部塞进下拉框并不能实现“选择这台机器上的
任意字体”：模型字段长度目前只有 10 个字符，渲染器也没有把任意 family 名称
安全地传递到 Latin/CJK 双路径的机制。

## 这台机器的实际情况

在 2026-10-03 检查到：

```text
fontconfig 可见的 family 数：444
```

其中已经被当前 cover 语义选项有效覆盖的代表字体包括：

| 语义选项 | 主要字体栈 | 当前机器是否可解析 |
|---|---|---|
| 默认 serif | EB Garamond, Liberation Serif, Noto Serif, DejaVu Serif | 是 |
| sans | Arial, Liberation Sans, Open Sans, DejaVu Sans | 是 |
| sans-bold | Arial Black, Open Sans Extrabold, DejaVu Sans | 是 |
| sans-light | Open Sans Light, DejaVu Sans | 是 |
| slab | Roboto Slab, PT Serif, DejaVu Serif | 是 |
| literary serif | Linux Libertine O, EB Garamond, Liberation Serif | 是 |
| geometric sans | Cabin, Ubuntu, DejaVu Sans | 是 |
| rounded | Comfortaa, Ubuntu, DejaVu Sans | 是 |
| monospace | Source Code Pro, Ubuntu Mono, DejaVu Sans Mono | 是 |
| bold display | Impact, Arial Black, DejaVu Sans | 是 |

仍有大量未直接暴露的 family，例如 Comic Neue、Cantarell、Inter、Lato、
Lobster Two、GFS Didot、Georgia、Charis SIL、Gentium、JetBrains Mono，以及
大量 Noto 的语言脚本字体和 TeX 数学字体。它们“安装了”不等于都适合作为
书名字体：有些只覆盖特定脚本，有些是数学/符号字体，有些只有单一字重或
不完整的字形覆盖。

## 为什么目前不直接暴露全部字体

### 1. 下拉值和数据库设计是固定的

`CoverDesign` 对字体选项使用 Django `choices`。数据库保存的是短别名，而不是
fontconfig 的显示名称。任意 family 名称可能超过当前字段长度，也可能包含
逗号、样式后缀或同名变体；直接扩大 choices 还会要求迁移和验证旧设计的兼容性。

### 2. “family”不等于一个可用的字体文件

一个 family 可能有 Regular、Light、Bold、Italic、Condensed 等多个 face，也可能
是 `.ttc` 集合。PIL 最终需要一个可加载的真实文件和字号，而不是仅仅一个显示
名称。当前代码专门处理了 fontconfig 解析和 TTC face 提取；任意字体选择需要
继续定义“选普通 face 还是粗体 face”，否则预览结果不可预测。

### 3. Latin 和 CJK 的字体路径不同

标题只要混入一个 CJK 字符，就会切换到 CJK 字体路径。很多漂亮的 Latin 字体
没有中文、日文或繁中字形；反过来，CJK 字体也未必适合英文标题。若把 444 个
family 原样展示，用户选中的字体可能只对英文生效，中文却静默回退到另一张
字体，造成“选项名称”和实际效果不一致。

### 4. 渲染必须可复现

封面预览和最终封面都依赖 PIL/fontconfig。若保存的是“本机 family 名称”，在
Docker、另一台构建机或批量构建环境中可能解析到不同字体，甚至退回 DejaVu，
导致换行、标题宽度和封面布局变化。书籍构建还需要考虑字体嵌入和字体授权。

### 5. 选项太多会放大维护和测试成本

字体会影响标题宽度、自动换行、字号、字重、CJK fallback、正反面和书脊。
每增加一个选项，至少要验证纯 Latin、混合 Latin/CJK、不同语言和缺字回退；
把系统字体清单直接变成 UI 还会使系统升级后选项数量和行为随时变化。

## 建议的扩展顺序

建议不要把 `fc-list` 全量结果直接放进 Title font 下拉框，而是分两层：

1. **短期：动态读取系统字体。**  
   从本机已经安装并能被 `fontconfig`/Pillow 加载的字体中生成列表，不下载字体；
   过滤 emoji、数学字体、特殊脚本和不可加载文件，并保留现有语义选项。
2. **中期：增加 Custom system font。**  
   保存用户选择的系统 family，保存前验证可解析，预览时显示实际解析到的文件，
   同时明确 CJK fallback 和字体失效提示。
3. **长期：项目级字体资产。**  
   如果未来需要跨机器可复现，再允许项目携带已授权的 `.ttf`/`.otf` 文件；这
   不是当前需求，也不意味着从 PyPI 自动下载。

具体执行步骤、数据迁移、CJK fallback、测试和分阶段任务见
[系统字体选择实施计划](fonts-plan.md)。
