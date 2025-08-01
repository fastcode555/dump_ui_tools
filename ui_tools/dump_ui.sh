#!/bin/bash

# UI布局拉取脚本
# 用法: ./dump_ui.sh [输出文件名]

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认输出文件名
OUTPUT_FILE=${1:-"window_dump.xml"}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="dumps/window_dump_${TIMESTAMP}.xml"

echo -e "${BLUE}=== Android UI 布局拉取工具 ===${NC}"

# 检查设备连接
echo -e "${YELLOW}检查设备连接...${NC}"
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}错误: 没有找到连接的Android设备${NC}"
    echo "请确保:"
    echo "1. 设备已通过USB连接"
    echo "2. 已启用USB调试"
    echo "3. 已授权此计算机进行调试"
    exit 1
fi

echo -e "${GREEN}✓ 设备连接正常${NC}"

# 获取当前应用信息
echo -e "${YELLOW}获取当前应用信息...${NC}"
CURRENT_APP=$(adb shell dumpsys window windows | grep -E 'mCurrentFocus' | head -1)
echo -e "${BLUE}当前焦点应用: ${CURRENT_APP}${NC}"

# 创建备份目录
mkdir -p dumps

# 获取UI布局
echo -e "${YELLOW}正在获取UI布局...${NC}"
if adb shell uiautomator dump; then
    echo -e "${GREEN}✓ UI布局获取成功${NC}"
else
    echo -e "${RED}✗ UI布局获取失败${NC}"
    exit 1
fi

# 拉取文件到本地
echo -e "${YELLOW}正在拉取布局文件...${NC}"
if adb pull /sdcard/window_dump.xml "${OUTPUT_FILE}"; then
    echo -e "${GREEN}✓ 布局文件已保存为: ${OUTPUT_FILE}${NC}"
    
    # 创建备份
    cp "${OUTPUT_FILE}" "${BACKUP_FILE}"
    echo -e "${GREEN}✓ 备份文件已保存为: ${BACKUP_FILE}${NC}"
else
    echo -e "${RED}✗ 拉取布局文件失败${NC}"
    exit 1
fi

# 显示文件信息
FILE_SIZE=$(wc -c < "${OUTPUT_FILE}")
ELEMENT_COUNT=$(grep -o '<node' "${OUTPUT_FILE}" | wc -l)

echo -e "${BLUE}文件信息:${NC}"
echo "  文件大小: ${FILE_SIZE} 字节"
echo "  UI元素数量: ${ELEMENT_COUNT} 个"

# 询问是否启动分析工具
echo ""
read -p "是否启动UI分析工具? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}启动UI分析工具...${NC}"
    python3 ui_analyzer.py
fi

echo -e "${GREEN}完成!${NC}"