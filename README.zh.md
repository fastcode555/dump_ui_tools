# Android UI 分析工具

[English](README.md) | [中文](README.zh.md) | [Deutsch](README.de.md) | [한국어](README.ko.md) | [日本語](README.ja.md)

---

一个强大的Flutter桌面应用程序，用于分析来自XML转储文件的Android UI层次结构。此工具帮助开发人员理解UI结构、调试布局问题并加速UI自动化测试开发。

![应用截图](docs/images/app-screenshot.png)

## 功能特性

### 核心功能
- **🔍 UI层次结构可视化**: Android UI结构的交互式树形视图
- **🔎 高级搜索和过滤**: 通过文本、资源ID、类名或属性查找元素
- **📊 属性检查**: UI元素属性和边界的详细视图
- **🖼️ 视觉预览**: 带有元素高亮的缩放设备屏幕表示
- **📝 XML查看**: 语法高亮的XML显示，支持导出功能
- **📚 历史管理**: 访问和管理之前捕获的UI转储

### 主要优势
- 加速UI自动化测试开发
- 调试复杂的布局层次结构
- 理解无障碍结构
- 导出数据以供进一步分析
- 简化移动应用测试工作流程

## 快速开始

### 前置要求
- macOS 10.14或更高版本
- 启用USB调试的Android设备
- 安装ADB（Android调试桥）

### 安装
1. 从[发布页面](https://github.com/your-repo/releases)下载最新版本
2. 解压并移动到应用程序文件夹
3. 启动应用程序
4. 连接您的Android设备并开始分析！

### 基本使用
1. **连接设备**: 启用USB调试的Android设备
2. **捕获UI**: 点击"捕获UI"获取当前屏幕层次结构
3. **探索**: 使用树形视图、搜索和过滤器查找元素
4. **检查**: 点击元素查看详细属性
5. **导出**: 保存XML文件用于自动化脚本

## 文档

- **[用户指南](docs/USER_GUIDE.md)**: 完整的用户文档
- **[开发者指南](docs/DEVELOPER_GUIDE.md)**: 技术实现细节
- **[部署指南](docs/DEPLOYMENT_GUIDE.md)**: 构建和分发说明
- **[测试报告](docs/TEST_REPORT.md)**: 全面的测试验证

## 项目结构

```
lib/
├── main.dart                 # 应用程序入口点
├── controllers/              # 状态管理和业务逻辑
│   ├── ui_analyzer_state.dart
│   ├── search_controller.dart
│   └── filter_controller.dart
├── models/                   # 数据模型和实体
│   ├── ui_element.dart
│   ├── android_device.dart
│   └── filter_criteria.dart
├── services/                 # 外部服务集成
│   ├── adb_service.dart
│   ├── xml_parser.dart
│   ├── file_manager.dart
│   └── user_preferences.dart
├── ui/                       # 用户界面组件
│   ├── panels/              # 主UI面板
│   ├── widgets/             # 可重用组件
│   ├── dialogs/             # 模态对话框
│   └── themes/              # 主题配置
└── utils/                   # 实用函数和助手

test/                        # 全面的测试套件
docs/                        # 文档
```

## 开发

### 前置要求
- Flutter SDK 3.7.2+（推荐通过FVM管理）
- Dart SDK 2.19.0+
- macOS开发环境
- Xcode（用于macOS构建）

### 设置
```bash
# 克隆仓库
git clone <repository-url>
cd android-ui-analyzer

# 安装依赖
fvm flutter pub get

# 运行应用程序
fvm flutter run -d macos
```

### 开发命令
```bash
# 代码分析
fvm flutter analyze

# 运行测试
fvm flutter test

# 运行集成测试
fvm flutter test test/integration/

# 构建发布版本
fvm flutter build macos --release
```

### 测试
项目包含全面的测试：
- **单元测试**: 核心业务逻辑验证
- **集成测试**: 端到端功能验证
- **组件测试**: UI组件行为测试

运行测试套件：
```bash
# 所有测试
fvm flutter test

# 特定测试文件
fvm flutter test test/integration/final_integration_test.dart

# 带覆盖率
fvm flutter test --coverage
```

## 架构

### 清洁架构模式
- **UI层**: Flutter组件和面板
- **业务逻辑**: 控制器和状态管理
- **数据层**: 服务和仓库
- **外部**: ADB集成和文件系统

### 关键技术
- **Flutter**: 跨平台UI框架
- **Provider**: 状态管理
- **XML**: Android UI转储解析
- **ADB**: Android设备通信
- **Material Design 3**: 现代UI组件

## 贡献

我们欢迎贡献！请参阅我们的贡献指南：

1. Fork仓库
2. 创建功能分支
3. 进行更改并添加测试
4. 提交拉取请求

### 代码风格
- 遵循Dart风格指南
- 为公共API添加文档
- 为新功能包含测试
- 使用有意义的提交消息

## 性能

### 基准测试
- **XML解析**: 典型UI转储< 500ms
- **搜索**: < 100ms响应时间
- **内存使用**: 针对大型层次结构优化
- **UI响应性**: 60fps流畅交互

### 优化功能
- 大型树的懒加载
- 性能的虚拟滚动
- 防抖搜索防止延迟
- 高效内存管理

## 安全

### 数据保护
- 不传输敏感数据
- 仅本地文件处理
- 安全的临时文件处理
- 注重隐私的设计

### 最佳实践
- 输入验证和清理
- 安全的XML解析
- 适当的错误处理
- 资源清理

## 兼容性

### 支持的平台
- **主要**: macOS 10.14+
- **Android设备**: API 16+（Android 4.1+）
- **ADB版本**: 所有现代版本

### 测试配置
- 各种Android设备制造商
- 不同的屏幕尺寸和方向
- 复杂的UI层次结构和布局
- 多个Android版本

## 故障排除

### 常见问题
- **设备未检测到**: 检查USB调试和ADB安装
- **UI捕获失败**: 确保设备已解锁且应用有权限
- **性能问题**: 使用过滤器减少显示的元素

详细故障排除请参阅[用户指南](docs/USER_GUIDE.md)。

## 许可证

本项目采用MIT许可证 - 详情请参阅[LICENSE](LICENSE)文件。

## 致谢

- Flutter团队提供的优秀框架
- Android团队提供的UIAutomator工具
- 开源社区提供的依赖项
- 贡献者和测试者

## 支持

- **文档**: 查看docs/目录
- **问题**: 使用GitHub Issues报告错误
- **讨论**: GitHub Discussions提问
- **邮箱**: [support@example.com](mailto:support@example.com)

---

**为Android开发人员和测试人员精心制作 ❤️** 