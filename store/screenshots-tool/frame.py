"""Turns raw phone screenshots into store-ready images: gradient background,
a headline on top, and the screenshot in a rounded frame bleeding off the bottom.

Usage (from the repo root, needs Pillow: pip install pillow):
    python3 store/screenshots-tool/frame.py --lang en --size play --in my_shots --out store/out/play-en
    python3 store/screenshots-tool/frame.py --lang fr --size ios  --in my_shots --out store/out/ios-fr

* --in   folder of screenshots (PNG/JPG), named so they sort in the order you want (01.png, 02.png...)
* --size play = 1080x1920 (Google Play phone), ios = 1290x2796 (App Store 6.7")
* --lang en | fr | ar picks the headlines from captions.json (same order as the screenshots)
Edit captions.json to change the headlines.
"""
import argparse, json, os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
SIZES = {"play": (1080, 1920), "ios": (1290, 2796)}

LATIN = ["/usr/share/fonts/opentype/inter/Inter-Bold.otf", "/System/Library/Fonts/Helvetica.ttc",
         "/Library/Fonts/Arial Bold.ttf", "C:/Windows/Fonts/arialbd.ttf"]
ARABIC = ["/System/Library/Fonts/GeezaPro.ttc", "/Library/Fonts/Arial Unicode.ttf",
          "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", "C:/Windows/Fonts/arialbd.ttf"]

def font(paths, size):
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

def gradient(w, h):
    c0, c1, c2 = (0x0E, 0x17, 0x45), (0x2A, 0x54, 0xE8), (0x3C, 0xC8, 0xFF)
    small = Image.new("RGB", (64, 64)); px = small.load()
    for y in range(64):
        for x in range(64):
            t = (x * 0.35 + y * 0.65) / 64
            a, b, k = (c0, c1, t / .62) if t < .62 else (c1, c2, (t - .62) / .38)
            px[x, y] = tuple(int(a[i] * (1 - k) + b[i] * k) for i in range(3))
    return small.resize((w, h), Image.BICUBIC)

def wrap(d, text, fnt, max_w, rtl):
    lines, cur = [], ""
    for word in text.split():
        t = (cur + " " + word).strip()
        width = d.textlength(t, font=fnt, direction="rtl") if rtl else d.textlength(t, font=fnt)
        if width <= max_w:
            cur = t
        else:
            lines.append(cur); cur = word
    if cur: lines.append(cur)
    return lines

def frame(shot, caption, size, lang):
    W, H = size
    rtl = lang == "ar"
    bg = gradient(W, H).convert("RGBA")
    d = ImageDraw.Draw(bg)
    fnt = font(ARABIC if rtl else LATIN, int(W * 0.072))
    lines = wrap(d, caption, fnt, W * 0.84, rtl)[:3]
    y = int(H * 0.065)
    for line in lines:
        w = d.textlength(line, font=fnt, direction="rtl") if rtl else d.textlength(line, font=fnt)
        kw = {"direction": "rtl"} if rtl else {}
        d.text(((W - w) / 2, y), line, font=fnt, fill="white", **kw)
        y += int(fnt.size * 1.3)
    top = max(y + int(H * 0.035), int(H * 0.2))
    sw = int(W * 0.80)
    sh = int(shot.height * sw / shot.width)
    shot = shot.convert("RGB").resize((sw, sh), Image.LANCZOS)
    bezel = int(W * 0.012)
    radius = int(W * 0.06)
    ph_w, ph_h = sw + bezel * 2, H - top + 200
    # screenshot with rounded corners inside a dark bezel, bleeding off the bottom
    body = Image.new("RGBA", (ph_w, ph_h), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle([0, 0, ph_w - 1, ph_h + radius], radius + bezel, fill=(12, 16, 36, 255))
    mask = Image.new("L", (sw, ph_h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw - 1, ph_h + radius], radius, fill=255)
    body.paste(shot.crop((0, 0, sw, min(sh, ph_h - bezel))), (bezel, bezel), mask.crop((0, 0, sw, min(sh, ph_h - bezel))))
    x = (W - ph_w) // 2
    shadow = Image.new("RGBA", bg.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle([x, top + 24, x + ph_w, top + ph_h], radius + bezel, fill=(0, 0, 20, 140))
    bg.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(28)))
    bg.alpha_composite(body, (x, top))
    return bg.convert("RGB")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lang", default="en", choices=["en", "fr", "ar"])
    ap.add_argument("--size", default="play", choices=list(SIZES))
    ap.add_argument("--in", dest="src", required=True)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()
    captions = json.load(open(os.path.join(HERE, "captions.json"), encoding="utf-8"))[a.lang]
    files = sorted(f for f in os.listdir(a.src) if f.lower().endswith((".png", ".jpg", ".jpeg")))
    if not files:
        sys.exit("No screenshots found in " + a.src)
    os.makedirs(a.out, exist_ok=True)
    for i, f in enumerate(files):
        caption = captions[i] if i < len(captions) else ""
        img = frame(Image.open(os.path.join(a.src, f)), caption, SIZES[a.size], a.lang)
        out = os.path.join(a.out, f"{i + 1:02d}.png")
        img.save(out, optimize=True)
        print("saved", out)

if __name__ == "__main__":
    main()
