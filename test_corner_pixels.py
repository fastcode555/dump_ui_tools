#!/usr/bin/env python3
"""
详细测试角区域像素的脚本
"""

from PIL import Image
import os

def test_corner_pixels():
    """测试角区域像素"""
    input_file = "ic_launcher_transparent.png"
    
    if not os.path.exists(input_file):
        print(f"❌ 找不到文件: {input_file}")
        return
    
    # 打开图像
    img = Image.open(input_file)
    width, height = img.size
    
    print(f"📏 图标尺寸: {width}x{height} 像素")
    print(f"🎨 图像模式: {img.mode}")
    
    # 测试角区域内的多个像素
    corner_size = 100
    test_positions = [
        (0, 0, "左上角-原点"),
        (10, 10, "左上角-内部"),
        (50, 50, "左上角-中心"),
        (corner_size-1, 0, "左上角-右边缘"),
        (0, corner_size-1, "左上角-下边缘"),
        
        (width-1, 0, "右上角-原点"),
        (width-10, 10, "右上角-内部"),
        (width-50, 50, "右上角-中心"),
        (width-corner_size, 0, "右上角-左边缘"),
        (width-1, corner_size-1, "右上角-下边缘"),
        
        (0, height-1, "左下角-原点"),
        (10, height-10, "左下角-内部"),
        (50, height-50, "左下角-中心"),
        (corner_size-1, height-1, "左下角-右边缘"),
        (0, height-corner_size, "左下角-上边缘"),
        
        (width-1, height-1, "右下角-原点"),
        (width-10, height-10, "右下角-内部"),
        (width-50, height-50, "右下角-中心"),
        (width-corner_size, height-1, "右下角-左边缘"),
        (width-1, height-corner_size, "右下角-上边缘"),
    ]
    
    print(f"\n🔍 测试角区域内的像素 (角区域大小: {corner_size}x{corner_size}):")
    
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
    
    # 检查中心区域
    center_x, center_y = width // 2, height // 2
    center_pixel = img.getpixel((center_x, center_y))
    print(f"\n🎯 中心区域 ({center_x},{center_y}): RGB({center_pixel[0]},{center_pixel[1]},{center_pixel[2]})")
    
    print("\n✅ 测试完成！")

if __name__ == "__main__":
    test_corner_pixels() 