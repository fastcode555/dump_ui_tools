#!/usr/bin/env python3
"""
图标处理效果测试脚本
用于验证四个角的透明背景处理效果
"""

from PIL import Image
import os

def test_icon_processing():
    """测试图标处理效果"""
    input_file = "ic_launcher_transparent.png"  # 测试处理后的文件
    
    if not os.path.exists(input_file):
        print(f"❌ 找不到图标文件: {input_file}")
        return
    
    # 打开图像
    img = Image.open(input_file)
    width, height = img.size
    
    print(f"📏 图标尺寸: {width}x{height} 像素")
    
    # 检查四个角的透明度
    corners = [
        (0, 0, "左上角"),
        (width-1, 0, "右上角"),
        (0, height-1, "左下角"),
        (width-1, height-1, "右下角")
    ]
    
    print("\n🔍 检查四个角的透明度:")
    for x, y, name in corners:
        pixel = img.getpixel((x, y))
        if len(pixel) == 4:  # RGBA
            r, g, b, a = pixel
            transparency = "透明" if a == 0 else f"不透明 (alpha={a})"
            color = f"RGB({r},{g},{b})"
        else:  # RGB
            r, g, b = pixel
            transparency = "不透明 (无alpha通道)"
            color = f"RGB({r},{g},{b})"
        
        print(f"  {name}: {color} - {transparency}")
    
    # 检查中心区域
    center_x, center_y = width // 2, height // 2
    center_pixel = img.getpixel((center_x, center_y))
    
    print(f"\n🎯 中心区域颜色: RGB({center_pixel[0]},{center_pixel[1]},{center_pixel[2]})")
    
    # 统计透明像素
    if img.mode == 'RGBA':
        transparent_count = 0
        total_pixels = width * height
        
        for y in range(height):
            for x in range(width):
                pixel = img.getpixel((x, y))
                if pixel[3] == 0:  # alpha = 0
                    transparent_count += 1
        
        transparency_percentage = (transparent_count / total_pixels) * 100
        print(f"\n📊 透明像素统计:")
        print(f"  总像素数: {total_pixels}")
        print(f"  透明像素数: {transparent_count}")
        print(f"  透明度比例: {transparency_percentage:.2f}%")
    
    print("\n✅ 测试完成！")

if __name__ == "__main__":
    test_icon_processing() 