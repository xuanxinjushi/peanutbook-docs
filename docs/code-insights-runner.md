# Interactive Python Runner & Code Insights Hub (代码教学与工程洞察中心)

Peanutbook includes a **built-in interactive Python execution engine and pedagogical Code Insights Hub** specifically tailored for technical books, quantitative finance treatises, and engineering documentation.

When authoring or reading technical literature containing executable code (such as mortgage pricing models, machine learning algorithms, or data pipelines), authors and readers no longer need to switch between an IDE, a terminal, and the book. Peanutbook transforms any `.py` script in the book project into an **interactive, pedagogical companion** that directly bridges executable algorithms with the book's manuscript text.

---

## 🌟 Overview & Key Pedagogical Capabilities

```mermaid
flowchart LR
    subgraph Input ["Source Python Script"]
        PY["🐍 .py Code File\n(e.g., amortization.py)"]
    end

    subgraph Engine ["Peanutbook AST & Runtime Analysis"]
        AST["🌳 AST Syntax Analyzer"]
        SCAN["🔍 Manuscript Citation Scanner"]
        RUN["⚡ Multi-Env Subprocess Runner"]
        GIT["🕒 Git History & LOC Metrics"]
    end

    subgraph Hub ["6-Tab Code Insights Hub"]
        T1["💻 1. Interactive Terminal"]
        T2["🐞 2. Interactive Debugger"]
        T3["📊 3. Dynamic Call Graph"]
        T4["📐 4. Outline & API Signatures"]
        T5["📖 5. Book Citations & Cross-Refs"]
        T6["🕒 6. Git Log & Quality Metrics"]
    end

    Input --> Engine
    Engine --> Hub
```

### Why Technical Publishing Demands Integrated Code Insights & In-Browser Debugging

| Dimension | Traditional Book Writing (Word / Static Markdown) | Peanutbook Code Insights & Debugger |
| :--- | :--- | :--- |
| **Code Executability** | Copy-pasted dead code; prone to silent bitrot | **Live in-browser execution** with 1-click run (`Ctrl+Shift+Enter`) and sub-second feedback |
| **Step-by-Step Debugging** | Requires external IDEs and complex path setups | **Built-in interactive debugger**: click gutters for breakpoints (`🔴`), step over/into/out, and live frame inspection |
| **Environment Control** | Ambiguous external setups and library mismatches | **Multi-interpreter selector**: auto-detects Conda envs (e.g. `usao`), system Python, or book-specific venvs |
| **Architectural Clarity** | Readers struggle to trace complex caller-callee trees | **Interactive Call Graph**: visualizes `__main__` entrypoints and inter-function calls via Mermaid |
| **Text-Code Alignment** | Authors forget which chapters reference which functions | **Bidirectional Citation Tracker**: automatically finds all chapters referencing the script or functions |
| **Pedagogical Navigation** | Endless scrolling through hundreds of lines of code | **One-click jump**: clicking any graph node, API card, stack frame, or citation jumps directly to the source code line |

---

## 🚀 The 6-Tab Code Insights & Debugging Hub

When any Python script (`.py`) is opened in the Peanutbook Workspace, the right preview pane automatically switches from standard PDF/Live view to the **Code Insights & Debugger Hub**.

---

### 1. 💻 Interactive Terminal (`Terminal`)

The interactive terminal provides zero-friction execution directly against the configured Python environment on the host or development container.

![Interactive Terminal & Execution Console](img/code-insight-1-terminal.png)

#### Highlights:
* **One-Click Execution**: Click `▶ Run Python` in the top action bar or press `Ctrl+Shift+Enter`.
* **Execution Status & Telemetry**: Displays exit code badges (`Exit 0` in emerald, nonzero in crimson) and elapsed execution time in milliseconds.
* **Interpreter Dropdown**: Seamlessly switch between Conda environments (such as `usao`), the project virtual environment, or system Python.
* **Matplotlib Figure Detection**: Scripts that output or save `.png`/`.jpg` figures have their visuals automatically captured and embedded beneath the console logs.

![Python Interpreter Dropdown](img/code-runner-interpreter-menu.png)

---

### 2. 🐞 In-Browser Interactive Debugger (`Debugger`)

The Interactive Debugger brings a full-featured, zero-dependency, VS Code-style debugging experience directly inside the browser workspace. Authors can inspect algorithms step by step, verify calculations, and explore internal state without leaving the manuscript.

| Paused at Breakpoint (Dark Theme) | Stepping Execution (Light Theme) |
| :---: | :---: |
| ![Python Debugger Paused at Breakpoint](img/code-debugger-paused-dark.png) | ![Python Debugger Stepping Execution](img/code-debugger-paused-light.png) |

