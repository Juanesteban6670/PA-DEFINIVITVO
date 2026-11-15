from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

width, height = 1200, 500
banner = Image.new("RGBA", (width, height), (15, 23, 42, 255)) # Dark slate (#0F172A)
draw = ImageDraw.Draw(banner)

# Add subtle gradient or geometric shapes
for i in range(height):
    alpha = int(255 - (i / height) * 50)
    draw.line([(0, i), (width, i)], fill=(15 + int(i*0.03), 23 + int(i*0.05), 42 + int(i*0.1), 255))

# Draw decorative background circles
draw.ellipse([800, -100, 1300, 400], fill=(30, 58, 138, 90))
draw.ellipse([950, 150, 1350, 550], fill=(2, 132, 199, 60))

# Paste AppLogo if available
logo_path = "client/assets/brand/app-icon.png"
if os.path.exists(logo_path):
    logo = Image.open(logo_path).convert("RGBA")
    logo = logo.resize((180, 180), Image.Resampling.LANCZOS)
    banner.paste(logo, (70, 160), logo)

# Draw text
try:
    font_title = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 44)
    font_sub = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 22)
    font_tag = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
except:
    font_title = ImageFont.load_default()
    font_sub = ImageFont.load_default()
    font_tag = ImageFont.load_default()

draw.text((280, 170), "CARTAGENA SEGURA", fill=(255, 255, 255, 255), font=font_title)
draw.text((280, 230), "DOCUMENTO DE ESPECIFICACIÓN DE CASOS DE USO", fill=(56, 189, 248, 255), font=font_sub)
draw.text((280, 270), "Plataforma Integral de Seguridad Ciudadana y Monitoreo Geoespacial", fill=(203, 213, 225, 255), font=font_tag)
draw.text((280, 310), "Distrito Turístico y Cultural de Cartagena de Indias • Versión 2.3.0", fill=(148, 163, 184, 255), font=font_tag)

banner.convert("RGB").save("doc_assets/cover_banner.jpg", "JPEG", quality=95)
print("Cover banner created successfully!")
