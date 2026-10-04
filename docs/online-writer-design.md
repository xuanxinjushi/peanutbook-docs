# 在线写作（Writer）设计文档

状态：**已删除**（2026-09-28），由 [online-book-folder-design.md](online-book-folder-design.md)（书架上的整本书）取代 · 原位置：`web/writer/`

> 单篇稿件后来被删掉了，因为章节应该属于某一本书。本文档保留下来作为历史记录。
> 其中仍然有效的部分：LaTeX/Typst 错误提取（现在在 `writer/diagnostics.py`）、`PEANUTBOOK_KEEP_LATEX_LOG`，
> 以及渲染时用进程组超时的做法（现在在 `writer/jobs.py`）。

## 1. 目标

在现有的 Cover Designer（`web/`，本地 Django 工具）里加一个在线写作功能：

- 左边是 Markdown 编辑区，右边是 PDF 预览区，中间的分隔条可以拖动。
- 点击 **Render**（或按 `Ctrl/⌘+Enter`）会保存稿件，用 peanutbook 本身的章节流水线（`bubble.convert`）生成 PDF，
  然后在右侧刷新显示。
- 稿件保存在 SQLite 里，可以有多篇，并且可以列出、新建、删除，也可以把 Markdown 或 PDF 下载下来。

### 不做（v1）

- 多用户、登录、协作编辑：和 coverdesigner 一样，这是单机开发工具。
- 整本书构建（多章节、目录、封面合成）。v1 只处理单章，相当于 `bubble-convert <chapter.md>`。
- 图片上传：Markdown 里引用的外部图片不会被带进构建目录，放在第 9 节的后续工作里。
- 后台任务队列（Celery 等）：渲染是同步的。LaTeX 单章大约 5–9 秒，Typst 不到 1 秒，可以接受。

## 2. 总体结构

```
web/
  webproject/settings.py   INSTALLED_APPS += "writer"
  webproject/urls.py       path("write/", include("writer.urls"))
  writer/                  新 Django app
    models.py              Manuscript 模型
    forms.py               ManuscriptForm（设置 + 正文）
    rendering.py           Manuscript -> 临时 peanutbook 项目 -> 子进程 bubble.convert -> PDF
    views.py               列表/新建/编辑/保存/渲染/PDF/下载/删除
    urls.py
    templates/writer/      继承 coverdesigner/base.html，保持同一套主题和顶栏
    tests.py               单元测试 + 集成测试
```

之所以新建一个 app 而不是塞进 coverdesigner：两者的模型、渲染后端都没有交集，唯一共享的是页面外观，
而 `{% extends "coverdesigner/base.html" %}` 就能拿到。顶栏加一个 “✍️ Write” 链接，两个工具可以互相切换。

## 3. 数据模型

`Manuscript`

| 字段 | 类型 | 说明 |
|---|---|---|
| `title` | Char(200) | 稿件名，列表显示用；同时写进 `peanut.config` 的 `book_title`（页眉用） |
| `author` | Char(200)，可空 | 写进 `peanut.config` 的 `author` |
| `lang` | Char，choices 取自 `bubble.locales.VALID_LANGS` | 决定 CJK 字体、`第N章` 等本地化 |
| `engine` | `latex` / `typst` | latex 是正式排版；typst 是快速预览 |
| `chapter_style` | `circle` / `square` / `none` | 章首装饰 |
| `template` | 页面尺寸模板，可空（空表示使用默认 `amazon_7x10.tpl`） | choices 取自仓库 `templates/*.tpl` |
| `body` | Text | Markdown 正文（表单里设置了 `strip=False`：缩进代码块和结尾换行都是有意义的） |
| `pdf` | FileField(`writer/pdf/`) | 最近一次成功渲染的 PDF |
| `render_log` | Text | 最近一次渲染的日志尾部（失败时给用户看） |
| `render_ok` | Bool，可空 | 最近一次渲染是否成功；从未渲染时为 `None` |
| `rendered_at` | DateTime，可空 | |
| `created_at` / `updated_at` | DateTime | |

新建稿件时带一段示例正文（`# Chapter 1: Untitled` + 几段演示标题、公式、代码块的内容），
这样用户第一次点 Render 就能看到完整效果。

## 4. 渲染流程（`writer/rendering.py`）

```
render_manuscript(m) -> RenderResult(ok, pdf_bytes, log, errors)
```

1. `tempfile.TemporaryDirectory()` 建一个一次性的 peanutbook 项目：
   ```
   <tmp>/peanut.config          JSON：lang, book_title, author, chapter_style, template
   <tmp>/chapter1/chapter1.md   稿件正文
   ```
   每次渲染用自己的临时目录，所以并发渲染（开发服务器是多线程的）互不干扰；目录用完就删掉，
   不会在 `media/` 里堆积 `.build/` 中间文件。