#### Highlights:
* **Gutter Breakpoint Setting**: Click any line number in the editor gutter to toggle red dot breakpoints (`🔴`). Breakpoints are visually rendered, remembered across sessions, and dynamically synchronized with the runner.
* **VS Code-Style Floating Debug Toolbar**:
  * `▶ Continue` (`F5`): Resume execution until the next breakpoint or completion.
  * `↷ Next / Step Over` (`F10`): Step over to the next source line in the current function.
  * `⇊ Step / Step Into` (`F11`): Step into function calls.
  * `⇈ Return / Step Out` (`Shift+F11`): Run until the current function returns.
  * `⏹ Stop` (`Shift+F5`): Terminate the debug session cleanly.
* **Active Line Pointer & Highlight**: The currently paused line is highlighted with an amber accent bar in the editor and marked with a bright yellow pointer (`▶`) in the gutter.
* **4-Card Diagnostics Layout**:
  1. **📦 Variables (Locals & Scope)**: Displays all variables in the active stack frame with type badges (e.g. `float`, `int`, `list`) and exact string representations.
  2. **📚 Call Stack**: Visualizes stack frames (e.g. `mortgage_balance` &rarr; `<module>`). Clicking any frame jumps the editor directly to that execution point.
  3. **🔴 Active Breakpoints**: Lists all registered breakpoints with file and line coordinates, 1-click editor jumping, and instant deletion (`✕`).
  4. **💬 Interactive Debug Console & REPL**: Evaluate arbitrary Python expressions within the paused frame's live context (e.g. evaluate `balance * i` to inspect intermediate monthly interest).

![Interactive Debug Console & REPL](img/code-debugger-repl-eval.png)

---

### 3. 📊 Dynamic Call Graph (`Call Graph`)

The Call Graph tab employs Python's standard `ast` (Abstract Syntax Tree) module to statically extract the structure of the script: entrypoint blocks (`if __name__ == '__main__':`), function definitions, and caller-callee relationships.

| Dark Theme Call Graph | Light Theme Call Graph |
| :---: | :---: |
| ![Call Graph Dark Theme](img/code-insight-2-callgraph-dark.png) | ![Call Graph Light Theme](img/code-insight-2-callgraph-light.png) |

![Call Graph Zoomed In View](img/code-insight-2-callgraph-zoomed.png)

#### Highlights:
* **Interactive Zoom & Pan Engine**:
  * **Zoom In & Out (`+` / `−`)**: Magnify from 25% up to 400% with live percentage indicator.
  * **Mouse Wheel Zoom**: Smooth cursor-centered zooming using the mouse wheel or trackpad pinch gesture.
  * **Click & Drag Pan**: Freely pan the graph across the infinite canvas with grab/grabbing feedback.
  * **Fit & 1:1 Reset**: Click `Fit` to auto-scale the entire call graph to the viewport, or `1:1` to reset to native 100% scale.
* **Mermaid Vector Flowchart**: Automatically compiled and rendered as crisp, vector graphics with publication-grade node palettes.
* **Interactive Code Jumping**: Every function node in the SVG diagram is interactive. Clicking on a node (such as `mortgage_balance`) instantly focuses CodeMirror and navigates the cursor to the exact line of the function definition (pan dragging is intelligently distinguished from clicks).
* **Theme-Aware Styling**: Perfectly harmonized with both Dark and Light themes.

---

### 4. 📐 Outline & API Signatures (`Outline & API`)

The Outline tab serves as an interactive table of contents for classes and functions within the script.

![Outline and API Documentation Cards](img/code-insight-3-outline.png)

#### Highlights:
* **Type Annotations & Arguments**: Extracts complete parameter signatures including type hints (e.g. `(balances: list[float], rates: list[float]) -> float`).
* **Docstring Rendering**: Parses and structures function docstrings into readable pedagogical descriptions.
* **Line Number Badges**: Displays start-to-end line pills (e.g. `L22-27`). Clicking any card or badge jumps the editor directly to that block.

---

### 5. 📖 Book Citations & Manuscript Cross-Referencing (`Book Citations`)

Technical books often reference scripts and functions across multiple chapters. The Book Citations tab performs an indexed full-text scan of all Markdown chapters in the book repository to pinpoint every occurrence.

![Book Chapters Citing Code](img/code-insight-4-citations.png)

#### Highlights:
* **Multi-Chapter Indexing**: Tracks mentions of the script filename (e.g. `amortization.py`) as well as individual function and class names across all book chapters.
* **Automatic Exclusion of Merged Book Artifacts**: Intelligently ignores generated whole-book files matching `book*.md` (e.g. `book.md`, `book_zh.md` created by `bubble-merge`), ensuring citations accurately point to individual authoring chapters instead of duplicate monolithic build artifacts.
* **Contextual Snippets**: Displays the exact line number in the target chapter and a contextual snippet of the surrounding paragraph or code block.
* **Click-to-Traverse**: Clicking any citation card immediately opens that chapter in the editor, providing a seamless bidirectional link between code and theory.

