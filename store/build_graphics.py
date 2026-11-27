"""Builds the store graphics from assets/icon. Run from the repo root:
    python3 store/build_graphics.py
Needs Pillow (pip install pillow). Outputs go to store/play and store/appstore."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON = Image.open(f"{ROOT}/assets/icon/icon.png").convert("RGB")
LOGO = Image.open(f"{ROOT}/assets/icon/splash_logo.png").convert("RGBA")

def font(paths, size):
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

LATIN_BOLD = ["/usr/share/fonts/opentype/inter/Inter-Bold.otf", "/System/Library/Fonts/Helvetica.ttc",
              "/Library/Fonts/Arial Bold.ttf", "C:/Windows/Fonts/arialbd.ttf"]
LATIN_REG = ["/usr/share/fonts/opentype/inter/Inter-SemiBold.otf", "/System/Library/Fonts/Helvetica.ttc",
             "/Library/Fonts/Arial.ttf", "C:/Windows/Fonts/arial.ttf"]
ARABIC = ["/System/Library/Fonts/GeezaPro.ttc", "/Library/Fonts/Arial Unicode.ttf",
          "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "C:/Windows/Fonts/arialbd.ttf"]

def gradient(w, h):
    c0, c1, c2 = (0x0E, 0x17, 0x45), (0x2A, 0x54, 0xE8), (0x3C, 0xC8, 0xFF)
    im = Image.new("RGB", (w, h)); px = im.load()
    for y in range(h):
        for x in range(w):
            t = (x * 0.7 + y * 0.3) / (w * 0.7 + h * 0.3)
            if t < .62:
                a, b, k = c0, c1, t / .62
            else:
                a, b, k = c1, c2, (t - .62) / .38
            px[x, y] = tuple(int(a[i] * (1 - k) + b[i] * k) for i in range(3))
    return im

def wrap(draw, text, fnt, max_w):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=fnt) <= max_w:
            cur = t
        else:
            lines.append(cur); cur = w
    if cur: lines.append(cur)
    return lines

TEXTS = {
    "en": ("DocuMind AI", "Understand any document in seconds", ["Summaries", "Risks", "Deadlines"], False),
    "fr": ("DocuMind IA", "Comprenez vos documents en quelques secondes", ["Résumés", "Risques", "Échéances"], False),
    "ar": ("DocuMind AI", "افهم أي مستند في ثوانٍ", ["ملخصات", "مخاطر", "مواعيد"], True),
}

def feature_graphic(lang):
    W, H = 1024, 500
    name, tagline, pills, rtl = TEXTS[lang]
    bg = gradient(W, H).convert("RGBA")
    # soft glow behind the glyph
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([590, 20, 1010, 460], fill=(120, 190, 255, 90))
    bg = Image.alpha_composite(bg, glow.filter(ImageFilter.GaussianBlur(60)))
    glyph = LOGO.resize((470, 470), Image.LANCZOS)
    gx = 40 if rtl else W - 500
    bg.alpha_composite(glyph, (gx, 15))
    d = ImageDraw.Draw(bg)
    title_f = font(ARABIC if rtl else LATIN_BOLD, 40)
    tag_f = font(ARABIC if rtl else LATIN_BOLD, 46 if lang == "en" else 42)
    pill_f = font(ARABIC if rtl else LATIN_REG, 24)
    left, right = (W - 70, W - 70) if rtl else (64, 64)
    block_w = 520
    x0 = (W - 70 - block_w) if rtl else 64
    # app icon + name
    icon = ICON.resize((76, 76), Image.LANCZOS)
    mask = Image.new("L", (76, 76), 0); ImageDraw.Draw(mask).rounded_rectangle([0, 0, 75, 75], 18, fill=255)
    ix = (x0 + block_w - 76) if rtl else x0
    bg.paste(icon, (ix, 70), mask)
    nx = (ix - 18 - d.textlength(name, font=title_f)) if rtl else ix + 94
    d.text((nx, 90), name, font=title_f, fill=(255, 255, 255, 255))
    # tagline (wrapped)
    y = 185
    for line in wrap(d, tagline, tag_f, block_w):
        lx = (x0 + block_w - d.textlength(line, font=tag_f)) if rtl else x0
        d.text((lx, y), line, font=tag_f, fill=(255, 255, 255, 255))
        y += int(tag_f.size * 1.25)
    # pills
    y = max(y + 24, 380)
    cursor = x0 + block_w if rtl else x0
    for p in pills:
        tw = d.textlength(p, font=pill_f)
        w = int(tw + 40)
        px = cursor - w if rtl else cursor
        layer = Image.new("RGBA", bg.size, (0, 0, 0, 0))
        ImageDraw.Draw(layer).rounded_rectangle([px, y, px + w, y + 52], 26, fill=(255, 255, 255, 40), outline=(255, 255, 255, 140), width=2)
        bg.alpha_composite(layer)
        d = ImageDraw.Draw(bg)
        d.text((px + 20, y + 9), p, font=pill_f, fill=(255, 255, 255, 255))
        cursor = px - 14 if rtl else px + w + 14
    return bg.convert("RGB")

os.makedirs(f"{ROOT}/store/play", exist_ok=True)
os.makedirs(f"{ROOT}/store/appstore", exist_ok=True)
# Google Play: 512x512 icon (square; Play applies its own rounding) and 1024x500 feature graphics
ICON.resize((512, 512), Image.LANCZOS).save(f"{ROOT}/store/play/icon-512.png", optimize=True)
for lang in TEXTS:
    feature_graphic(lang).save(f"{ROOT}/store/play/feature-graphic-{lang}-1024x500.png", optimize=True)
# App Store: 1024x1024, no transparency, no rounded corners
ICON.resize((1024, 1024), Image.LANCZOS).convert("RGB").save(f"{ROOT}/store/appstore/icon-1024.png", optimize=True)
print("done")
