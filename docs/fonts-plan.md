# System font selector implementation plan

## 目标

让 Cover Designer 的 Title font（以及共用该字段的 Subtitle、Author、背面和书脊
文字）可以选择这台机器已经安装的字体，**不下载字体、不新增字体包依赖**。

字体选择必须满足：

- 下拉框来自当前运行环境的系统字体；
- 保存后能重新打开并保持选择；
- Latin 标题使用用户选择的 family；
- CJK 标题仍然使用有对应字形的 CJK fallback；
- 找不到字体或字体不能加载时，页面和日志都明确显示问题；
- 预览和最终封面走同一套解析逻辑；
- 保留已有的 `sans`、`slab`、`mono` 等旧值，不破坏已有设计。

## 推荐架构

### 1. 抽出共享字体发现模块

在 `bubble.cover.fonts` 增加系统字体发现 API，不在 Django model import 时直接执行
昂贵或可能失败的扫描。建议提供：

```python
@dataclass(frozen=True)
class SystemFont:
    family: str
    style: str
    path: Path
    is_variable: bool
    is_cjk_capable: bool

def list_system_fonts(*, include_special=False) -> list[SystemFont]:
    ...

def resolve_system_font(family: str, *, text: str = "", lang: str = "en") -> Path:
    ...
```

实现优先复用现有的 `fontconfig` 解析、TTC face 提取和
`matplotlib.font_manager` fallback，不引入 `fonttools`、`freetype-py` 或其他
PyPI 字体依赖。Pillow 继续负责最终加载。

### 2. 发现并规范化字体

扫描结果要按“family + 可用普通 face”去重，而不是把每一个字体文件都显示为
一个选项：

1. 从 `fontconfig`/matplotlib 获取 family、style 和文件路径；
2. 选择 Regular/Book/Normal 作为默认 face；没有普通 face 时选择最接近的可加载
   face；
3. 规范化 family 名称，去除重复别名和重复路径；
4. 排除 emoji、数学符号、图标、纯特殊脚本等不适合作为普通标题的字体；
5. 用 Pillow 实际打开候选文件，不能打开的条目不进入下拉框；
6. 缓存扫描结果，并提供显式刷新机制，避免每次表单渲染都扫描 444 个 family。

初期可以保守过滤，只展示可加载且包含基本 Latin 字符集的 family。CJK-only
字体通过专门的 CJK fallback 逻辑提供，不要混入普通 Latin 列表。

### 3. 不再把动态 family 放进固定 choices

现有 `TITLE_FONT_FAMILY_CHOICES` 继续保留，作为旧设计的兼容值和稳定语义选项。
动态字体不应硬编码进这个列表，因为 Django model 的 choices 会在启动时固定，
而系统字体属于运行环境。

建议把字体字段从固定 choices 改为普通 `CharField`，并在表单层做验证：

- 空值和旧别名仍按原逻辑处理；
- 动态值保存为经过规范化的 family 名称；
- 只允许来自当前系统字体发现结果的 family；
- 对失效的历史值保留原字符串，编辑页显示“字体不可用”，不能静默改成另一款
  字体；
- 不要把用户提交的 family 名称拼进 shell 命令或文件路径。

由于该字段目前 `max_length=10`，需要迁移到足够容纳真实 family 名称的长度，
建议至少 200。所有 `*_font_family` 字段应保持一致，并增加迁移测试。

### 4. 表单和 UI

在 `web/coverdesigner/forms.py` 中：

1. 初始化表单时读取缓存后的系统字体列表；
2. 将旧语义选项放在顶部；
3. 将系统字体按 family 名称排序，必要时分组为 Serif、Sans、Mono、Other；
4. 在选项标签中显示 family，避免把 Regular、Bold 等 face 误认为不同字体；
5. 对不可用的已保存值添加 disabled 的警告项，而不是让 Django 直接拒绝整个
   表单；
6. 需要时提供“Refresh system fonts”操作，刷新后重新打开表单。

第一版可以只改 Title font；但因为多个模型字段共用同一套 choices，最终应把所有
封面文字字段统一接入同一字体发现和验证逻辑，避免 Title 能选而 Subtitle 不能选。

### 5. 渲染路径

在 `resolve_title_font()` 中区分两种情况：

```text
旧语义值（sans/slab/mono/...）
    -> 现有字体栈和现有 CJK variant 行为

真实系统 family
    -> 解析 Regular face并加载
    -> 纯 Latin：使用该 family
    -> 含 CJK：使用该 family（若覆盖字形）或明确的 CJK fallback
```

