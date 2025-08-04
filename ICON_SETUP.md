# 图标配置说明

## 配置概述

项目已配置 `flutter_launcher_icons` 插件，用于为所有平台生成应用图标。

## 配置详情

### 已配置的平台
- ✅ **Android**: 生成自适应图标
- ✅ **iOS**: 生成iOS应用图标
- ✅ **Web**: 生成Web应用图标
- ✅ **Windows**: 生成Windows应用图标
- ✅ **macOS**: 生成macOS应用图标
- ✅ **Linux**: 生成Linux应用图标

### 源图标
- 源文件: `ic_launcher.png` (根目录)
- 建议尺寸: 1024x1024 像素
- 格式: PNG (推荐) 或 JPG

## 使用步骤

### 1. 安装依赖
```bash
fvm flutter pub get
```

### 2. 生成所有平台图标
```bash
fvm flutter pub run flutter_launcher_icons:main
```

### 3. 验证生成结果
生成后，图标文件将出现在以下位置：

#### Android
- `android/app/src/main/res/mipmap-hdpi/launcher_icon.png`
- `android/app/src/main/res/mipmap-mdpi/launcher_icon.png`
- `android/app/src/main/res/mipmap-xhdpi/launcher_icon.png`
- `android/app/src/main/res/mipmap-xxhdpi/launcher_icon.png`
- `android/app/src/main/res/mipmap-xxxhdpi/launcher_icon.png`

#### iOS
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

#### Web
- `web/icons/`

#### Windows
- `windows/runner/resources/`

#### macOS
- `macos/Runner/Assets.xcassets/AppIcon.appiconset/`

#### Linux
- `linux/my_application.cc`

## 自定义配置

### 修改图标颜色
在 `pubspec.yaml` 中修改以下配置：

```yaml
flutter_launcher_icons:
  web:
    background_color: "#4CAF50"  # Android绿色
    theme_color: "#2196F3"       # Material蓝色
```

### 修改Android图标名称
```yaml
flutter_launcher_icons:
  android: "my_custom_icon_name"
```

### 调整Windows图标大小
```yaml
flutter_launcher_icons:
  windows:
    icon_size: 256  # 可选: 48, 64, 128, 256
```

## 故障排除

### 常见问题

1. **图标不显示**
   - 确保源图标文件存在且格式正确
   - 检查图标尺寸是否足够大（建议1024x1024）

2. **生成失败**
   - 运行 `fvm flutter clean`
   - 重新运行 `fvm flutter pub get`
   - 再次执行图标生成命令

3. **Android图标显示异常**
   - 检查 `android/app/src/main/AndroidManifest.xml` 中的图标引用
   - 确保图标名称与配置一致

### 调试命令
```bash
# 清理项目
fvm flutter clean

# 重新获取依赖
fvm flutter pub get

# 重新生成图标
fvm flutter pub run flutter_launcher_icons:main

# 验证配置
fvm flutter pub run flutter_launcher_icons:main --debug
```

## 最佳实践

1. **图标设计**
   - 使用简洁、易识别的设计
   - 确保在小尺寸下仍然清晰
   - 遵循各平台的设计规范

2. **文件管理**
   - 将源图标文件放在项目根目录
   - 使用版本控制管理图标文件
   - 定期更新图标以保持一致性

3. **测试验证**
   - 在不同平台测试图标显示效果
   - 检查各种尺寸下的清晰度
   - 验证图标在不同背景下的可见性

## 相关文档

- [flutter_launcher_icons 官方文档](https://pub.dev/packages/flutter_launcher_icons)
- [Android 自适应图标指南](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [iOS 应用图标指南](https://developer.apple.com/design/human-interface-guidelines/ios/icons-and-images/app-icon/)
- [Material Design 图标指南](https://material.io/design/iconography/system-icons.html) 