# Requirements Document

## Introduction

基于现有Python UI分析工具，开发一个功能强大的Flutter版Mac应用，用于分析Android设备的UI层次结构。该工具将通过ADB和UIAutomator获取Android应用的UI布局信息，并提供直观的可视化界面，支持层次查看、搜索、过滤等功能，帮助开发者更高效地进行UI自动化测试和无障碍服务开发。

## Requirements

### Requirement 1

**User Story:** 作为一个Android开发者，我希望能够连接到Android设备并获取当前屏幕的UI层次结构，以便分析应用的界面布局。

#### Acceptance Criteria

1. WHEN 用户启动应用 THEN 系统 SHALL 自动检测已连接的Android设备
2. WHEN 用户点击"获取UI结构"按钮 THEN 系统 SHALL 通过ADB执行uiautomator dump命令
3. WHEN UI dump成功获取 THEN 系统 SHALL 解析XML文件并显示层次结构
4. IF 设备未连接或ADB命令失败 THEN 系统 SHALL 显示错误信息和解决建议
5. WHEN 获取UI结构完成 THEN 系统 SHALL 自动备份XML文件到dumps目录

### Requirement 2

**User Story:** 作为一个UI测试工程师，我希望能够以树形结构查看UI层次，并支持展开/收缩节点，以便清晰地理解界面的组织结构。

#### Acceptance Criteria

1. WHEN UI数据加载完成 THEN 系统 SHALL 在左侧面板显示树形层次结构
2. WHEN 用户点击节点展开/收缩图标 THEN 系统 SHALL 切换该节点的展开状态
3. WHEN 节点展开 THEN 系统 SHALL 显示所有子节点
4. WHEN 节点收缩 THEN 系统 SHALL 隐藏所有子节点
5. WHEN 用户点击节点 THEN 系统 SHALL 高亮显示该节点并在右侧显示详细属性
6. WHEN 节点有文本内容 THEN 系统 SHALL 在节点标签中显示文本预览

### Requirement 3

**User Story:** 作为一个自动化测试开发者，我希望能够搜索和过滤UI元素，以便快速找到目标控件。

#### Acceptance Criteria

1. WHEN 用户在搜索框输入文本 THEN 系统 SHALL 实时过滤匹配的节点
2. WHEN 搜索匹配成功 THEN 系统 SHALL 高亮显示匹配的节点并自动展开路径
3. WHEN 用户选择"仅显示可点击元素" THEN 系统 SHALL 只显示clickable为true的节点
4. WHEN 用户选择"仅显示输入框" THEN 系统 SHALL 只显示EditText类型的节点
5. WHEN 用户选择"仅显示有文本元素" THEN 系统 SHALL 只显示包含text或content-desc的节点
6. WHEN 用户清空搜索条件 THEN 系统 SHALL 恢复显示所有节点

### Requirement 4

**User Story:** 作为一个开发者，我希望能够查看UI元素的详细属性信息，以便了解控件的具体配置。

#### Acceptance Criteria

1. WHEN 用户选择一个UI节点 THEN 系统 SHALL 在右侧属性面板显示完整属性信息
2. WHEN 显示属性信息 THEN 系统 SHALL 包含text、content-desc、class、resource-id、bounds等关键属性
3. WHEN 属性值较长 THEN 系统 SHALL 支持文本换行和滚动显示
4. WHEN 用户点击属性值 THEN 系统 SHALL 支持复制属性值到剪贴板
5. WHEN 节点有bounds属性 THEN 系统 SHALL 解析并显示坐标和尺寸信息

### Requirement 5

**User Story:** 作为一个测试工程师，我希望能够可视化显示UI元素在屏幕上的位置，以便直观地理解布局关系。

#### Acceptance Criteria

1. WHEN 用户选择一个UI节点 THEN 系统 SHALL 在屏幕预览区域高亮显示该元素的位置
2. WHEN 显示屏幕预览 THEN 系统 SHALL 根据设备分辨率按比例缩放显示
3. WHEN 用户悬停在树节点上 THEN 系统 SHALL 在预览区域临时高亮对应位置
4. WHEN 多个元素重叠 THEN 系统 SHALL 使用不同颜色或透明度区分显示
5. WHEN 用户点击预览区域 THEN 系统 SHALL 选中对应位置的UI元素

### Requirement 6

**User Story:** 作为一个开发者，我希望能够管理和查看历史UI dump文件，以便对比不同时间点的界面变化。

#### Acceptance Criteria

1. WHEN 系统获取新的UI dump THEN 系统 SHALL 自动保存带时间戳的备份文件
2. WHEN 用户打开历史记录面板 THEN 系统 SHALL 显示所有历史dump文件列表
3. WHEN 用户选择历史文件 THEN 系统 SHALL 加载并显示该文件的UI结构
4. WHEN 用户删除历史文件 THEN 系统 SHALL 从文件系统中移除对应文件
5. WHEN 历史文件过多 THEN 系统 SHALL 支持按日期范围过滤和搜索

### Requirement 7

**User Story:** 作为一个用户，我希望应用界面美观易用，支持主题切换和布局调整，以便获得良好的使用体验。

#### Acceptance Criteria

1. WHEN 用户启动应用 THEN 系统 SHALL 显示现代化的Material Design界面
2. WHEN 用户切换主题 THEN 系统 SHALL 支持明暗主题切换
3. WHEN 用户调整面板大小 THEN 系统 SHALL 支持拖拽调整左右面板宽度
4. WHEN 窗口大小改变 THEN 系统 SHALL 自适应调整布局
5. WHEN 用户进行操作 THEN 系统 SHALL 提供适当的加载指示和反馈信息

### Requirement 8

**User Story:** 作为一个开发者，我希望能够查看和导出原始XML文件，并且XML内容能够语法高亮显示，以便更好地理解和分析UI结构。

#### Acceptance Criteria

1. WHEN 用户点击"查看XML"按钮 THEN 系统 SHALL 在新面板中显示原始XML内容
2. WHEN 显示XML内容 THEN 系统 SHALL 使用语法高亮显示XML标签、属性名和属性值
3. WHEN 显示XML属性 THEN 系统 SHALL 对属性值（如text="签到"中的"签到"）进行特殊高亮
4. WHEN 用户选择XML文本 THEN 系统 SHALL 支持复制选中的XML内容
5. WHEN 用户点击导出按钮 THEN 系统 SHALL 保存当前XML文件到指定位置
6. WHEN 导出完成 THEN 系统 SHALL 显示成功提示并打开文件保存位置