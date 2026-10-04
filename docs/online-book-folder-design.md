# 在线书稿文件夹（Book workspace）设计文档

状态：已实现（v1，书架模式） · 位置：`web/writer/` · 日期：2026-09-28
前身：[online-writer-design.md](online-writer-design.md)（单篇稿件的在线写作，已删除）

## 1. 目标

单篇稿件只能写一章。这次要支持**整本书**：在浏览器里打开一个书稿文件夹，看到整本书的目录树，
可以编辑任意章节，预览单章 PDF，也可以构建整本书的 PDF。

核心决定是：**书稿就是磁盘上真实的 peanutbook 项目目录**（`peanut.config` + `chapterN-xxx/` + `img/` + `chapterx/` + `cover/`），
而不是存进数据库。所以：

- 在浏览器里编辑的就是磁盘上的真实文件。VS Code、git、`bubble-build` 以及已有的脚本全都照常可用。
  图片、`<!-- include: -->`、自定义 `peanut.config`、封面脚本也都不需要额外处理。
- **所有书都放在一个书架目录里**：`SHELF_ROOT`（默认 `~/shelf`，可用同名环境变量覆盖）。
  书架下一层的每个 peanutbook 文件夹就是一本书，用**文件夹名**标识（URL 形如 `/write/books/mmb/`）。
  书架目录本身就是书的清单，不需要数据库登记。
- 可以在网页上新建书稿（用 `bubble.scaffold.create_scaffold` 在书架里生成标准结构）。
  已有的书（比如 `~/mmb`）要在服务器上移进书架，或者在书架里建一个符号链接（`ln -s ~/mmb ~/shelf/mmb`），网页上无法添加。
- **浏览器看不到服务器上的任何绝对路径**（见第 2 节第 7 条）。

> 最初的版本用 `WRITER_PROJECT_ROOTS`（默认包含整个家目录）加上数据库登记，网页上可以输入任意路径打开书稿，
> 并且会显示真实路径。这等于把服务器的目录结构暴露给了浏览器，所以改成了书架模式。

### 不做（当前阶段）

- 多用户和权限：沿用 writer 的定位，单机本地与容器化写作工具。
- 实时协同、自动合并：检测到冲突时让用户选择“重新加载”或“覆盖”，不做三方实时多人协同。

## 2. 安全边界

书稿是用户真实的数据，所以路径安全是第一优先级：

1. **书架是唯一的入口**：只有 `SHELF_ROOT` 下一层的文件夹才是书。书名（文件夹名）必须是单层名字：
   不能包含 `/` 或 `\`，不能是 `.` 或 `..`，也不能以 `.` 开头（隐藏目录）或是 `__pycache__` 之类。
   书架里的符号链接是允许的，这是把外面已有的书放上书架的方式；但只有能登录服务器的人才能放，网页做不到。
2. **书的判定**：书架顶层的文件夹必须含有 `peanut.config` 文件才算一本书。只有 `chapter*/` 子目录、没有配置文件的文件夹不算。
   不满足的文件夹既不会列出来，也打不开（返回 404）。
3. **每个请求都检查路径**：前端传来的永远是书稿内的相对路径，由 `projects.resolve()` 统一解析：
   - 拒绝绝对路径和空路径，拒绝经过 `..` 之后跑到书稿目录外面的路径；
   - **书里的符号链接一律忽略**：路径上只要有一段是符号链接，读、写、删除、预览都拒绝，不管它指向哪里。
     目录树也不显示符号链接，而且它们不占用 5000 条的数量上限。这样 `leak.txt -> ~/.ssh/id_rsa`、
     `notes.md -> .git/config`、`loop -> .` 这类链接都不会有问题。
     构建时 bubble-build 链接进 `img/` 的自带图标也因此不会显示；构建本身直接读磁盘，不受影响。
     书稿目录**本身**可以是书架上的一个符号链接（见第 1 节），这条规则只管书的内部。
   - 在没有符号链接的前提下，仍然再检查一次真实路径：必须在书稿目录内，并且不落在隐藏目录里。
   - 从浏览器导入文件夹时，网页无法知道哪个文件是符号链接（浏览器只给文件内容）。
     所以导入进来的都是普通文件；这条规则只对导入之后、或在服务器上放进书里的链接起作用。
4. **隐藏目录不显示**：以 `.` 开头的文件或目录、`__pycache__`、`node_modules` 都不出现在目录树里，也不能通过 API 访问
   （`.build/` 和 `.git/` 都在此列）。
5. **删除即移入回收站**：文件会被移动到 `<书稿>/.writer-trash/<时间戳>/<相对路径>`，可以手动恢复。
6. 依然**不能暴露到公网**，原因同 writer：LaTeX 的 `--shell-escape`。
7. **不暴露服务器路径**：
   - 页面和 API 里只出现书名和书内的相对路径；
   - 构建日志、错误信息里的绝对路径由 `projects.scrub_paths()` 替换：书稿目录（包括经符号链接解析后的真实目录）
     替换为 `<book>`，书架替换为 `<shelf>`，peanutbook 包目录替换为 `<peanutbook>`，家目录替换为 `~`；
     按长度从长到短替换，保证 `/home/me/shelf/x` 不会先被替换成 `~/shelf/x`；

## 3. 数据模型

没有数据库模型：书架目录本身就是书的清单（`projects.list_books()`）。显示名取 `peanut.config` 里的 `book_title`，
没有就用文件夹名。要把一本书从书架上拿走，在服务器上把文件夹移走即可。

## 4. 模块划分

```
writer/
  projects.py    路径安全、目录树、读写文件（冲突检测、原子写入）、新建章节、上传、回收站、发现已有书稿
  jobs.py        后台构建任务：线程 + 子进程（进程组超时），日志实时追加，每本书同一时间只允许一个构建
  diagnostics.py extract_latex_errors / extract_typst_errors（从已删除的单篇稿件模块挪过来）
  views_books.py 书稿相关的视图
  templates/writer/book_list.html, book_workspace.html