---

### 6. 🕒 Git History & Quality Metrics (`Git & Metrics`)

The Git & Metrics tab provides instant visibility into the script's software engineering health and revision history.

![Git History and Code Metrics](img/code-insight-5-gitmetrics.png)

#### Highlights:
* **Metric Stat Cards**:
  * **Total Lines**: Overall length of the file.
  * **Code LOC**: Pure logic lines excluding blank lines and comments.
  * **Comments**: Documented line count.
  * **Functions**: Total number of top-level and helper functions.
  * **Imports**: Number of module dependencies imported.
* **Recent Git Commits**: Displays the recent commit log for the specific file, including commit hash, commit message, author name, and relative timestamp.

---

## ⌨️ Productivity Keyboard Shortcuts

| Shortcut | Context | Action |
| :--- | :--- | :--- |
| `Ctrl+Shift+Enter` (or `Cmd+Shift+Enter`) | Python file open | **Run script** immediately in the interactive terminal |
| `F5` | Python file open | **Start Debugger** / **Continue** to next breakpoint |
| `F10` | Debugger paused | **Step Over (Next)** to next line in current function |
| `F11` | Debugger paused | **Step Into** function call |
| `Shift+F11` | Debugger paused | **Step Out (Return)** until current function returns |
| `Shift+F5` | Debugger active | **Stop Debugging** session |
| `Click on Gutter Line Number` | Python file open | **Toggle Breakpoint (`🔴`)** on clicked line |
| `Ctrl+S` (or `Cmd+S`) | Workspace editor | Save file changes and refresh live diagnostics |
| `Ctrl+F` (or `Cmd+F`) | Workspace editor | Open in-editor search bar |
| `Click on Call Graph Node` | Call Graph tab | Navigate editor directly to function definition line |
| `Click on Stack Frame` | Debugger tab | Navigate editor directly to paused frame line |
| `Click on API Card Badge` | Outline tab | Navigate editor directly to function / class line |
| `Click on Citation Card` | Citations tab | Open the citing chapter file in the workspace |

---

## 🛠️ Backend API Endpoints

For developers and plugin integrators, Peanutbook exposes dedicated JSON endpoints for Python analysis, debugging, and execution:

### 1. Execute Script
* **Endpoint**: `POST /books/<book>/python/run/`
* **Payload**: `{"path": "chapter1/code/amortization.py", "python": "usao"}`
* **Response**:
  ```json
  {
    "ok": true,
    "exit_code": 0,
    "stdout": "...",
    "stderr": "",
    "seconds": 1.44,
    "python": "/home/wukong/miniconda3/envs/usao/bin/python",
    "images": []
  }
  ```

### 2. Extract Insights & Call Graph
* **Endpoint**: `GET /books/<book>/python/insights/?path=chapter1/code/amortization.py`
* **Response**:
  ```json
  {
    "ok": true,
    "filename": "amortization.py",
    "metrics": {
      "total_lines": 150,
      "code_lines": 104,
      "comment_lines": 12,
      "functions_count": 8,
      "imports_count": 0
    },
    "functions": [...],
    "classes": [...],
    "mermaid_graph": "flowchart LR ...",
    "citations": [
      {
        "file": "book.md",
        "line": 690,
        "term": "amortization.py",
        "snippet": "...in code/amortization.py..."
      }
    ],
    "git_log": [...]
  }
  ```

### 3. Interactive Debugger Sessions
* **Start Session**: `POST /books/<book>/python/debug/start/`
  * **Payload**: `{"path": "chapter1/code/amortization.py", "breakpoints": [16], "stop_on_entry": 0}`
  * **Response**: `{"ok": true, "session_id": "...", "state": {"event": "paused", "line": 16, "func": "mortgage_balance", "locals": {...}, "stack": [...]}}`
* **Step / Action**: `POST /books/<book>/python/debug/step/`
  * **Payload**: `{"session_id": "...", "action": "next"}` (Actions: `continue`, `next`, `step`, `return`, `stop`, `set_break`, `clear_break`)
  * **Response**: `{"ok": true, "session_id": "...", "state": {"event": "paused", "line": 17, ...}}`
* **REPL Evaluation**: `POST /books/<book>/python/debug/eval/`
  * **Payload**: `{"session_id": "...", "expr": "balance * i"}`
  * **Response**: `{"ok": true, "result": {"event": "eval_result", "ok": true, "result": "2166.67", "type": "float"}}`
* **Stop Session**: `POST /books/<book>/python/debug/stop/`
  * **Payload**: `{"session_id": "..."}`
  * **Response**: `{"ok": true}`