2. 用**子进程**跑 `sys.executable -m bubble.convert chapter1/chapter1.md --lang L --style S --engine E [--template T]`，`cwd=<tmp>`。
   这里不在进程内直接调 `Converter`，原因有三个：
   - `bubble.convert` 靠 `cwd` 找项目根目录（`find_project_root`），在 Django 进程里 `chdir` 不是线程安全的；
   - `Converter._setup_logging` 调用的是 `logging.basicConfig`，会改全局 logging，而且日志写到 stdout。放到子进程里，
     stdout 可以完整捕获下来作为渲染日志；
   - 可以设一个总超时（`WRITER_RENDER_TIMEOUT`，默认 180 秒）。子进程用 `start_new_session=True` 启动；
     超时时用 `os.killpg` 杀掉整个进程组（包括 pandoc 和 lualatex 这些孙进程），不会把请求线程挂死。
3. 判断结果：返回码是 0 **并且** `chapter1/chapter1.pdf` 存在，才算成功。读出 PDF 的字节。
4. 收集错误：宽松（dev）模式下，LaTeX 报错时往往仍然能出 PDF（日志里写的是 “Compiled with warnings”）。
   这时从 `<tmp>/.build/**/chapter1.log` 里提取以 `!` 开头的 LaTeX 错误行，以及其后的 `l.<行号>` 上下文，
   放进 `errors`，前端会以黄色警告的形式显示出来。
   `Converter.compile_latex` 原本在构建成功后会删掉 `.log`，所以给 `convert.py` 加了一个可选的环境变量
   `PEANUTBOOK_KEEP_LATEX_LOG=1`（渲染子进程会设置它）：设置后保留 `.log`，不设置时行为不变。
   Typst 引擎则从 bubble.convert 的输出里提取 `error:` / `warning:` 诊断（`extract_typst_errors`），
   每条附上出错的源码片段和位置，例如 `error: unknown variable: foo · #foo() (chapter1.typ:3:1)`。
   注意位置指向 pandoc 生成的 `.typ` 中间文件，不是用户的 Markdown，所以源码片段放在前面。
5. 日志只保留尾部 `LOG_TAIL_CHARS`（20k 字符），避免数据库字段过大。

视图层拿到 `RenderResult` 后：
- 成功：把 `pdf_bytes` 存进 `m.pdf`（先删掉旧文件，所以同一篇稿件在磁盘上始终只有一份 PDF），
  并设置 `render_ok=True` 和 `rendered_at`；
- 失败：**保留上一份 PDF**（右侧仍然显示上次成功的结果），设置 `render_ok=False`，把日志交给前端。

## 5. HTTP 接口（`/write/` 前缀，`app_name="writer"`）

| URL | 方法 | 作用 |
|---|---|---|
| `/write/` | GET | 稿件列表 |
| `/write/new/` | POST | 新建一篇带示例正文的稿件，302 到编辑页（GET 也允许，方便从链接直接进） |
| `/write/<pk>/` | GET | 编辑器页面（左写右看） |
| `/write/<pk>/save/` | POST（AJAX） | 保存表单，返回 `{ok, updated_at}`；校验失败返回 400 和 `{ok:false, errors}` |
| `/write/<pk>/render/` | POST（AJAX） | 保存后渲染，返回 `{ok, pdf_url, errors, log, rendered_at}`；渲染失败时 HTTP 仍返回 200，由 `ok:false` 表示失败，表单校验失败才返回 400 |
| `/write/<pk>/pdf/` | GET | 以 `inline` 方式返回 PDF，用于 iframe 预览；加 `?download=1` 时改为 `attachment` |
| `/write/<pk>/markdown/` | GET | 下载 `.md` |
| `/write/<pk>/delete/` | GET 确认 / POST 删除 | 同时删除磁盘上的 PDF |

要点：
- **iframe 与 X-Frame-Options**：项目开启了 `XFrameOptionsMiddleware`，默认值 `DENY` 会让右侧 iframe 显示空白。
  因此 `/pdf/` 视图加了 `@xframe_options_sameorigin`，这一点由测试覆盖。
- 预览 URL 带 `?v=<rendered_at 时间戳>`，避免浏览器缓存旧 PDF。另外 PDF 响应头设了 `Cache-Control: no-store`。
- 所有写操作都是 POST，并带 CSRF token。前端从 cookie 或者模板里的 `{% csrf_token %}` 取 token。

## 6. 前端（`templates/writer/editor.html`）