```

### 4.1 文件读写（`projects.py`）

- **可编辑的文本类型**：`.md .markdown .txt .json .config .yaml .yml .tex .bib .css .lua .py .tpl .csv .html .typ`，大小不超过 2 MB。
  其他类型只能预览（图片、PDF）或下载。
- **读取**时返回 `{content, mtime}`。`mtime` 使用 `st_mtime_ns` 的字符串形式。
- **保存**时要带上读取时拿到的 `mtime`。如果磁盘上的文件在这之后被别处改过（比如 VS Code、git checkout），
  返回 **409 冲突**，前端提示用户“重新加载（放弃本地修改）”还是“覆盖”。选择覆盖时带上 `force=1` 重新提交。
- **原子写入**：先写到同目录的临时文件，再 `os.replace` 替换，并保留原文件的权限位。写到一半断电也不会把章节写坏。
  保留原有的换行风格：不做任何换行转换，前端传来什么就写什么。
- **新建章节**：编号 N 取现有 `chapterK-*` 目录的最大 K 再加 1。目录名是 `chapterN-<标题 slug>`，
  文件名按书稿语言用 `bubble.locales` 的本地化规则生成（例如 cn 对应 `chapterN_zh.md`）。
  初始内容是 `# Chapter N: 标题`，CJK 语言则是 `# 第N章 标题`。同时建好 `img/` 目录。
- **上传**：只接受图片和 PDF（`png jpg jpeg gif svg webp pdf`），单个文件不超过 20 MB，放到指定目录（通常是某章的 `img/`）。
  文件重名时自动加上 `-1`、`-2` 后缀，不会覆盖已有文件。

### 4.2 构建（`jobs.py`）

两种构建：

| 类型 | 命令（`cwd` 为书稿根目录） | 产物 |
|---|---|---|
| 单章 | `python -m bubble.convert <章节相对路径> --engine E` | 章节 `.md` 旁边的同名 `.pdf` |
| 整本书 | `python -m bubble.build_book --engine E` | 书稿根目录下本次新生成的 `*.pdf`（取修改时间晚于构建开始的最新一个） |

- 语言、章首样式、页面模板**都由书稿自己的 `peanut.config` 决定**，网页不覆盖，保证和命令行构建结果一致。网页上只选择引擎。
- 构建直接在书稿目录里运行，和用户在终端里执行 `bubble-convert` / `bubble-build` 完全一样，
  所以会生成 `.build/` 和各章的 `.pdf`，整本书构建还会重新生成封面 PDF。这些都是 peanutbook 的正常行为。
- **后台任务**：整本书可能要跑好几分钟，不能让 HTTP 请求一直挂着。所以 `POST /build/` 只负责启动一个线程，立即返回 `job_id`；
  前端每秒轮询一次 `GET /jobs/<id>/?since=<offset>`，拿到增量日志、状态、PDF 路径和错误列表。
- **每本书同一时间只允许一个构建**（两个构建会共用 `.build/`，互相踩踏）。已有构建在跑时返回 409 和正在运行的 `job_id`，
  前端直接接上去显示它的进度。
- **超时**：单章 `WRITER_CHAPTER_TIMEOUT`（默认 300 秒），整本书 `WRITER_BOOK_TIMEOUT`（默认 1800 秒）。
  超时后杀掉整个进程组，和单篇稿件的做法一致。
- **错误提取**：
  - Typst：对输出调用 `extract_typst_errors`；
  - LaTeX 单章：设置 `PEANUTBOOK_KEEP_LATEX_LOG=1`，读取 `.build/**/<章节名>.log` 中本次生成的那一份；
  - 整本书：LaTeX 的中间文件在系统临时目录里，这里只对输出调用 `extract_latex_errors`，尽力而为。
- 任务状态只保存在内存里（最多保留 50 个）。开发服务器重启后任务记录会丢失，但生成的 PDF 还在磁盘上，不影响使用。

