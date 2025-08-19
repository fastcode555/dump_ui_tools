#!/bin/bash

# 更新Flutter项目依赖版本的脚本
# 根据pubspec.lock文件自动更新pubspec.yaml中的版本
# 简化版本：只要插件前面有空格，就可以进行替换

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查必要文件
if [ ! -f "pubspec.lock" ]; then
    echo -e "${RED}错误: 找不到pubspec.lock文件${NC}"
    exit 1
fi

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}错误: 找不到pubspec.yaml文件${NC}"
    exit 1
fi

echo -e "${BLUE}开始更新依赖版本...${NC}"

# 创建临时文件存储版本信息
TEMP_VERSIONS=$(mktemp)
TEMP_PACKAGES=$(mktemp)

# 解析pubspec.lock中的依赖版本
echo -e "${BLUE}解析pubspec.lock中的版本信息...${NC}"

# 提取所有direct依赖包及其版本
package_count=0
current_package=""
current_dependency=""
current_version=""

while IFS= read -r line; do
    # 检查是否是包名行（包名后面有冒号，且不是其他字段）
    # 排除description、name、url、source等字段
    if [[ $line =~ ^[[:space:]]*([a-zA-Z0-9_-]+):[[:space:]]*$ ]] && \
       [[ "${BASH_REMATCH[1]}" != "description" && "${BASH_REMATCH[1]}" != "name" && "${BASH_REMATCH[1]}" != "url" && "${BASH_REMATCH[1]}" != "source" && "${BASH_REMATCH[1]}" != "packages" ]]; then
        current_package="${BASH_REMATCH[1]}"
        current_dependency=""
        current_version=""
    # 检查是否是dependency行（处理带引号和不带引号的格式）
    elif [[ $line =~ ^[[:space:]]*dependency:[[:space:]]*\"?([^\"]+)\"? ]]; then
        current_dependency="${BASH_REMATCH[1]}"
    # 检查是否是版本行
    elif [[ $line =~ ^[[:space:]]*version:[[:space:]]*\"([^\"]+)\" ]]; then
        current_version="${BASH_REMATCH[1]}"
        # 只处理direct依赖，跳过Flutter SDK相关的包
        if [[ "$current_dependency" == "direct main" || "$current_dependency" == "direct dev" ]] && \
           [[ "$current_package" != "flutter" && "$current_package" != "flutter_test" && "$current_package" != "flutter_web_plugins" && "$current_package" != "sky_engine" ]]; then
            echo "$current_package" >> "$TEMP_PACKAGES"
            echo "$current_version" >> "$TEMP_VERSIONS"
            echo -e "${GREEN}找到包: $current_package ($current_dependency) -> $current_version${NC}"
            ((package_count++))
        fi
    fi
done < pubspec.lock

echo -e "${BLUE}共找到 $package_count 个direct依赖包${NC}"

# 更新pubspec.yaml中的版本
echo -e "${BLUE}开始更新pubspec.yaml...${NC}"

# 读取包名和版本到数组
packages=()
versions=()
while IFS= read -r package; do
    packages+=("$package")
done < "$TEMP_PACKAGES"

while IFS= read -r version; do
    versions+=("$version")
done < "$TEMP_VERSIONS"

# 显示要更新的包信息
echo -e "${YELLOW}要更新的包:${NC}"
for i in "${!packages[@]}"; do
    echo -e "  ${packages[$i]} -> ^${versions[$i]}"
done

echo -e "${YELLOW}开始更新依赖版本...${NC}"

# 更新每个包
for i in "${!packages[@]}"; do
    package="${packages[$i]}"
    version="${versions[$i]}"
    
    echo -e "${BLUE}处理包: $package${NC}"
    
    # 简化逻辑：只要插件前面有空格，就可以进行替换
    # 这样可以匹配到 dependencies 和 dev_dependencies 下的所有子级依赖
    if grep -q "^[[:space:]]\+$package:" pubspec.yaml; then
        # 使用更简单的sed替换，直接替换整个版本部分
        sed -i.tmp "s/$package:.*/$package: ^$version/" pubspec.yaml
        
        # 检查是否更新成功
        if grep -q "^[[:space:]]\+$package:[[:space:]]*^$version" pubspec.yaml; then
            echo -e "${GREEN}✓ 更新成功: $package -> ^$version${NC}"
        else
            echo -e "${RED}✗ 更新失败: $package${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ 未找到包: $package${NC}"
    fi
done

# 清理临时文件
rm -f pubspec.yaml.tmp
rm -f "$TEMP_VERSIONS" "$TEMP_PACKAGES"

echo -e "${GREEN}依赖版本更新完成！${NC}"
echo -e "${YELLOW}建议执行以下命令验证更新:${NC}"
echo -e "  flutter pub get"
echo -e "  flutter pub outdated"
echo -e ""
echo -e "${YELLOW}如果需要回滚，可以使用Git命令:${NC}"
echo -e "  git checkout -- pubspec.yaml"
echo -e "  git restore pubspec.yaml"