- 布局沿用 coverdesigner 的 `body.fullbleed` 和 `.designer-layout` 两栏，以及可拖动的分隔条，宽度比例存在 `localStorage`。
- 左栏：
  - 顶部是一行紧凑的设置（标题、语言、引擎、章首样式、页面模板），可以折叠；
  - 下面是占满剩余高度的等宽 `<textarea>`。不引入 CodeMirror 等 CDN 依赖，这是离线本地工具，
    textarea 加少量增强就够用；
  - 增强：`Tab` 插入 4 个空格，`Shift+Tab` 反缩进，`Ctrl/⌘+S` 保存，`Ctrl/⌘+Enter` 渲染；
  - 状态行显示 “未保存 / 已保存 hh:mm:ss / 渲染中… / 渲染成功 (x.x s) / 渲染失败”，以及字数统计
    （中文按字、英文按词）；
  - 有未保存的修改时，`beforeunload` 会提示；
  - 草稿防丢：输入停止 1.5 秒后自动 `save`（只保存，不渲染）。
- 右栏：
  - 有 PDF 时用 `<iframe>` 显示，也就是浏览器自带的 PDF 阅读器，支持缩放、翻页和搜索；
  - 没有 PDF 时显示空状态提示 “点 Render 生成 PDF”；
  - 渲染失败或有 LaTeX 警告时，iframe 上方显示错误框，日志可以展开查看；
  - 工具条：Render、下载 PDF、下载 .md。
- Render 期间按钮禁用，避免重复提交；如果渲染时又有新的输入，渲染结束后状态回到 “未保存”。

## 7. 测试计划

测试放在 `web/writer/tests.py`，用 `cd web && python manage.py test writer` 运行（`usao` 环境）。

**单元测试**（不需要 pandoc 或 LaTeX，子进程用 mock 替代）：
- `build_project()`：临时目录里 `peanut.config` 的 JSON 内容正确（lang、title、author、template、style），正文写到了 `chapter1/chapter1.md`；
- `build_command()`：参数里包含 `-m bubble.convert`、`--lang`、`--engine`、`--style`，模板为空时不带 `--template`；
- `render_manuscript()` 子进程返回 0 且生成了 PDF：结果为 ok，`pdf_bytes` 正确；
- 返回 0 但没有 PDF、返回非 0、超时（`TimeoutExpired`）：结果都是失败，日志里有原因；
- `extract_latex_errors()`：能从一段 LaTeX log 里提取 `!` 行和上下文，并做去重和截断；
- 日志尾部截断；
- 模型：默认值，新建时带示例正文，`__str__`，删除稿件时 PDF 文件一起删除。

**视图测试**（`render_manuscript` 用 mock 替代）：
- 列表、新建（302 并创建一条记录）、编辑页的 200 响应和内容（textarea、iframe 或空状态）；
- `save`：更新字段，非法 lang 返回 400；
- `render`：成功时写入 PDF 并返回 `pdf_url`；失败时保留旧 PDF，返回 `ok:false` 和日志；
- `pdf`：返回 `inline` 和 `application/pdf`，`X-Frame-Options` 为 `SAMEORIGIN`；`?download=1` 返回 attachment；没有 PDF 时返回 404；
- `markdown` 下载；删除时文件一起删除；GET 请求 `save`/`render` 返回 405。

**集成测试**（真实调用 pandoc、lualatex、typst；缺工具时 `skipUnless` 自动跳过）：
- 英文 + LaTeX：通过 Django client POST `/render/`，得到真实 PDF（以 `%PDF` 开头），再 GET `/pdf/` 拿到同样的字节；
- 中文 + LaTeX：`第1章` 标题，确认 CJK 流水线能跑通；
- 英文 + Typst：确认快速引擎能跑通；
- 故意写一个未定义的宏：PDF 仍然生成，同时 `errors` 里出现 `Undefined control sequence` 和宏名。

**浏览器 E2E 测试**（Playwright + 无头 Chromium，`StaticLiveServerTestCase`；缺 playwright 或 typst 时跳过）：
- 输入内容后变为 “未保存”，显示字数，按 `Ctrl+Enter` 渲染后 iframe 加载 `/pdf/?v=`，空状态隐藏；
- 自动保存和 `Tab` 缩进，确认前导空格保存进了数据库（这个测试发现了表单 strip 吞掉空格的 bug）；
- 在设置里改语言和标题，按 `Ctrl+S` 保存；
- 渲染失败时显示错误框。

## 8. 安全与边界

- 本地工具，不加认证，和 coverdesigner 一致。**不要直接暴露到公网**：LaTeX 以 `--shell-escape` 运行
  （这是 peanutbook 本身的构建方式），任意 Markdown 可以通过 raw LaTeX 执行命令。README 里会写明这一点。
- 渲染在一次性的临时目录里进行，用超时兜底；子进程的环境变量继承自 Django 进程。

## 9. 后续工作

- 图片或素材上传：稿件级别的 `ManuscriptAsset`，渲染时复制到 `chapter1/img/`；
- 多章节或整本书构建（`bubble-build`），以及把 coverdesigner 的封面接进来；
- 编辑区语法高亮（本地打包 CodeMirror 6）；
- 源码行和 PDF 页之间的双向跳转（SyncTeX）。