### 4.3 接口（前缀 `/write/books/`，除非另有说明）

| URL | 方法 | 作用 |
|---|---|---|
| `/write/` | GET | 首页：书架上的书，以及“新建书稿”表单 |
| `/write/new-book/` | POST | 新建书稿：在书架里用 scaffold 生成（放在 `books/` 之外，以免和名为 `new` 的书冲突） |
| `<book>/` | GET | 工作区页面（`<book>` 是书架上的文件夹名） |
| `<book>/tree/` | GET | 目录树 JSON |
| `<book>/file/?path=` | GET | 读取文件，返回 `{content, mtime, editable}` |
| `<book>/file/` | POST | 保存文件（`path, content, mtime, force`），冲突时返回 409 |
| `<book>/new-chapter/` | POST | 新建章节，参数 `title` |
| `<book>/new-file/` | POST | 新建空文本文件，参数 `path` |
| `<book>/upload/` | POST | 上传文件，参数 `dir` 和 `file` |
| `<book>/trash/` | POST | 删除文件（移入回收站），参数 `path` |
| `<book>/build/` | POST | 启动构建（`kind=chapter\|book, path, engine`），返回 `{job_id}`，已有构建在运行时返回 409 |
| `<book>/jobs/<job_id>/` | GET | 查询任务状态和增量日志 |
| `<book>/raw/<path>` | GET | 直接输出原始文件（inline，带 `SAMEORIGIN`，禁止缓存），用于 PDF 和图片预览 |

所有写操作都是 POST 并带 CSRF token。

## 5. 前端（`book_workspace.html`）

三栏布局，两条分隔条都可以拖动：

```
┌──────────────┬───────────────────────────┬───────────────────────────┐
│ 目录树        │ 编辑器（当前文件）          │ 预览（PDF / 图片）          │
│ + 章节 + 文件  │ 路径 · 状态 · 字数          │ [单章] [整本书] 引擎▾        │
│ ⬆ 上传  🗑    │ CodeMirror（见 5.4）        │ 构建日志 / 👁 Live 预览       │
│ ▸ chapter1-… │                           │ iframe                    │
└──────────────┴───────────────────────────┴───────────────────────────┘
```

- **目录树**：目录可以折叠，展开状态记在 `localStorage` 里。点击文本文件会在编辑器中打开；
  点击图片或 PDF 会显示在预览区。当前打开的文件高亮显示。
- **切换文件**时如果有未保存的修改，先自动保存；保存失败则停止切换。
- **编辑器**：沿用单篇稿件的增强功能（Tab 缩进、Ctrl+S 保存、Ctrl+Enter 渲染当前章、1.5 秒后自动保存、字数统计）。
  URL 带 `?file=<路径>`，刷新页面后仍打开同一个文件。
- **外部修改检测**：浏览器窗口重新获得焦点时，检查当前文件的 `mtime`。如果没有未保存的修改，就静默重新加载；
  如果有，就显示冲突条。这样和 VS Code 同时编辑时不会互相覆盖。
- **预览**：
  - “单章”按钮构建当前打开的 `.md`；“整本书”按钮构建全书。
  - 构建过程中实时滚动显示日志，结束后 iframe 加载生成的 PDF，错误列表显示在上方。
  - 打开某章时，如果它旁边已经有 PDF，就直接显示这份 PDF，不需要重新构建。

## 5.4 编辑器、实时预览、全书搜索与 git（2026-10-04）

动机：评估过用 code-server 替代工作区，结论是不替代，而是把写书真正需要的几项能力做进现有编辑器，
这样书架、封面、发布、路径沙箱都保留，也不引入一个能拿到宿主机 shell 的终端。

**前端打包**：`web/writer/frontend/`（npm + esbuild）打包成 `web/writer/static/writer/editor.js`（IIFE，约 1.2 MB 压缩后）
和 `static/writer/katex/`（KaTeX 样式和 woff2 字体）。打包产物提交进仓库，服务器和 Docker 镜像都不需要 Node。
它向页面暴露 `window.PBWriter = {createEditor, renderMarkdown}`，页面脚本仍然是原来的普通 `<script>`。
`@vscode/markdown-it-katex` 自带一份 KaTeX，构建时用 esbuild `alias` 指回同一份，避免打包两份，也让公式缓存生效。

**编辑器**（`frontend/src/editor.js`，CodeMirror 6）替换原来的 `<textarea>`：
- 语法高亮：Markdown（代码块里的语言嵌套高亮），以及按扩展名识别的 LaTeX/`.tpl`、Python、JSON/`peanut.config`、YAML、CSS、HTML、Lua、shell 等（`languages.js`，全部静态打包，不做按需加载）；
- 多光标（Ctrl/⌘+点击、Ctrl+D、Ctrl+Alt+↑/↓）、Alt+拖动矩形选择、Ctrl+F 查找替换（正则/大小写/整词）、标题折叠、自动换行；
- 主题跟随页面的 `data-theme`（MutationObserver），颜色取自页面的 CSS 变量；
- Ctrl+S / Ctrl+Enter / Ctrl+Shift+F 由编辑器的 keymap 处理（`Prec.highest`），页面的全局 keydown 遇到 `defaultPrevented` 就跳过，避免执行两次；
- 打开文件用 `setDoc()` 换一个新的 EditorState：撤销历史不跨文件，也不触发 onChange。

