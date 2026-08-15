# PDF保护功能使用指南

本指南说明如何使用PDF保护功能来防止文本复制和OCR识别。

## 功能说明

PDF保护功能通过以下方式保护PDF：

1. **防止直接复制文本**：将PDF页面转换为图像，文本不再是可选择的文本层
2. **防止OCR识别**：可以添加噪声和干扰模式，使OCR工具难以识别

## 快速开始

### 基本保护（转换为图像）

```bash
# 单个章节
bubble-convert 11 --protect

# 所有章节
bubble-convert --protect
```

### 高级保护（添加噪声和干扰模式）

```bash
# 添加噪声
bubble-convert 11 --protect --protect-noise

# 添加干扰模式
bubble-convert 11 --protect --protect-pattern

# 最大保护（噪声+干扰模式）
bubble-convert 11 --protect --protect-noise --protect-pattern
```

### 高质量保护

```bash
# 使用更高DPI（更清晰但文件更大）
bubble-convert 11 --protect --protect-dpi 400
```

## 选项说明

### 保护选项

- `--protect`: 启用PDF保护（将文本转换为图像）
- `--protect-dpi DPI`: 设置图像DPI（默认：300，越高质量越好但文件越大）
- `--protect-noise`: 添加细微噪声使OCR更困难
- `--protect-pattern`: 添加反OCR干扰模式（细微线条）

### 性能优化选项（高级）

- `--protect-batch-size N`: 每批处理的页数（默认：自动检测）
- `--protect-max-batches N`: 最大并发批次数（默认：自动检测）
- `--protect-workers N`: 图像处理worker数量（默认：自动检测）
- `--protect-pdf-threads N`: PDF转图像时的线程数（默认：自动检测）

**建议**：大多数情况下使用默认自动检测即可，脚本会根据你的系统自动优化。

## 使用示例

### 示例1：基本保护
```bash
bubble-convert 1 --protect
```
- 将PDF转换为图像
- 防止直接复制文本
- 文件大小会增加（因为图像比文本大）

### 示例2：高质量保护
```bash
bubble-convert 1 --protect --protect-dpi 400
```
- 使用400 DPI（更清晰）
- 适合需要高质量输出的情况
- 文件会更大

### 示例3：最大保护
```bash
bubble-convert 1 --protect --protect-noise --protect-pattern
```
- 转换为图像
- 添加噪声干扰
- 添加干扰模式
- 最大程度防止OCR

### 示例4：保护+水印
```bash
bubble-convert 1 --protect --watermark "DRAFT"
```
- 同时应用保护和水印
- 双重保护

## 系统要求

PDF保护功能需要以下依赖：

```bash
# Python包
pip install pdf2image pillow reportlab numpy

# 系统依赖（poppler-utils）
sudo apt-get install poppler-utils
```

## 工作原理

1. **PDF转图像**：使用`pdf2image`将PDF每一页转换为高分辨率图像
2. **图像处理**（可选）：
   - 添加噪声：在图像上添加随机噪声
   - 添加干扰模式：添加细微的线条模式
3. **图像转PDF**：将处理后的图像重新组合成PDF

## 性能影响

- **处理时间**：每页约1-3秒（取决于DPI和页面复杂度）
  - **批次并行处理**：脚本自动检测系统资源，使用批次并行处理，充分利用多核CPU
  - **自动优化**：根据CPU核心数和内存自动配置批次大小和并发数
  - 可以通过 `--protect-batch-size` 和 `--protect-max-batches` 手动调整
- **内存使用**：
  - **自动控制**：通过批次处理控制内存使用，避免一次性加载所有页面
  - **32核系统**：从45GB+降低到4-8GB（约80-90%的内存节省）
  - **智能分配**：根据系统内存自动计算最优批次大小
- **文件大小**：会增加2-5倍（因为图像比文本大）
- **质量**：使用300 DPI时，视觉质量与原始PDF几乎相同

## 自动检测和优化

PDF保护脚本现在支持**自动检测系统资源**并优化配置：

### 自动检测功能

- **CPU核心数**：自动检测并使用60-75%的可用核心
- **内存大小**：自动检测系统总内存并计算最优批次大小
- **批次处理**：自动将PDF页面分成批次并行处理
- **内存控制**：限制内存使用，防止系统过载