不能因为用户选择的 family 缺少 CJK 字形，就让整段文字悄悄变成 DejaVu。应至少
记录实际使用的字体路径；更好的 UI 是显示“中文字符使用 CJK fallback”。

预览 `render_panel_texts()`、全封面 `assemble_full_cover()` 和书脊渲染必须共同
调用这个解析函数，不能各自实现一套字体查找。

### 6. CJK fallback 策略

候选优先级建议为：

1. 用户选择的 family 能覆盖标题中的全部字符；
2. 用户选择的 family 覆盖 Latin、系统 CJK family 覆盖 CJK；
3. 现有 locale/variant CJK 栈；
4. 明确报错并使用项目已有的最终 fallback。

标题可能是混合 Latin/CJK，因此理想实现是按字符或 glyph run 分段绘制；如果第一
版仍按整段字体绘制，至少要在 UI 和文档中说明：含 CJK 的标题可能使用 fallback，
并测试不出现 tofu 方框。

## 数据和兼容性

- 不改变旧别名的含义。
- 现有数据库数据无需转换；旧值继续走旧解析路径。
- 新系统 family 作为字符串保存，因此换机器后可能不可用。
- 换机器后不应自动替换已保存字体；编辑页应显示不可用并要求用户重新选择。
- 如果未来需要跨机器可复现，再增加项目内字体文件/字体哈希方案；当前不做下载
  和打包字体。

## 测试计划

### 单元测试

- 发现结果按 family 去重；
- 排除 emoji、数学和不可加载文件；
- 选择一个已知 family 时返回真实存在的文件；
- 未安装 family 返回明确异常或验证错误；
- TTC 字体能解析到可加载 face；
- 旧语义值仍返回原来的字体栈；
- 含 CJK 文本进入 CJK fallback；
- 混合 Latin/CJK 不产生不可加载字体。

### Django 表单测试

- 新增真实系统 family 可以保存；
- 重新打开设计时该 family 仍是选中项；
- 失效历史 family 显示警告而不是静默替换；
- 所有共用字体字段接受相同的动态 family；
- 非法或伪造的 family 值被拒绝；
- 旧设计和旧 choices 全部继续通过。

### 渲染回归测试

至少覆盖：

- Latin title；
- 中文 title；
- Latin + 中文混合 title；
- front、back、spine 三个渲染路径；
- 普通 `.ttf` 和 `.otf`；
- `.ttc` 字体；
- 本机存在但运行时无法加载的字体。

## 分阶段执行与进度

### Phase 1：共享解析器（已完成）

- [x] 在 `bubble.cover.fonts` 增加发现、规范化、缓存和验证 API（`SystemFont`, `list_system_fonts`, `resolve_system_font`）；
- [x] 在 `web/coverdesigner/fonts` 提供向后兼容与 fallback 导入；
- [x] 为发现去重、特殊字符排除、别名和 CJK fallback 增加单元测试（`tests/test_cover_fonts.py` 全绿通过）。

### Phase 2：Title font 动态选择（已完成）

- [x] 扩大数据库字段长度为 `max_length=200`；
- [x] 增加并执行数据迁移 `0037` 与 `0038`；
- [x] 在 Title font 中加入动态系统 family 与 `<optgroup>`（Presets 与 System Fonts）；
- [x] 让 preview 和 full-cover 共用新的解析器；
- [x] 增加失效字体容错与降级。

### Phase 3：所有封面文字字段（已完成）

- [x] Subtitle、Author、Edition、Publisher、Back title、Blurb 和 Spine（共 12 个字体字段）统一接入 `FONT_FAMILY_CHOICES`；
- [x] 清理表单 choices 逻辑，保证无论从哪个入口编辑均能直接选择系统字体；
- [x] 增加自动化与全流程回归测试（Coverdesigner 45 项测试与 8 项单元测试全部通过）。

### Phase 4：体验和可复现性（演进中）

- 字体分类、搜索和刷新按钮；
- 显示实际解析文件和 CJK fallback 状态；
- 记录渲染日志；
- 评估是否需要项目级字体文件，但不默认下载或自动安装字体。

## 暂不做的事情

- 不从 PyPI 下载字体；
- 不自动安装系统字体；
- 不把所有 `fc-list` 结果无过滤地放进下拉框；
- 不把字体 family 名称传入 shell；
- 不把系统字体文件复制进项目；
- 不在第一版引入新的字体渲染库。