**实时预览**（`frontend/src/preview.js`）：markdown-it + footnote + attrs（pandoc 风格 `{...}`）+ KaTeX，再加 peanutbook 扩展：
- `@@pb:var@@` 变量：页面通过 `json_script` 拿到 `projects.preview_variables()`（每种语言一份，用 `bubble.variables.resolve_variables`），
  按 `/file/` 接口新返回的 `lang` 选择；
- `>NOTES:`…`>NOTEE` 等 callout（跨多段落，也支持同一引用块里结尾）；`\newpage`、`HBAR_*`、`% END_OF_PREFACE` 之类的整段指令显示成虚线小标签；
  `<!-- include: … -->` 显示为标签；
- `\label{eq:x}` / `\\WFHLABEL:eq:x` 编号成 `(章.n)`，`@eq:x` 和 `\eqref{eq:x}` 替换成编号；`@fig:`/`@tbl:` 等显示为标签；
- 代码块去掉开头的 `#STYLE:`/`#BKG:`/`#LINENUM` 等指令行，用同一套 lezer 解析器高亮（不额外引入 highlight.js）；
- 图片：相对路径按当前文件所在目录解析成 `raw/` 地址（raw HTML 的 `<img>` 也处理），加载失败时再按书稿根目录重试一次；
  `width=40%`、`alpha`、`rotate` 转成 style；段落里只有一张图时按 pandoc 的规则显示成带标题的 figure；
- 每个块带 `data-line`（源码行号）：编辑器滚动时预览同步（在前后两个块之间插值），双击预览块跳到对应源码行；
- 输出经过 DOMPurify 净化（书稿里的 `<script>`、`onerror` 等会被去掉）；KaTeX 结果按公式文本缓存，打字时不重复排版。
- 右侧面板的 **👁 Live / 📄 PDF** 切换记在 `localStorage`；构建完成时自动切到 PDF。

**全书搜索**（`writer/search.py`，`GET <book>/search/?q=&case=&word=&regex=`）：遍历的文件和目录树完全一致（`list_tree` 的规则：
不进隐藏目录、不跟随符号链接），只读可编辑的文本文件，最多 1000 条结果、5000 个文件。逐行匹配，返回行号、列号和截断后的片段。
**全部替换**（`POST <book>/replace/`）只处理上一次搜索结果里的文件，并且要带上搜索时的 `mtime`：之后被改过的文件跳过、不覆盖。
非正则模式下替换文本按字面处理（不展开 `\1`）。空匹配（如 `^`）既不显示也不替换。
前端在搜索、替换、提交之前只保存**有未保存修改**的文件（`saveIfDirty`）。原来的 `save()` 总会重写文件、改变 mtime，
会让刚搜索过的文件在替换时被判定为"已变化"。

**git**（`writer/gitops.py`）：只运行固定的几个子命令，`cwd` 是书稿目录，并用 `-- .` 限定在书稿内。所以书在一个更大仓库的子目录里时，
只列出、只提交这本书的文件（路径用 `rev-parse --show-prefix` 换算成书内相对路径）。隐藏路径照样过滤掉。
- `GET <book>/git/[?log=1]`：分支和变更列表（M/A/D/R/U/?），可附带最近 30 条历史；
- `GET <book>/git/head/?path=`：HEAD 版本的内容，供编辑器的 **± Changes** 使用（`@codemirror/merge` 的 unifiedMergeView，
  行内显示删除内容，每处修改都有一个 ↶ Revert）；
- `POST <book>/git/commit/`（`message`、多个 `paths`）：先 `add -A -- paths`，再 `commit -- paths`，仓库里其他已暂存的内容不受影响。
  服务器上没有配置 git 身份时，使用 `Peanutbook Writer <writer@localhost>`；
- `POST <book>/git/discard/`：已跟踪的文件 `restore` 回 HEAD；新文件移进 `.writer-trash/`，不直接删除；
- 加了 `-c safe.directory=*`：书架通常是挂载进容器的，属主和容器用户不同，不加的话 git 会拒绝操作。
  `GIT_TERMINAL_PROMPT=0`，超时 60 秒。**不做 push/pull**，凭据不进浏览器。
- Docker 镜像（`Dockerfile`、`Dockerfile.release`）加装了 `git`；没有 git 或者书不是仓库时，面板里会给出说明。

