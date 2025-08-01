#!/usr/bin/env python3
"""
UI Analyzer Tool - 分析Android UI结构的工具
使用方法：
1. 确保设备连接并启用USB调试
2. 打开要分析的应用
3. 运行此脚本
"""

import subprocess
import xml.etree.ElementTree as ET
import json
import sys
import os

def run_command(cmd):
    """执行命令并返回输出"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout, result.stderr, result.returncode
    except Exception as e:
        return "", str(e), 1

def get_ui_dump():
    """获取UI层次结构"""
    print("正在获取UI层次结构...")
    
    # 检查是否已有window_dump.xml文件
    if os.path.exists("window_dump.xml"):
        print("使用现有的window_dump.xml文件")
        return "window_dump.xml"
    
    # 获取UI dump
    stdout, stderr, code = run_command("adb shell uiautomator dump")
    if code != 0:
        print(f"获取UI dump失败: {stderr}")
        return None
    
    # 拉取文件到本地
    stdout, stderr, code = run_command("adb pull /sdcard/window_dump.xml ./window_dump.xml")
    if code != 0:
        print(f"拉取文件失败: {stderr}")
        return None
    
    return "./window_dump.xml"

def parse_ui_elements(xml_file):
    """解析UI元素"""
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        
        elements = []
        
        def traverse_node(node, depth=0):
            # 提取节点属性
            attrs = node.attrib
            element = {
                'depth': depth,
                'text': attrs.get('text', ''),
                'content-desc': attrs.get('content-desc', ''),
                'class': attrs.get('class', ''),
                'package': attrs.get('package', ''),
                'resource-id': attrs.get('resource-id', ''),
                'clickable': attrs.get('clickable', 'false') == 'true',
                'enabled': attrs.get('enabled', 'false') == 'true',
                'bounds': attrs.get('bounds', ''),
                'index': attrs.get('index', ''),
            }
            
            # 只保存有用的元素
            if (element['text'] or element['content-desc'] or 
                element['clickable'] or 'EditText' in element['class']):
                elements.append(element)
            
            # 递归处理子节点
            for child in node:
                traverse_node(child, depth + 1)
        
        traverse_node(root)
        return elements
        
    except Exception as e:
        print(f"解析XML失败: {e}")
        return []

def find_elements_by_text(elements, search_text):
    """根据文本查找元素"""
    found = []
    for element in elements:
        if (search_text.lower() in element['text'].lower() or 
            search_text.lower() in element['content-desc'].lower()):
            found.append(element)
    return found

def print_element(element):
    """打印元素信息"""
    indent = "  " * element['depth']
    print(f"{indent}[{element['index']}] {element['class']}")
    if element['text']:
        print(f"{indent}  文本: '{element['text']}'")
    if element['content-desc']:
        print(f"{indent}  描述: '{element['content-desc']}'")
    if element['resource-id']:
        print(f"{indent}  ID: {element['resource-id']}")
    print(f"{indent}  可点击: {element['clickable']}")
    print(f"{indent}  边界: {element['bounds']}")
    print()

def main():
    print("=== Android UI 分析工具 ===")
    
    # 获取当前应用包名
    stdout, stderr, code = run_command("adb shell dumpsys window windows | grep -E 'mCurrentFocus|mFocusedApp'")
    if code == 0:
        print("当前焦点应用:")
        print(stdout)
    
    # 获取UI结构
    xml_file = get_ui_dump()
    if not xml_file:
        return
    
    # 解析元素
    elements = parse_ui_elements(xml_file)
    print(f"找到 {len(elements)} 个有用的UI元素")
    
    # 交互式查找
    while True:
        print("\n=== 选择操作 ===")
        print("1. 显示所有元素")
        print("2. 按文本搜索")
        print("3. 显示可点击元素")
        print("4. 显示输入框")
        print("5. 重新获取UI")
        print("0. 退出")
        
        choice = input("请选择 (0-5): ").strip()
        
        if choice == '0':
            break
        elif choice == '1':
            print("\n=== 所有UI元素 ===")
            for element in elements:
                print_element(element)
        elif choice == '2':
            search_text = input("请输入搜索文本: ").strip()
            found = find_elements_by_text(elements, search_text)
            print(f"\n=== 搜索结果 (找到 {len(found)} 个) ===")
            for element in found:
                print_element(element)
        elif choice == '3':
            clickable = [e for e in elements if e['clickable']]
            print(f"\n=== 可点击元素 (共 {len(clickable)} 个) ===")
            for element in clickable:
                print_element(element)
        elif choice == '4':
            inputs = [e for e in elements if 'EditText' in e['class'] or 'Input' in e['class']]
            print(f"\n=== 输入框 (共 {len(inputs)} 个) ===")
            for element in inputs:
                print_element(element)
        elif choice == '5':
            xml_file = get_ui_dump()
            if xml_file:
                elements = parse_ui_elements(xml_file)
                print(f"重新获取完成，找到 {len(elements)} 个有用的UI元素")

if __name__ == "__main__":
    main()