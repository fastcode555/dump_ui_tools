#!/usr/bin/env python3
"""
测试圆角区域处理效果的脚本
"""

from PIL import Image
import os
import math

def test_rounded_corners():
    """测试圆角区域的处理效果"""
    input_file = "ic_launcher_transparent.png"
    
    if not os.path.exists(input_file):
        print(f"❌ 找不到文件: {input_file}")
        return
    
    # 打开图像
    img = Image.open(input_file)
    width, height = img.size
    
    print(f"📏 图标尺寸: {width}x{height} 像素")
    print(f"🎨 图像模式: {img.mode}")
    
    # 计算圆角区域大小（1/4宽度）
    corner_size = width // 4
    radius = corner_size // 2
    print(f"📐 圆角区域大小: {corner_size}x{corner_size} 像素，半径: {radius}")
    
    # 定义四个圆角区域的中心点
    corner_centers = [
        (radius, radius, "左上角"),
        (width - radius, radius, "右上角"),
        (radius, height - radius, "左下角"),
        (width - radius, height - radius, "右下角")
    ]
    
    # 测试每个圆角区域的像素
    test_positions = []
    
    for center_x, center_y, corner_name in corner_centers:
        # 圆角中心
        test_positions.append((center_x, center_y, f"{corner_name}-中心"))
        # 圆角边缘
        test_positions.append((center_x - radius, center_y, f"{corner_name}-左边缘"))
        test_positions.append((center_x + radius, center_y, f"{corner_name}-右边缘"))
        test_positions.append((center_x, center_y - radius, f"{corner_name}-上边缘"))
        test_positions.append((center_x, center_y + radius, f"{corner_name}-下边缘"))
        # 圆角内部
        test_positions.append((center_x - radius//2, center_y - radius//2, f"{corner_name}-内部"))
        # 圆角外部
        test_positions.append((center_x - radius - 10, center_y, f"{corner_name}-外部"))
    
    # 中心区域测试点
    test_positions.extend([
        (width//2, height//2, "中心区域"),
        (width//2, 0, "顶部中心"),
        (width//2, height-1, "底部中心"),
        (0, height//2, "左侧中心"),
        (width-1, height//2, "右侧中心"),
    ])
    
    print(f"\n🔍 测试各区域像素:")
    
    corner_transparent = 0
    center_transparent = 0
    total_corner_tests = 0
    total_center_tests = 5
    
    for x, y, name in test_positions:
        if 0 <= x < width and 0 <= y < height:
            pixel = img.getpixel((x, y))
            if len(pixel) == 4:  # RGBA
                r, g, b, a = pixel
                transparency = "透明" if a == 0 else f"不透明 (alpha={a})"
                color = f"RGB({r},{g},{b})"
                if a == 0:
                    if "角" in name:
                        corner_transparent += 1
                    else:
                        center_transparent += 1
                if "角" in name:
                    total_corner_tests += 1
            else:  # RGB
                r, g, b = pixel
                transparency = "不透明 (无alpha通道)"
                color = f"RGB({r},{g},{b})"
                if "角" in name:
                    total_corner_tests += 1
            
            print(f"  {name} ({x},{y}): {color} - {transparency}")
    
    print(f"\n📊 圆角区域透明统计: {corner_transparent}/{total_corner_tests} 个测试点")
    print(f"📊 中心区域透明统计: {center_transparent}/{total_center_tests} 个测试点")
    
    # 统计每个圆角区域的透明像素
    print(f"\n🔍 各圆角区域透明像素统计:")
    for center_x, center_y, corner_name in corner_centers:
        transparent_count = 0
        total_pixels = 0
        
        # 计算圆角区域的边界框
        x1 = max(0, center_x - radius)
        y1 = max(0, center_y - radius)
        x2 = min(width, center_x + radius)
        y2 = min(height, center_y + radius)
        
        for y in range(y1, y2):
            for x in range(x1, x2):
                # 计算到圆心的距离
                distance = math.sqrt((x - center_x) ** 2 + (y - center_y) ** 2)
                
                # 检查是否在圆形区域内
                if distance <= radius:
                    total_pixels += 1
                    pixel = img.getpixel((x, y))
                    if len(pixel) == 4 and pixel[3] == 0:  # alpha = 0
                        transparent_count += 1
        
        if total_pixels > 0:
            percentage = (transparent_count / total_pixels) * 100
            print(f"  {corner_name}: {transparent_count}/{total_pixels} ({percentage:.1f}%)")
    
    print("\n✅ 测试完成！")

if __name__ == "__main__":
    test_rounded_corners() 