左栏顶部改成 **📁 Files / 🔍 Search / ⎇ Git** 三个标签页，当前标签记在 `localStorage`；目录树里有变更的文件带状态字母。
测试：`writer/tests_search_git.py`（搜索、替换、git 都在临时书架上测，git 的情况是"书在大仓库的子目录里"）；
原来的浏览器 E2E 测试改成操作 `.cm-content`。

## 4.4 文档类型

书架上不只放书。`peanut.config` 的 `doc_type` 字段记录类型：

| 类型 | 新建时生成 | 构建命令（`cwd` 为项目目录） | 产物 |
|---|---|---|---|
| `book` 书 | `create_scaffold`：多语言、N 章 | 单章 `bubble.convert`，整本书 `bubble.build_book` | 章节旁的 PDF / 根目录的书 PDF |
| `paper` 论文 | `bubble.paper.scaffold_paper`：`paper.md`、`references.bib` | `python -m bubble.paper paper.md --lang L` | `paper.pdf` |
| `bizplan` 商业计划书 | `create_bizplan_scaffold`：`bizplan.md` | `python -m bubble.bizplan bizplan.md --lang L` | `bizplan.pdf` |
| `proposal` 提案 | `create_proposal_scaffold`（即 `bubble-scaffold --proposal`）：`proposal.md` | `python -m bubble.proposal proposal.md --lang L` | `proposal.pdf` |

- **旧项目推断类型**：`peanut.config` 里没有 `doc_type` 时，有章节目录就是书；否则按存在 `paper.md` / `bizplan.md` / `proposal.md` 判断；都没有则按书处理。
  主文件默认按类型取上表中的文件名，可以用配置里的 `main` 覆盖。
- **语言**：论文、商业计划书、提案都是单语言，新建时只选一种语言。只有书支持多语言和章节数，表单会按所选类型显示或隐藏对应字段。
- **工作区**：非书类型只有一个“⚡ Build <类型>”按钮（Ctrl+Enter 也会触发），固定用 LaTeX 构建主文件。
  没有“+ Chapter”、整本书构建、引擎和语言选择、封面这些只属于书的功能。首次打开时自动打开主文件。
- **服务端校验**：书只接受 `chapter` / `book` 两种构建，其他类型只接受 `document`，不匹配时返回 400。封面入口对非书类型返回 404。

## 4.5 从本地文件夹导入

首页的“Import a folder”卡片：用浏览器的**文件夹选择框**（`<input webkitdirectory>`）选中你电脑上的书稿文件夹，
网页把它**复制**到书架上。整个过程服务器路径不会出现在网页上，原文件夹也不会被改动。
书如果本来就在服务器上、想原地编辑，仍然是在服务器上 `ln -s` 到书架。

1. **浏览器预检**：跳过路径中任何一段以 `.` 开头的文件（`.git`、`.build`…），以及 `__pycache__`、`node_modules`；
   文件夹顶层必须有 `peanut.config`，否则直接提示，不上传；显示文件数、总大小和跳过的文件数；书架上的名字默认用文件夹名，可以修改。
2. **分批上传到暂存区**：`POST import/` 生成一个 32 位十六进制 token，并建立 `<shelf>/.incoming/<token>/`（隐藏目录，不会被当成书）。
   然后 `POST import/<token>/files/` 分批上传，每批最多 50 个文件或 40 MB（Django 默认每个请求最多 100 个文件）。
   服务端对每个路径再做一次校验（`import_relpath`）：不能是绝对路径，不能含 `..`，不能有隐藏的路径段。同一路径上传两次视为错误。
   单个文件上限 200 MB，总量上限 2 GB；已上传的总量记在旁边的 `<token>.bytes` 文件里，避免每上传一个文件都要遍历整个目录。
3. **完成**：`POST import/<token>/finish/` 先确认顶层有 `peanut.config`，再用一次 `os.rename` 把暂存目录移到书架上。
   用户给的名字合法且没被占用就用它，否则用 slug 并加后缀。之后跳转到这本书的工作区。
4. **失败处理**：任何一批出错，服务端立即删除整个暂存目录，前端也会调用 `abort`。所以书架上不会出现上传到一半的书。
   超过 24 小时的暂存目录会在下次开始导入时清掉。

## 5.0 移除一本书

首页的书卡片右上角有 🗑，工作区左下角有“Remove book from shelf”，两处都进入 `books/<book>/remove/` 确认页：

- 确认页显示章节数和语言。必须**手动输入书的文件夹名**才能执行，防止误点。
- 书不会被真删，而是移到 `<shelf>/.trash/<时间戳>-<书名>`。`.trash` 是隐藏目录，不会被当成书列出来，
  想恢复就在服务器上把它移回书架。
- 通过符号链接放上书架的书，移走的是**链接本身**（`os.rename` 不跟随链接），原来的书稿文件夹完全不动。
- 这本书正在构建时拒绝移除。

## 5.1 多语言

