# Android UI 分析工具集

这个工具集用于分析Android应用的UI结构，特别是为了开发无障碍服务而设计。

## 文件说明

- `start_ths.sh` - 启动同花顺应用
- `dump_ui.sh` - 获取当前屏幕的UI布局
- `ui_analyzer.py` - UI结构分析工具
- `analyze_ths.sh` - 同花顺完整分析流程
- `dumps/` - 布局文件备份目录

## 使用方法

### 方法1: 完整分析流程（推荐）

```bash
./analyze_ths.sh
```

这个脚本会：
1. 启动同花顺应用
2. 等待你手动导航到目标页面
3. 获取UI布局
4. 启动分析工具

### 方法2: 分步操作

1. **启动同花顺**：
   ```bash
   ./start_ths.sh
   ```

2. **手动导航到目标页面**（如交易页面）

3. **获取UI布局**：
   ```bash
   ./dump_ui.sh
   ```

4. **分析UI结构**：
   ```bash
   python3 ui_analyzer.py
   ```

## UI分析工具功能

启动 `ui_analyzer.py` 后，你可以：

1. **显示所有元素** - 查看页面上所有UI元素
2. **按文本搜索** - 搜索包含特定文本的元素
3. **显示可点击元素** - 只显示可以点击的元素
4. **显示输入框** - 只显示输入框元素
5. **重新获取UI** - 刷新UI结构

## 同花顺交易流程分析

建议按以下顺序分析同花顺的交易流程：

1. **主页面** - 搜索"交易"按钮
2. **交易页面** - 搜索"条件单"按钮
3. **条件单页面** - 搜索"新建条件单"按钮
4. **新建页面** - 搜索"股价条件"按钮
5. **股价条件页面** - 搜索输入框和"000001"

## 注意事项

1. 确保Android设备已连接并启用USB调试
2. 确保已安装同花顺应用
3. 每次获取UI布局时，确保目标页面已完全加载
4. 布局文件会自动备份到 `dumps/` 目录

## 输出文件

- `window_dump.xml` - 当前UI布局文件
- `dumps/window_dump_YYYYMMDD_HHMMSS.xml` - 带时间戳的备份文件

## 故障排除

如果遇到问题：

1. 检查设备连接：`adb devices`
2. 检查应用是否安装：`adb shell pm list packages | grep hexin`
3. 手动获取UI：`adb shell uiautomator dump && adb pull /sdcard/window_dump.xml`