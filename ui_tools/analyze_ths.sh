#!/bin/bash

# 同花顺UI完整分析脚本

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== 同花顺UI完整分析工具 ===${NC}"

# 进入ui_tools目录
cd "$(dirname "$0")"

# 1. 启动同花顺
echo -e "${YELLOW}步骤1: 启动同花顺应用${NC}"
./start_ths.sh

if [ $? -ne 0 ]; then
    echo -e "${RED}启动同花顺失败，退出${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}请按以下步骤操作:${NC}"
echo "1. 在同花顺应用中导航到交易页面"
echo "2. 确保页面完全加载"
echo "3. 按任意键继续..."
read -n 1 -s

# 2. 获取UI布局
echo -e "${YELLOW}步骤2: 获取UI布局${NC}"
./dump_ui.sh "ths_ui.xml"

if [ $? -ne 0 ]; then
    echo -e "${RED}获取UI布局失败，退出${NC}"
    exit 1
fi

# 3. 启动分析工具
echo -e "${YELLOW}步骤3: 启动UI分析工具${NC}"
echo "建议搜索以下关键词:"
echo "- 交易"
echo "- 条件单"
echo "- 新建条件单"
echo "- 股价条件"
echo "- 股票"
echo "- 000001"

python3 ui_analyzer.py

echo -e "${GREEN}分析完成!${NC}"