peanutbook 的多语言书，是在同一个章节目录里为每种语言各放一个文件：`chapter1.md`（en）、`chapter1_zh.md`（cn）、
`chapter1_tc.md`、`chapter1_jp.md`、`chapter1_sp.md`。`peanut.config` 的 `lang` 是主语言，`batch_default_langs` 列出全部语言。

- **新建书**：表单里可以多选语言，并指定主语言和章节数（1–50）。`create_scaffold` 只会生成 en 和 zh 的文件，
  所以 `projects.create_book()` 为其余语言复制最接近的模板（CJK 语言复制 zh，其他复制 en）；没选 en 时，
  再删掉 scaffold 生成的英文文件。
- **书的语言**（`project_langs`）：优先读 `batch_default_langs`；没有这个配置时，根据章节目录里实际存在的本地化文件推断。主语言排在第一位。
- **+ Chapter**：为书的每种语言各建一个文件，标题行按语言使用 `# 第N章 …` 或 `# Chapter N: …`（bubble.convert 只认这两种格式）。
- **构建时一定传 `--lang`**：
  - 单章构建按文件名后缀判断语言（`_jp` → jp）；没有后缀的文件，书里有 en 就按 en，否则按主语言；
  - 整本书构建使用工作区里语言下拉框选中的语言，并且只能选这本书有的语言。

  不传的话，bubble 会用主语言构建。实测：在主语言为 en 的书里构建 `chapter1_jp.md`，会走 lualatex，
  汉字用了简体中文字体（`NotoSerifCJKsc`，字形不对），章首也显示 “Chapter 1”；加上 `--lang jp` 后改走 xelatex，
  用 `NotoSerifCJKjp`，章首显示 “第1章”。集成测试会检查 PDF 里的字体。

## 5.2 封面：封面设计器 ↔ 书

封面设计（`CoverDesign`）现在可以关联一本书：`book` 字段存书架上的文件夹名，`book_exported_at` 记录上次导出时间。代码在 `coverdesigner/booklink.py`。

- **从书进入**：工作区预览栏的“🎨 Cover”按钮，按当前选中的语言打开这本书的封面设计。
  还没有对应的设计时，用 `peanut.config` 预填一份：`book_title`、`book_subtitle`、`author_<语言>` 或 `author`，
  以及和书的尺寸匹配的 provider（例如 6x9 对应 `kdp/paperback_6x9`）。语言对应关系：cn ↔ zh，其余相同。
- **导出到书**：封面编辑页的预览栏下方有“📚 Book”面板，选好书后点“Export to book”，
  以 **300 dpi**（`PRINT_DPI`）渲染，写到 `cover/<尺寸>/out/` 下：
  - `cover_front[_<tag>].pdf`、`cover_back[_<tag>].pdf`：页面恰好是裁切尺寸（例如 7×10 英寸），供 bubble-build 放在书的首页和末页；
  - `cover_front[_<tag>].png`：EPUB 封面；
  - `<provider>_full_cover_<lang>.pdf`：包含书脊和出血的完整封面，用于上传给印刷商。

  `<tag>` 就是 bubble-build 查找封面时使用的语言后缀（英文没有后缀，简体中文是 `_zh`，其余同理），所以构建对应语言时会直接用上。
- **不覆盖手工封面**：`out/` 的优先级高于 `cover/<尺寸>/` 本身，所以用户原来放在 `cover/<尺寸>/cover_front.pdf` 的手工封面只是被“遮住”，不会被改动。
  `out/` 里已有的同名文件会先移进书的 `.writer-trash/` 再写入。
- **拒绝的情况**：设计的裁切尺寸和书的封面目录尺寸不一致（例如书是 7x10，设计是 6x9）；设计的语言不在书的语言里；书已经不在书架上。
- **书的封面目录**：和 bubble-build 用同一个函数来确定。`cover_directory_for_template()` 已从 `BookBuilder.get_cover_directory` 提取为模块级函数，
  两边共用，保证结果一致。
- **dpi 参数化**：封面设计器的渲染从固定的 `PREVIEW_DPI` 改为参数，`render_images(design, dpi)`。
  测试会把 300 dpi 的渲染缩小到 150 dpi，和直接渲染的 150 dpi 结果比对，平均差异小于 2/255，
  确认字号、logo 等都随 dpi 正确缩放，而不是写死的像素值。

### 5.3 封面设计器是书的内置功能

封面设计器不再是一个独立的工具：

- `/` 直接跳转到书架（`/write/`），原来的封面列表页已删除。顶栏品牌改为“📚 Peanutbook”，
  “🏠 Shelf”按钮回到书架；“+ New cover”和“✍️ Write”入口都去掉了。
- **每本书有自己的封面页** `books/<book>/covers/`（工作区里的“🎨 Covers”按钮进入），功能包括：
  - 列出这本书的全部封面设计：缩略图、语言、印刷规格、是否已导出。印刷尺寸和书不一致的会标出 ⚠ 警告；
  - **新建**：选择一种语言，用 `peanut.config` 预填一份新设计（`booklink.new_design_for_book`，每次都新建一份）；
  - **挂载已有封面**：可以挂上来的是**不属于书架上任何一本书的设计**，包括改造前做的封面，以及所属书已被移出书架的封面（`booklink.unassigned_designs`）。已经属于书架上其他书的封面不能被挂走。
