import sys
from PIL import Image, ImageDraw, ImageFont
import os

def create_terminal_screenshot(text, output_path, title="Terminal"):
    # Settings
    font_size = 14
    padding = 20
    line_height = 20
    header_height = 30
    
    # Try to load a monospace font
    try:
        # MacOS default monospace
        font = ImageFont.truetype("/System/Library/Fonts/Monaco.ttf", font_size)
        header_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 14)
    except:
        font = ImageFont.load_default()
        header_font = ImageFont.load_default()

    lines = text.split('\n')
    width = 800
    height = header_height + (len(lines) * line_height) + (padding * 2)
    
    # Create image with dark background
    img = Image.new('RGB', (width, height), color='#1e1e1e')
    draw = ImageDraw.Draw(img)
    
    # Draw header bar
    draw.rectangle([(0, 0), (width, header_height)], fill='#2d2d2d')
    
    # Draw window buttons
    draw.ellipse([(10, 8), (22, 20)], fill='#ff5f56') # Red
    draw.ellipse([(30, 8), (42, 20)], fill='#ffbd2e') # Yellow
    draw.ellipse([(50, 8), (62, 20)], fill='#27c93f') # Green
    
    # Draw title
    draw.text((width//2, 5), title, font=header_font, fill='#d4d4d4', anchor="mt")

    # Draw text
    y = header_height + padding
    for line in lines:
        draw.text((padding, y), line, font=font, fill='#d4d4d4')
        y += line_height

    img.save(output_path)
    print(f"Generated {output_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 gen_terminal_screenshot.py <input_text_file> <output_png_path> [title]")
        sys.exit(1)
        
    input_file = sys.argv[1]
    output_path = sys.argv[2]
    title = sys.argv[3] if len(sys.argv) > 3 else "Terminal"
    
    with open(input_file, 'r') as f:
        text = f.read()
        
    create_terminal_screenshot(text, output_path, title)
