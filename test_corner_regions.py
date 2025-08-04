#!/usr/bin/env python3
"""
测试四个角区域处理效果的脚本
"""

from PIL import Image
import os

def test_corner_regions():
    """测试四个角区域的处理效果"""
    input_file = "ic_launcher_transparent.png"
    
    if not os.path.exists(input_file):
        print(f"❌ 找不到文件: {input_file}")
        return
    
    # 打开图像
    img = Image.open(input_file)
    width, height = img.size
    
    print(f"📏 图标尺寸: {width}x{height} 像素")
    print(f"🎨 图像模式: {img.mode}")
    
    # 计算角区域大小（1/4宽度）
    corner_size = width // 4
    print(f"📐 角区域大小: {corner_size}x{corner_size} 像素")
    
    # 定义四个角区域
    corner_regions = [
        # 左上角
        (0, 0, corner_size, corner_size, "左上角"),
        # 右上角
        (width - corner_size, 0, width, corner_size, "右上角"),
        # 左下角
        (0, height - corner_size, corner_size, height, "左下角"),
        # 右下角
        (width - corner_size, height - corner_size, width, height, "右下角")
    ]
    
    # 测试每个角区域的像素
    test_positions = [
        # 左上角测试点
        (0, 0, "左上角-原点"),
        (corner_size//2, corner_size//2, "左上角-中心"),
        (corner_size-1, 0, "左上角-右边缘"),
        (0, corner_size-1, "左上角-下边缘"),
        
        # 右上角测试点
        (width-1, 0, "右上角-原点"),
        (width-corner_size//2, corner_size//2, "右上角-中心"),
        (width-corner_size, 0, "右上角-左边缘"),
        (width-1, corner_size-1, "右上角-下边缘"),
        
        # 左下角测试点
        (0, height-1, "左下角-原点"),
        (corner_size//2, height-corner_size//2, "左下角-中心"),
        (corner_size-1, height-1, "左下角-右边缘"),
        (0, height-corner_size, "左下角-上边缘"),
        
        # 右下角测试点
        (width-1, height-1, "右下角-原点"),
        (width-corner_size//2, height-corner_size//2, "右下角-中心"),
        (width-corner_size, height-1, "右下角-左边缘"),
        (width-1, height-corner_size, "右下角-上边缘"),
        
        # 中心区域测试点
        (width//2, height//2, "中心区域"),
        (width//2, 0, "顶部中心"),
        (width//2, height-1, "底部中心"),
        (0, height//2, "左侧中心"),
        (width-1, height//2, "右侧中心"),
    ]
    
    print(f"\n🔍 测试各区域像素:")
    
    corner_transparent = 0
    center_transparent = 0
    total_corner_tests = 16  # 4个角 x 4个测试点
    total_center_tests = 5   # 中心区域测试点
    
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
            else:  # RGB
                r, g, b = pixel
                transparency = "不透明 (无alpha通道)"
                color = f"RGB({r},{g},{b})"
            
            print(f"  {name} ({x},{y}): {color} - {transparency}")
    
    print(f"\n📊 角区域透明统计: {corner_transparent}/{total_corner_tests} 个测试点")
    print(f"📊 中心区域透明统计: {center_transparent}/{total_center_tests} 个测试点")
    
    # 统计每个角区域的透明像素
    print(f"\n🔍 各角区域透明像素统计:")
    for x1, y1, x2, y2, corner_name in corner_regions:
        transparent_count = 0
        total_pixels = (x2 - x1) * (y2 - y1)
        
        for y in range(y1, y2):
            for x in range(x1, x2):
                pixel = img.getpixel((x, y))
                if len(pixel) == 4 and pixel[3] == 0:  # alpha = 0
                    transparent_count += 1
        
        percentage = (transparent_count / total_pixels) * 100
        print(f"  {corner_name}: {transparent_count}/{total_pixels} ({percentage:.1f}%)")
    
    print("\n✅ 测试完成！")

if __name__ == "__main__":
    test_corner_regions() 