#!/usr/bin/env python3
"""
图标背景透明化处理脚本
使用PIL库处理图标，只移除四个圆角区域的白色背景
"""

from PIL import Image, ImageDraw
import os
import math

def make_icon_transparent(input_path, output_path, corner_ratio=0.25, color_tolerance=50):
    """
    将图标处理成圆角透明背景，只处理四个圆角区域
    
    Args:
        input_path: 输入图标路径
        output_path: 输出图标路径
        corner_ratio: 角区域占宽度的比例（默认0.25，即1/4）
        color_tolerance: 颜色容差，用于检测白色背景
    """
    try:
        # 打开图像
        img = Image.open(input_path)
        
        # 转换为RGBA模式（如果还不是）
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
            print(f"🔄 将图像从 {img.mode} 转换为 RGBA 模式")
        
        # 获取图像尺寸
        width, height = img.size
        
        # 计算圆角区域大小
        corner_size = int(width * corner_ratio)
        
        print(f"📏 图像尺寸: {width}x{height} 像素")
        print(f"📐 圆角区域大小: {corner_size}x{corner_size} 像素")
        
        # 创建新图像
        new_img = img.copy()
        
        # 定义四个圆角区域的中心点和半径
        corner_regions = [
            # 左上角圆角
            (corner_size//2, corner_size//2, corner_size//2, "左上角"),
            # 右上角圆角
            (width - corner_size//2, corner_size//2, corner_size//2, "右上角"),
            # 左下角圆角
            (corner_size//2, height - corner_size//2, corner_size//2, "左下角"),
            # 右下角圆角
            (width - corner_size//2, height - corner_size//2, corner_size//2, "右下角")
        ]
        
        # 统计透明像素
        transparent_count = 0
        total_pixels = width * height
        
        # 处理每个圆角区域
        for center_x, center_y, radius, corner_name in corner_regions:
            corner_transparent = 0
            corner_total = 0
            
            print(f"\n🔍 处理{corner_name}圆角区域 中心({center_x},{center_y}) 半径{radius}")
            
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
                        corner_total += 1
                        pixel = new_img.getpixel((x, y))
                        r, g, b, a = pixel
                        
                        # 检测接近白色的像素
                        if (r >= 255 - color_tolerance and 
                            g >= 255 - color_tolerance and 
                            b >= 255 - color_tolerance):
                            # 白色背景设为透明
                            new_img.putpixel((x, y), (r, g, b, 0))
                            transparent_count += 1
                            corner_transparent += 1
            
            if corner_total > 0:
                corner_percentage = (corner_transparent / corner_total) * 100
                print(f"  {corner_name}圆角透明像素: {corner_transparent}/{corner_total} ({corner_percentage:.1f}%)")
        
        transparency_percentage = (transparent_count / total_pixels) * 100
        
        print(f"\n📊 总体透明像素统计:")
        print(f"  总像素数: {total_pixels}")
        print(f"  透明像素数: {transparent_count}")
        print(f"  透明度比例: {transparency_percentage:.2f}%")
        print(f"  颜色容差: {color_tolerance}")
        print(f"  圆角区域比例: {corner_ratio} ({corner_ratio*100:.0f}%)")
        
        # 保存图像
        new_img.save(output_path, 'PNG')
        print(f"\n✅ 圆角区域白色背景处理完成！输出文件: {output_path}")
        
    except Exception as e:
        print(f"❌ 处理图标时出错: {e}")

def main():
    """主函数"""
    input_file = "ic_launcher.png"
    output_file = "ic_launcher_transparent.png"
    
    # 检查输入文件是否存在
    if not os.path.exists(input_file):
        print(f"❌ 找不到输入文件: {input_file}")
        return
    
    print("🔄 开始处理图标四个圆角区域的白色背景...")
    print(f"📁 输入文件: {input_file}")
    print(f"📁 输出文件: {output_file}")
    
    # 处理图标四个圆角区域
    # 参数说明：
    # corner_ratio=0.25: 圆角区域占宽度的比例（1/4）
    # color_tolerance=50: 颜色容差，用于检测白色背景
    make_icon_transparent(input_file, output_file, corner_ratio=0.25, color_tolerance=50)
    
    print("\n📋 处理完成！")
    print("💡 如果效果不理想，可以调整以下参数：")
    print("   - corner_ratio: 圆角区域比例（默认0.25，即1/4）")
    print("   - color_tolerance: 颜色容差（默认50，越大越容易检测到白色）")

if __name__ == "__main__":
    main() 