### 自动配置示例

```bash
# 完全自动（推荐）- 脚本会自动检测并优化
bubble-build --protect

# 对于32核系统，脚本会自动：
# - 使用约24个并发批次（75%的CPU核心）
# - 批次大小：10-30页/批次
# - 预估内存：4-8GB（而不是45GB+）
```

### 系统资源检测

脚本会自动显示检测到的系统资源：

```
🖥️  System resources detected:
   CPU cores: 32
   Total memory: 64.0 GB
   Auto-configured: batch_size=20, max_concurrent_batches=24
```

### 不同系统的自动配置

**32+核 + 64+GB内存**：
- 批次大小：10-30页
- 并发批次：最多24个（使用75%的CPU核心）
- 每批内存：最多2GB

**16+核 + 32+GB内存**：
- 批次大小：8-25页
- 并发批次：最多22个（使用70%的CPU核心）
- 每批内存：最多1.5GB

**其他系统**：
- 根据CPU和内存自动调整

## 并行处理

PDF保护脚本使用**批次并行处理**，可以显著加速处理并控制内存使用：

```bash
# 使用自动检测（推荐）
bubble-build --protect

# 手动指定批次大小和并发数
bubble-build --protect --protect-batch-size 20 --protect-max-batches 24

# 直接使用脚本
python3 scripts/protect_pdf.py input.pdf output.pdf
```

### 批次处理优势

- **内存控制**：分批处理避免一次性加载所有页面
- **并行加速**：多个批次同时处理，充分利用多核CPU
- **动态调整**：根据系统资源自动优化配置

**性能提升**：
- 串行处理：100页约需5-10分钟，内存45GB+
- 批次并行处理（24 workers）：100页约需1-2分钟，内存4-8GB
- 加速比：约4-5倍（取决于CPU核心数）
- 内存节省：约80-90%（通过批次处理）

## 注意事项

⚠️ **重要提示**：

1. **文件大小**：保护后的PDF文件会显著增大（因为图像比文本大）
2. **处理时间**：保护过程需要额外时间，特别是大文件
3. **质量平衡**：DPI越高质量越好，但文件也越大
4. **不可逆**：保护后的PDF无法恢复为可编辑文本
5. **建议**：保留原始PDF作为备份

## 最佳实践

1. **开发阶段**：不使用保护，保持文件小且处理快
2. **发布阶段**：使用保护，防止未授权复制
3. **DPI选择**：
   - 300 DPI：平衡质量和大小（推荐）
   - 400+ DPI：高质量输出（文件较大）
   - 200 DPI：文件较小但可能影响清晰度

## 与单独脚本使用

你也可以直接使用保护脚本：

```bash
# 保护已生成的PDF
python3 scripts/protect_pdf.py input.pdf output.pdf

# 带选项
python3 scripts/protect_pdf.py input.pdf output.pdf \
  --dpi 300 --noise --pattern
```

## 常见问题

**Q: 保护后文件太大怎么办？**
A: 降低DPI（如使用`--protect-dpi 250`）或只保护关键章节

**Q: 保护会影响打印质量吗？**
A: 使用300+ DPI时，打印质量与原始PDF相同

**Q: 可以同时使用水印和保护吗？**
A: 可以，两者可以同时使用，提供双重保护

**Q: 保护是100%安全的吗？**
A: 没有绝对安全，但可以显著增加复制和OCR的难度

**Q: 自动检测是如何工作的？**
A: 脚本会自动检测CPU核心数和系统内存，然后计算最优的批次大小和并发批次数。对于32核系统，会自动使用约24个并发批次，显著提升处理速度并控制内存使用。

**Q: 我可以覆盖自动检测的配置吗？**
A: 可以，使用 `--protect-batch-size` 和 `--protect-max-batches` 参数可以手动指定配置。但建议先使用自动检测，通常已经是最优配置。

**Q: 为什么内存使用从45GB降到了4-8GB？**
A: 通过批次处理，不再一次性加载所有PDF页面到内存。而是分批处理，每批处理完成后释放内存，从而大幅降低峰值内存使用。