- **编辑器处在书的上下文里**：左上角和底部是“← 书名”，返回这本书的封面页。书面板变成“Export to “书名””，不用再选书。
  只有不属于任何书的设计，才显示“选书 → Attach & export”。
- **删除封面**后回到它所属书的封面页；不属于书的封面删除后回到书架。
- 旧的 `coverdesigner` 路由（按 pk 访问的编辑、克隆、下载等）保留不变，只是不再作为入口。克隆出来的封面会带上原来的 `book`，仍然属于同一本书。

### 5.4 目录树右键上下文菜单（Context Menu）

左侧文件目录树支持全功能的鼠标右键上下文菜单与操作：
- **右键文件**：
  - `Rename`（快捷键 `F2`）：行内/弹窗重命名，自动保持相对路径并同步更新已打开的 Tab。
  - `Duplicate`：快速生成文件副本（自动处理同名冲突，后缀如 `-copy.md`）。
  - `New File Here`：在当前文件所在目录就地新建文件。
  - `Copy Relative Path`：一键复制书内相对路径至剪贴板并弹出 Toast 提示。
  - `Download`：直接从浏览器下载该源文件。
  - `Move to Trash`：安全移入该书的 `.writer-trash/` 目录，并关闭关联 Tab。
- **右键目录（文件夹）**：
  - `New File Here`：在该目录下新建文件。
  - `New Subfolder`：在该目录下新建子文件夹。
  - `Rename`：重命名目录，并同步递归更新所有已打开子文件的 Tab 路径。
  - `Copy Relative Path`：复制目录相对路径。
  - `Upload to Folder`：直接向该目录上传图片或文件。
  - `Move to Trash`：整目录安全递归移入回收站。
- **右键空白根目录**：
  - 快速在书根目录下新建文件或新建文件夹；一键刷新目录树（⟳）。

### 5.5 多标签页工作区编辑器（Multi-Tab Workspace Editor）

工作区中心编辑区域支持现代 IDE 级多标签页编辑：
- **无缝状态恢复与历史快照**：
  - 基于 CodeMirror 6，切换 Tab 时自动保存各文档独立的 `EditorState`（包含光标位置、当前选区、滚动条位置及完整的 Undo/Redo 撤销历史）。
  - 切换回标签页瞬间恢复编辑状态，无需重新从服务器拉取，保留完整编辑撤销链。
- **修改状态提示与防丢拦截**：
  - 文件修改后实时显示醒目的黄色未保存圆点 `●`。
  - 手动保存（`Ctrl+S`）或自动保存成功后清除。
  - 关闭有未保存变动的标签页时弹出确认保护提示。
- **快捷操作与手势**：
  - 鼠标中键单击标签页快速关闭。
  - 鼠标滚轮在 Tab 栏横向滚动浏览。
  - 快捷键：`Alt+W` 关闭当前 Tab；`Alt+←` / `Alt+→` 向左/向右循环切换 Tab。
- **标签页右键菜单**：
  - 支持 `Close Tab`、`Close Others`（关闭其他）、`Close to the Right`（关闭右侧）、`Close Saved Tabs`（仅保留未保存）、`Copy Relative Path`、`Close All Tabs`。
- **状态持久化**：
  - 打开的 Tab 列表自动记录在 `localStorage`，刷新页面自动恢复上次编辑会话。

### 5.6 侧边栏布局切换与 Zen 专注写作模式（VS Code Layout Toggles & Zen Mode）

像 VS Code 一样，工作区最左侧（目录/搜索/Git）与最右侧（Live 预览/PDF 编译）面板均可随手折叠与展开：
- **顶部全局布局按钮组**：
  - 顶部导航栏提供直观的 VS Code 经典布局图标组 `[ ◧ ] [ ◨ ]`。
  - 激活时以亮蓝高亮并填充对应侧边栏矩形，隐藏时自动变为轮廓低亮。
- **Tab 栏与面板就地控制**：
  - 编辑区 Tab 栏右端内置轻量布局切换按钮。
  - 左侧面板顶部配有 `«` 折叠按钮，右侧面板顶部配有 `»` 折叠按钮。
- **快捷键**：
  - **`Ctrl+B`**（或 macOS `Cmd+B`）：快速切换左侧面板。
  - **`Ctrl+Alt+P`** 或 **`Ctrl+J`**：快速切换右侧预览面板。
- **全屏 Zen 专注模式**：
  - 当同时折叠左侧和右侧面板时，中间编辑器自动 100% 铺满整个屏幕宽度，消除一切干扰。
  - 此时编辑器栏左上角与右上角会自动浮现 `📁 Files` 与 `👁 Preview` 快速召回胶囊按钮。
