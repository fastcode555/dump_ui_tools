#!/bin/bash

# 启动同花顺应用脚本

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 同花顺应用启动工具 ===${NC}"

# 检查设备连接
echo -e "${YELLOW}检查设备连接...${NC}"
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}错误: 没有找到连接的Android设备${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 设备连接正常${NC}"

# 检查同花顺是否已安装
echo -e "${YELLOW}检查同花顺应用...${NC}"
if adb shell pm list packages | grep -q "com.hexin.plat.android"; then
    echo -e "${GREEN}✓ 同花顺应用已安装${NC}"
else
    echo -e "${RED}✗ 同花顺应用未安装${NC}"
    echo "请先安装同花顺应用"
    exit 1
fi

# 启动同花顺应用
echo -e "${YELLOW}正在启动同花顺应用...${NC}"
if adb shell monkey -p com.hexin.plat.android -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1; then
    echo -e "${GREEN}✓ 同花顺应用启动成功${NC}"
else
    echo -e "${RED}✗ 同花顺应用启动失败${NC}"
    exit 1
fi

# 等待应用完全启动
echo -e "${YELLOW}等待应用完全启动...${NC}"
sleep 3

# 获取当前应用信息
CURRENT_APP=$(adb shell dumpsys window windows | grep -E 'mCurrentFocus' | head -1)
echo -e "${BLUE}当前焦点应用: ${CURRENT_APP}${NC}"

# 检查是否成功启动到同花顺
if echo "$CURRENT_APP" | grep -q "com.hexin.plat.android"; then
    echo -e "${GREEN}✓ 成功启动到同花顺应用${NC}"
else
    echo -e "${YELLOW}⚠ 当前焦点不在同花顺应用，请手动切换${NC}"
fi

echo ""
echo -e "${BLUE}提示:${NC}"
echo "1. 请手动导航到交易页面"
echo "2. 然后运行 ./dump_ui.sh 获取UI布局"
echo "3. 或运行 ./analyze_ths.sh 进行完整分析"

echo -e "${GREEN}完成!${NC}"