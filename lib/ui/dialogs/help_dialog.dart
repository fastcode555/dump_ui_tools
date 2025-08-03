import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive help dialog for the UI Analyzer application
class HelpDialog extends StatefulWidget {
  const HelpDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HelpDialog(),
    );
  }

  @override
  State<HelpDialog> createState() => _HelpDialogState();
}

class _HelpDialogState extends State<HelpDialog> with TickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Android UI Analyzer 帮助',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '快速开始', icon: Icon(Icons.play_arrow)),
                Tab(text: 'ADB设置', icon: Icon(Icons.settings)),
                Tab(text: '功能介绍', icon: Icon(Icons.featured_play_list)),
                Tab(text: '快捷键', icon: Icon(Icons.keyboard)),
              ],
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuickStartTab(),
                  _buildADBSetupTab(),
                  _buildFeaturesTab(),
                  _buildShortcutsTab(),
                ],
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '如需更多帮助，请查看项目文档或联系技术支持',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('关闭'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('欢迎使用 Android UI Analyzer'),
          const SizedBox(height: 16),
          
          _buildStepCard(
            1,
            '连接Android设备',
            '使用USB线缆连接您的Android设备到电脑，并确保已启用USB调试。',
            Icons.smartphone,
            [
              '在设备上启用开发者选项',
              '打开USB调试功能',
              '连接USB线缆',
              '在设备上允许调试授权',
            ],
          ),
          
          _buildStepCard(
            2,
            '选择设备',
            '在应用顶部的设备下拉菜单中选择您要分析的设备。',
            Icons.devices,
            [
              '点击设备选择下拉菜单',
              '选择已连接的设备',
              '确认设备状态显示为"Connected"',
            ],
          ),
          
          _buildStepCard(
            3,
            '获取UI结构',
            '点击"Capture UI"按钮获取当前屏幕的UI层次结构。',
            Icons.screenshot_monitor,
            [
              '确保设备屏幕显示要分析的界面',
              '点击"Capture UI"按钮',
              '等待获取过程完成',
            ],
          ),
          
          _buildStepCard(
            4,
            '分析UI结构',
            '使用左侧的树形视图浏览UI层次，右侧查看元素属性和屏幕预览。',
            Icons.account_tree,
            [
              '在左侧树形视图中浏览UI元素',
              '点击元素查看详细属性',
              '使用搜索和过滤功能快速定位元素',
              '在右下角预览区域查看元素位置',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildADBSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('ADB (Android Debug Bridge) 设置'),
          const SizedBox(height: 16),
          
          _buildInfoCard(
            '什么是ADB？',
            'ADB是Android SDK中的一个命令行工具，用于与Android设备进行通信。本应用需要ADB来获取设备的UI层次结构。',
            Icons.info,
            Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionTitle('安装ADB'),
          const SizedBox(height: 8),
          
          _buildInstallationStep(
            'macOS (推荐方法)',
            [
              '使用Homebrew安装: brew install android-platform-tools',
              '或下载Android SDK Platform Tools',
              '将ADB路径添加到系统PATH环境变量',
            ],
            'brew install android-platform-tools',
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionTitle('启用USB调试'),
          const SizedBox(height: 8),
          
          _buildTroubleshootingCard(
            '在Android设备上启用USB调试',
            [
              '打开"设置" > "关于手机"',
              '连续点击"版本号"7次启用开发者选项',
              '返回设置，进入"开发者选项"',
              '启用"USB调试"选项',
              '连接USB线缆时选择"允许USB调试"',
            ],
            Icons.developer_mode,
          ),
          
          const SizedBox(height: 16),
          
          _buildSectionTitle('常见问题解决'),
          const SizedBox(height: 8),
          
          _buildTroubleshootingCard(
            '设备未显示在列表中',
            [
              '检查USB线缆连接是否牢固',
              '尝试不同的USB端口',
              '确认设备已启用USB调试',
              '在设备上重新授权USB调试',
              '重启ADB服务: adb kill-server && adb start-server',
            ],
            Icons.warning,
          ),
          
          _buildTroubleshootingCard(
            'UI获取失败',
            [
              '确保设备屏幕处于活动状态',
              '检查设备是否有屏幕锁定',
              '尝试在不同的应用界面获取UI',
              '重新连接设备',
            ],
            Icons.error,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('功能介绍'),
          const SizedBox(height: 16),
          
          _buildFeatureCard(
            '树形视图',
            '以层次结构显示UI元素，支持展开/收缩节点，快速浏览界面组织结构。',
            Icons.account_tree,
            [
              '点击节点前的箭头展开/收缩',
              '点击节点名称选择元素',
              '支持虚拟滚动处理大量元素',
            ],
          ),
          
          _buildFeatureCard(
            '搜索和过滤',
            '快速定位目标UI元素，支持多种过滤条件。',
            Icons.search,
            [
              '实时文本搜索',
              '过滤可点击元素',
              '过滤输入框元素',
              '过滤包含文本的元素',
            ],
          ),
          
          _buildFeatureCard(
            '属性查看',
            '查看UI元素的详细属性信息，支持复制属性值。',
            Icons.info,
            [
              '显示所有元素属性',
              '点击属性值复制到剪贴板',
              '解析bounds坐标信息',
              '支持长文本换行显示',
            ],
          ),
          
          _buildFeatureCard(
            '屏幕预览',
            '可视化显示UI元素在屏幕上的位置和大小。',
            Icons.preview,
            [
              '按比例显示设备屏幕',
              '高亮显示选中元素',
              '支持缩放和平移',
              '点击预览区域选择元素',
            ],
          ),
          
          _buildFeatureCard(
            'XML查看',
            '查看和导出原始XML文件，支持语法高亮。',
            Icons.code,
            [
              'XML语法高亮显示',
              '选择和复制XML内容',
              '导出XML文件',
              '折叠面板设计',
            ],
          ),
          
          _buildFeatureCard(
            '历史记录',
            '管理和查看历史UI dump文件。',
            Icons.history,
            [
              '自动保存每次获取的UI结构',
              '按时间戳组织文件',
              '快速加载历史记录',
              '支持删除和清理',
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('键盘快捷键'),
          const SizedBox(height: 16),
          
          _buildShortcutSection(
            '通用操作',
            [
              ShortcutInfo('Cmd+R', '刷新设备列表'),
              ShortcutInfo('Cmd+U', '获取UI结构'),
              ShortcutInfo('Cmd+F', '聚焦搜索框'),
              ShortcutInfo('Cmd+H', '显示/隐藏历史面板'),
              ShortcutInfo('Cmd+X', '显示/隐藏XML面板'),
              ShortcutInfo('Cmd+,', '打开设置'),
              ShortcutInfo('Cmd+Shift+?', '显示帮助'),
            ],
          ),
          
          _buildShortcutSection(
            '导航操作',
            [
              ShortcutInfo('↑/↓', '在树形视图中上下移动'),
              ShortcutInfo('←/→', '展开/收缩树节点'),
              ShortcutInfo('Enter', '选择当前节点'),
              ShortcutInfo('Esc', '清除选择'),
            ],
          ),
          
          _buildShortcutSection(
            '视图操作',
            [
              ShortcutInfo('Cmd+T', '切换主题'),
              ShortcutInfo('Cmd+P', '显示/隐藏预览面板'),
              ShortcutInfo('Cmd++', '放大预览'),
              ShortcutInfo('Cmd+-', '缩小预览'),
              ShortcutInfo('Cmd+0', '重置预览缩放'),
              ShortcutInfo('Cmd+Shift+R', '重置布局'),
            ],
          ),
          
          _buildShortcutSection(
            '快速过滤',
            [
              ShortcutInfo('Cmd+1', '切换可点击元素过滤'),
              ShortcutInfo('Cmd+2', '切换输入框过滤'),
              ShortcutInfo('Cmd+3', '切换有文本元素过滤'),
              ShortcutInfo('Cmd+4', '清除所有过滤器'),
            ],
          ),
          
          _buildShortcutSection(
            '编辑操作',
            [
              ShortcutInfo('Cmd+C', '复制选中属性值'),
              ShortcutInfo('Cmd+A', '选择所有XML内容'),
              ShortcutInfo('Cmd+S', '导出当前XML'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoCard(
            '提示',
            '大部分快捷键在相应的菜单项和按钮上都有显示。您也可以通过鼠标悬停查看工具提示。',
            Icons.lightbulb,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStepCard(int step, String title, String description, IconData icon, List<String> details) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    step.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...details.map((detail) => Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.arrow_right,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      detail,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    final theme = Theme.of(context);
    
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallationStep(String title, List<String> steps, String? command) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...steps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: theme.colorScheme.primary)),
                  Expanded(child: Text(step, style: theme.textTheme.bodySmall)),
                ],
              ),
            )),
            if (command != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        command,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: command));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('命令已复制到剪贴板')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      tooltip: '复制命令',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingCard(String title, List<String> solutions, IconData icon) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...solutions.map((solution) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(color: theme.colorScheme.primary)),
                  Expanded(child: Text(solution, style: theme.textTheme.bodySmall)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, IconData icon, List<String> features) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutSection(String title, List<ShortcutInfo> shortcuts) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: shortcuts.map((shortcut) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        shortcut.keys,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        shortcut.description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class ShortcutInfo {
  final String keys;
  final String description;

  const ShortcutInfo(this.keys, this.description);
}