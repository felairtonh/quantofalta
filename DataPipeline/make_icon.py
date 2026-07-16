#!/usr/bin/env python3
"""Renders the AlbumTracker app icon (1024px): a gold foil '26' sticker with a
soccer ball, tilted over a pitch-green striped background. Drawn at 2x and
downscaled for anti-aliasing."""
import math
import sys
from PIL import Image, ImageDraw, ImageFilter, ImageFont

S = 2048  # working canvas; output 1024
OUT = sys.argv[1] if len(sys.argv) > 1 else "AppIcon.png"


def hexc(h, a=255):
    return ((h >> 16) & 255, (h >> 8) & 255, h & 255, a)


# ---- background: vertical pitch gradient + diagonal mowing stripes ----
img = Image.new("RGBA", (S, S))
top, bottom = hexc(0x11A257), hexc(0x0A6B3A)
bg = ImageDraw.Draw(img)
for y in range(S):
    t = y / S
    bg.line([(0, y), (S, y)], fill=tuple(
        int(top[i] + (bottom[i] - top[i]) * t) for i in range(4)))

stripes = Image.new("RGBA", (S, S), (0, 0, 0, 0))
sd = ImageDraw.Draw(stripes)
x = -800
while x < S + 400:
    sd.polygon([(x, S), (x + 260, S), (x + 260 + 520, 0), (x + 520, 0)],
               fill=(255, 255, 255, 13))
    x += 520
img.alpha_composite(stripes)

# ---- sticker layer (drawn unrotated, then rotated & composited) ----
W, H = 1180, 1400
layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ld = ImageDraw.Draw(layer)
x0, y0 = (S - W) // 2, (S - H) // 2
rect = (x0, y0, x0 + W, y0 + H)

# gold base + vertical-ish gradient via mask
ld.rounded_rectangle(rect, radius=120, fill=hexc(0xF2C95C))
grad = Image.new("L", (1, H))
for y in range(H):
    grad.putpixel((0, y), int(255 * (y / H) * 0.55))
grad = grad.resize((W, H))
dark = Image.new("RGBA", (W, H), hexc(0xC8861F))
goldmask = Image.new("L", (S, S), 0)
ImageDraw.Draw(goldmask).rounded_rectangle(rect, radius=120, fill=255)
layer.paste(dark, (x0, y0), Image.composite(grad, Image.new("L", (W, H), 0),
                                            goldmask.crop(rect)))

# diagonal sheen
sheen = Image.new("L", (W, H), 0)
shd = ImageDraw.Draw(sheen)
for i in range(W + H):
    a = max(0, 90 - int(i / (W + H) * 260))
    if a:
        shd.line([(i, 0), (0, i)], fill=a)
white = Image.new("RGBA", (W, H), (255, 255, 255, 255))
layer.paste(white, (x0, y0), Image.composite(sheen, Image.new("L", (W, H), 0),
                                             goldmask.crop(rect)))

# white sticker edge
ld.rounded_rectangle(rect, radius=120, outline=(255, 255, 255, 245), width=30)

# dashed inner slot border (straight segments only)
ins = 96
ix0, iy0, ix1, iy1 = x0 + ins, y0 + ins, x0 + W - ins, y0 + H - ins
dash, gap, wd, col = 62, 44, 16, hexc(0x6B4E00, 130)
corner = 80
for (ax, ay, bx, by) in [(ix0 + corner, iy0, ix1 - corner, iy0),
                         (ix0 + corner, iy1, ix1 - corner, iy1)]:
    x = ax
    while x < bx:
        ld.line([(x, ay), (min(x + dash, bx), by)], fill=col, width=wd)
        x += dash + gap
for (ax, ay, bx, by) in [(ix0, iy0 + corner, ix0, iy1 - corner),
                         (ix1, iy0 + corner, ix1, iy1 - corner)]:
    y = ay
    while y < by:
        ld.line([(ax, y), (bx, min(y + dash, by))], fill=col, width=wd)
        y += dash + gap

# soccer ball (simple): white circle, pentagon, spokes
cx, cy, r = S // 2, y0 + 400, 150
ld.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, 255),
           outline=hexc(0x333333), width=10)
pent = [(cx + 62 * math.sin(a), cy - 62 * math.cos(a))
        for a in [math.radians(72 * i) for i in range(5)]]
ld.polygon(pent, fill=hexc(0x222222))
for px, py in pent:
    vx, vy = px - cx, py - cy
    n = math.hypot(vx, vy)
    ld.line([(px, py), (cx + vx / n * (r - 14), cy + vy / n * (r - 14))],
            fill=hexc(0x222222), width=12)

# "26"
font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", 660)
ld.text((S // 2, y0 + H - 460), "26", font=font, fill=hexc(0x6B4E00), anchor="mm")

# rotate sticker with soft shadow
rot = layer.rotate(7, resample=Image.BICUBIC, center=(S // 2, S // 2))
alpha = rot.split()[3].point(lambda a: int(a * 0.45))
shadow = Image.merge("RGBA", (Image.new("L", (S, S), 0),) * 3 + (alpha,))
shadow = shadow.filter(ImageFilter.GaussianBlur(46))
img.alpha_composite(shadow, (0, 34))
img.alpha_composite(rot)

img = img.resize((1024, 1024), Image.LANCZOS).convert("RGB")
img.save(OUT, "PNG")
print("wrote", OUT)
