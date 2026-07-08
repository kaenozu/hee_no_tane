"""Generate a simple app icon for hee_no_tane"""
import os
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
BG = (0x1A, 0x6B, 0x5A, 255)  # Deep Teal
FG = (0xE8, 0xA8, 0x7C, 255)  # Coral

img = Image.new("RGBA", (SIZE, SIZE), BG)
draw = ImageDraw.Draw(img)

font_paths = [
    "C:/Windows/Fonts/msgothic.ttc",
    "C:/Windows/Fonts/meiryo.ttc",
    "C:/Windows/Fonts/arial.ttf",
]

font = None
for fp in font_paths:
    try:
        font = ImageFont.truetype(fp, 400)
        break
    except Exception:
        continue

if font is None:
    font = ImageFont.load_default()

text = "へ"
bbox = draw.textbbox((0, 0), text, font=font)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
x = (SIZE - tw) // 2 - bbox[0]
y = (SIZE - th) // 2 - bbox[1]
draw.text((x, y), text, fill=FG, font=font)

out_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets")
os.makedirs(out_dir, exist_ok=True)
out_path = os.path.join(out_dir, "app_icon.png")
img.save(out_path)
print(f"Saved: {out_path}")
