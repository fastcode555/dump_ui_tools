#!/usr/bin/env python3
"""
测试圆角效果的脚本
"""

from PIL import Image
import os
import math

def test_rounded_corners():
    """测试圆角效果"""
    input_file = "ic_launcher_transparent.png"
    
    if not os.path.exists(input_file):
        print(f"❌ 找不到文件: {input_file}")
        return
    
    # 打开图像
    img = Image.open(input_file)
    width, height = img.size
    
    print(f"📏 图标尺寸: {width}x{height} 像素")
    print(f"🎨 图像模式: {img.mode}")
    
    # 测试圆角区域的像素
    corner_radius = 100
    
    # 测试四个角的圆角区域
    test_positions = [
        # 左上角圆角区域
        (0, 0, "左上角-原点"),
        (corner_radius//2, corner_radius//2, "左上角-圆角中心"),
        (corner_radius, 0, "左上角-圆角边缘"),
        (0, corner_radius, "左上角-圆角边缘"),
        
        # 右上角圆角区域
        (width-1, 0, "右上角-原点"),
        (width-corner_radius//2, corner_radius//2, "右上角-圆角中心"),
        (width-corner_radius, 0, "右上角-圆角边缘"),
        (width-1, corner_radius, "右上角-圆角边缘"),
        
        # 左下角圆角区域
        (0, height-1, "左下角-原点"),
        (corner_radius//2, height-corner_radius//2, "左下角-圆角中心"),
        (corner_radius, height-1, "左下角-圆角边缘"),
        (0, height-corner_radius, "左下角-圆角边缘"),
        
        # 右下角圆角区域
        (width-1, height-1, "右下角-原点"),
        (width-corner_radius//2, height-corner_radius//2, "右下角-圆角中心"),
        (width-corner_radius, height-1, "右下角-圆角边缘"),
        (width-1, height-corner_radius, "右下角-圆角边缘"),
        
        # 中心区域
        (width//2, height//2, "中心区域"),
    ]
    
    print(f"\n🔍 测试圆角区域的像素 (圆角半径: {corner_radius}):")
    
    transparent_count = 0
    for x, y, name in test_positions:
        if 0 <= x < width and 0 <= y < height:
            pixel = img.getpixel((x, y))
            if len(pixel) == 4:  # RGBA
                r, g, b, a = pixel
                transparency = "透明" if a == 0 else f"不透明 (alpha={a})"
                color = f"RGB({r},{g},{b})"
                if a == 0:
                    transparent_count += 1
            else:  # RGB
                r, g, b = pixel
                transparency = "不透明 (无alpha通道)"
                color = f"RGB({r},{g},{b})"
            
            print(f"  {name} ({x},{y}): {color} - {transparency}")
    
    print(f"\n📊 透明像素统计: {transparent_count}/{len(test_positions)} 个测试点")
    
    # 检查圆角外的区域是否透明
    print(f"\n🔍 检查圆角外的区域:")
    
    # 测试圆角外的区域
    outside_positions = [
        (width//2, 0, "顶部中心"),
        (width//2, height-1, "底部中心"),
        (0, height//2, "左侧中心"),
        (width-1, height//2, "右侧中心"),
    ]
    
    outside_transparent = 0
    for x, y, name in outside_positions:
        pixel = img.getpixel((x, y))
        if len(pixel) == 4:  # RGBA
            r, g, b, a = pixel
            transparency = "透明" if a == 0 else f"不透明 (alpha={a})"
            if a == 0:
                outside_transparent += 1
        else:  # RGB
            transparency = "不透明 (无alpha通道)"
        
        print(f"  {name} ({x},{y}): {transparency}")
    
    print(f"\n📊 圆角外透明区域: {outside_transparent}/{len(outside_positions)} 个测试点")
    
    print("\n✅ 测试完成！")

if __name__ == "__main__":
    test_rounded_corners() 