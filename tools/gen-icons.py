#!/usr/bin/env python3
# Genera los íconos y el encabezado de Office Móvil en overlay/.
# Uso: python3 tools/gen-icons.py   (requiere Pillow)
# MPL-2.0
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "overlay", "android", "app", "src", "main", "res")

BG = "#1565C0"        # azul
PAGE = "#FFFFFF"
FOLD = "#BBDEFB"
LINE = "#1565C0"
GREEN = "#2E7D32"     # hoja de cálculo
ORANGE = "#EF6C00"    # presentación

# Geometría del ícono en el viewport adaptativo de 108x108 (zona segura 66).
PAGE_PATH = "M36,26 L64,26 L76,38 L76,82 L36,82 Z"
FOLD_PATH = "M64,26 L64,38 L76,38 Z"
LINES = [(42, 44, 70), (42, 52, 70), (42, 60, 58)]       # (x1, y, x2)
CELL_GREEN = (42, 66, 54, 76)
CELL_ORANGE = (58, 66, 70, 76)


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def vectors():
    header = ('<?xml version="1.0" encoding="utf-8"?>\n'
              '<!-- Adk-office (MPL-2.0). Generado por tools/gen-icons.py -->\n')
    write(os.path.join(RES, "drawable", "ic_launcher_background.xml"), header +
          '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
          '    android:width="108dp" android:height="108dp"\n'
          '    android:viewportWidth="108" android:viewportHeight="108">\n'
          f'    <path android:fillColor="{BG}" android:pathData="M0,0h108v108h-108z" />\n'
          '</vector>\n')

    lines = "".join(
        f'    <path android:strokeColor="{LINE}" android:strokeWidth="3"'
        f' android:strokeLineCap="round" android:pathData="M{x1},{y} L{x2},{y}" />\n'
        for x1, y, x2 in LINES)
    def rect(c, color):
        x1, y1, x2, y2 = c
        return (f'    <path android:fillColor="{color}" '
                f'android:pathData="M{x1},{y1} L{x2},{y1} L{x2},{y2} L{x1},{y2} Z" />\n')
    write(os.path.join(RES, "drawable-v24", "ic_launcher_foreground.xml"), header +
          '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
          '    android:width="108dp" android:height="108dp"\n'
          '    android:viewportWidth="108" android:viewportHeight="108">\n'
          f'    <path android:fillColor="{PAGE}" android:pathData="{PAGE_PATH}" />\n'
          f'    <path android:fillColor="{FOLD}" android:pathData="{FOLD_PATH}" />\n'
          + lines + rect(CELL_GREEN, GREEN) + rect(CELL_ORANGE, ORANGE) +
          '</vector>\n')


def draw_icon(size, round_corners=True):
    s = size / 108.0
    # Para íconos heredados se recorta la zona central (18..90).
    off, scale = 18, size / 72.0
    def p(x, y):
        return ((x - off) * scale, (y - off) * scale)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    radius = int(size * 0.18) if round_corners else 0
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=BG)
    d.polygon([p(36, 26), p(64, 26), p(76, 38), p(76, 82), p(36, 82)], fill=PAGE)
    d.polygon([p(64, 26), p(64, 38), p(76, 38)], fill=FOLD)
    w = max(1, int(3 * scale))
    for x1, y, x2 in LINES:
        d.line([p(x1, y), p(x2, y)], fill=LINE, width=w)
    for c, color in ((CELL_GREEN, GREEN), (CELL_ORANGE, ORANGE)):
        d.rectangle([p(c[0], c[1]), p(c[2], c[3])], fill=color)
    del s
    return img


def pngs():
    for density, size in (("mdpi", 48), ("hdpi", 72), ("xhdpi", 96),
                          ("xxhdpi", 144), ("xxxhdpi", 192)):
        icon = draw_icon(size * 4).resize((size, size), Image.LANCZOS)
        out = os.path.join(RES, f"mipmap-{density}", "ic_launcher.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        icon.save(out, optimize=True)
    # lo_icon: ícono del diálogo "Acerca de".
    for density, size in (("mdpi", 48), ("hdpi", 72)):
        icon = draw_icon(size * 4).resize((size, size), Image.LANCZOS)
        out = os.path.join(RES, f"drawable-{density}", "lo_icon.png")
        os.makedirs(os.path.dirname(out), exist_ok=True)
        icon.save(out, optimize=True)


def header():
    w, h = 912, 442
    img = Image.new("RGB", (w, h), BG)
    d = ImageDraw.Draw(img)
    # degradado vertical suave
    top, bottom = (0x19, 0x76, 0xD2), (0x0D, 0x47, 0xA1)
    for y in range(h):
        t = y / (h - 1)
        d.line([(0, y), (w, y)], fill=tuple(int(a + (b - a) * t) for a, b in zip(top, bottom)))
    icon = draw_icon(176 * 4).resize((176, 176), Image.LANCZOS)
    img.paste(icon, (56, (h - 176) // 2), icon)
    font_dir = "/usr/share/fonts/truetype/dejavu"
    try:
        big = ImageFont.truetype(os.path.join(font_dir, "DejaVuSans-Bold.ttf"), 72)
        small = ImageFont.truetype(os.path.join(font_dir, "DejaVuSans.ttf"), 30)
    except OSError:
        big = small = ImageFont.load_default()
    d.text((268, 150), "Office Móvil", font=big, fill="white")
    d.text((272, 245), "Documentos · Hojas · Presentaciones", font=small, fill="#E3F2FD")
    out = os.path.join(RES, "drawable", "drawer_header.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.save(out, optimize=True)


if __name__ == "__main__":
    vectors()
    pngs()
    header()
    print("Íconos generados en", RES)