- **智能唤起联动**：
  - 按 `Ctrl+Shift+F` 进行全书搜索时，若左侧处于折叠状态，会自动展开并聚焦搜索输入框。
  - 按 `Ctrl+Enter` 编译章节时，若右侧处于折叠状态，会自动展开右侧预览展示编译日志与生成产物。
- **布局记忆**：面板显隐状态持久化存储于 `localStorage`。

### 5.7 Live 实时预览：Mermaid 矢量图表与 Peanutbook 排版语法

在右侧预览栏切换至 **`👁 Live`** 模式，即可享受无需触发 LaTeX 编译的零延迟即打即显排版：
- **Mermaid 架构图与流程图原生渲染**：
  - 内置离线 `mermaid.min.js`，无需安装 `mmdc` 即可在浏览器端实时将 ` ```mermaid ` 和 ` ```{.mermaid width=...} ` 编译为高清矢量 SVG。
  - 自动防抖容错：打字半途中语法暂未闭合时自动抑制异常，打完立即平滑渲染。
  - 自动适配明暗主题（☀️ Light / 🌙 Dark 动态重新着色）。
- **Peanutbook 专有排版语法直观展现**：
  - **语义提示框**：`>NOTES:`（💡 Note 蓝框）、`>IMPORS:`（⭐ Important 紫框）、`>WARNS:`（⚠️ Warning 橙黄警示框）、`>CENTERS:`（题献与跋语居中块）。
  - **东方与古典章节分割线 (HBAR)**：`HBAR1_CLOUD`（☁️ 云纹分割线）、`HBAR_TOP` / `HBAR_BOT`（❖ 古典饰条）、`HBAR_CENTER_FLOWER_RED`（🌸 雅致红花条）等。
  - **分页符指示**：`\newpage` 渲染为精致的虚线分页符指示器 `⸺ Page Break (\newpage) ⸺`。
  - **动态变量置换**：`@@pb:var_name@@` 实时结合书本配置替换。
  - **KaTeX 数学公式与自动编号**：LaTeX 公式即时渲染，`\WFHLABEL:eq:...` 与 `@eq:...` 自动关联生成章节公式编号（如 `(1.1)`）。
  - **交叉引用芯片**：`@fig:` / `@tbl:` / `@def:` / `@thm:` 自动渲染为圆角引用胶囊。

## 6. 与单篇稿件的关系

单篇稿件（Drafts，见 [online-writer-design.md](online-writer-design.md)）**已经删除**：章节本来就应该属于某一本书，
它和"只有一章的书"是重复的概念。删除内容包括 `Manuscript` 模型（迁移 `0004` 删表）、视图、模板和测试。
它的错误提取函数挪到了 `writer/diagnostics.py`，整本书构建仍在使用。`/write/` 首页现在只列出书架上的书。

## 7. 测试计划

`web/writer/tests_books.py`。所有测试只在临时目录里操作，通过 `override_settings(SHELF_ROOT=tmp)` 指定书架，
**绝不触碰用户真实的书稿**。

- **projects 单元测试**：
  - 路径安全：`..`、绝对路径、隐藏目录、写操作不能通过符号链接逃逸、读操作可以跟随指向允许根目录的符号链接；
  - 目录树：过滤规则、排序、文件类型；
  - 读写：冲突检测、`force` 覆盖、原子写入后权限位保持不变、不可编辑的类型被拒绝；
  - 新建章节：编号、slug、en 和 cn 的文件命名；
  - 上传：自动改名、拒绝不支持的扩展名；
  - 回收站；
  - 书架：非法书名（`..`、带斜杠、隐藏目录）、不像书稿的目录、书架外的目录都返回 404；书架里的符号链接可以打开；
  - 路径清理：日志、错误信息、首页和工作区页面里都不出现临时目录、书架、家目录或 peanutbook 包的绝对路径
    （真实的 LaTeX 构建日志也覆盖到了）。
- **jobs 单元测试**（子进程用 mock 替代）：单章或整本书成功并找到 PDF、失败、超时时杀掉进程组、同一本书并发构建返回 busy、增量日志的 offset。
- **视图测试**：每个接口的正常路径和错误路径（404、400、409、405），以及 raw 接口的响应头。
- **集成测试**（需要真实的 LaTeX 和 Typst，缺少时跳过）：在临时目录里 scaffold 一本书，通过 HTTP 分别做单章 LaTeX、单章 Typst、整本书的构建，然后轮询任务直到成功，并验证 PDF。
- **浏览器 E2E 测试**（Playwright）：打开工作区，点击目录树里的章节，编辑并保存，渲染单章后 iframe 出现 PDF；
  在磁盘上直接改文件以制造冲突，确认冲突条出现并且“重新加载”有效；新建章节后目录树里出现新条目。

## 8. 后续工作

- 目录重命名、移动、章节重新编号；
- 整本书构建完成后，通过 SyncTeX 点击 PDF 跳回对应的源文件。
