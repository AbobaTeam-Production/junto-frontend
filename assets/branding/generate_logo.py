"""Generate the Junto placeholder logo set.

Produces three PNGs in the same folder:
  - logo_1024.png   — full bleed 1024x1024 with letter on amber/dark gradient,
                      consumed by flutter_launcher_icons (Android adaptive +
                      Web favicon).
  - logo_foreground_1024.png — transparent-background "J" only, used as the
                      Android adaptive-icon foreground layer (the launcher
                      crops it to circle/squircle/teardrop on Pixel/Samsung).
  - splash_512.png  — square logo on transparent for the splash centerpiece.

Re-run with `python assets/branding/generate_logo.py` if the colour palette
ever shifts in `lib/core/theme/app_colors.dart` — the constants below are
mirrored from there.
"""

from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

# Mirrors lib/core/theme/app_colors.dart
BG_DEEP = (16, 16, 20, 255)         # AppColors.bgDeep — splash + safe area
SURFACE = (28, 28, 34, 255)         # subtle ring around the medallion
AMBER = (235, 178, 90, 255)         # AppColors.amber — accent ring + glyph
INK = (245, 240, 230, 255)          # off-white inside the medallion

OUT_DIR = Path(__file__).parent


def _load_font(size: int) -> ImageFont.ImageFont:
    """Pick a serif-ish font that ships with most Windows installs.
    Falls back to PIL default if nothing matches — the layout still works
    but kerning of the single glyph will look generic."""
    for name in ('georgiab.ttf', 'georgia.ttf', 'palab.ttf', 'arialbd.ttf'):
        try:
            return ImageFont.truetype(name, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def _draw_glyph(draw: ImageDraw.ImageDraw, size: int, color):
    """Centre a "J" inside an `size`x`size` box, optically nudged so the
    descender sits visually balanced (PIL centres the *bbox*, which pulls
    the J too high)."""
    font = _load_font(int(size * 0.62))
    glyph = 'J'
    # measure
    try:
        l, t, r, b = font.getbbox(glyph)
    except AttributeError:
        l, t, r, b = (0, 0, *font.getsize(glyph))
    w, h = r - l, b - t
    x = (size - w) / 2 - l
    # Nudge down ~3% so the descender lands near the optical centre.
    y = (size - h) / 2 - t + size * 0.03
    draw.text((x, y), glyph, font=font, fill=color)


def make_full_logo(out: Path):
    size = 1024
    img = Image.new('RGBA', (size, size), BG_DEEP)
    d = ImageDraw.Draw(img)

    # Outer amber ring — restrained so the icon reads at 48dp launcher size.
    pad = int(size * 0.08)
    d.ellipse(
        [pad, pad, size - pad, size - pad],
        outline=AMBER, width=int(size * 0.012),
    )

    # Inner darker medallion to keep contrast under bright launcher backdrops.
    inner_pad = int(size * 0.13)
    d.ellipse(
        [inner_pad, inner_pad, size - inner_pad, size - inner_pad],
        fill=SURFACE,
    )

    _draw_glyph(d, size, AMBER)
    img.save(out)
    print(f'wrote {out} ({size}x{size})')


def make_foreground(out: Path):
    """Adaptive-icon foreground: glyph + ring on transparent. Android's
    launcher will compose its own circular/squircle background and clip
    this layer to it."""
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # The safe-zone for adaptive icons is the inner 66% of the canvas, so we
    # render the full medallion at ~58% to leave breathing room.
    medallion_pad = int(size * 0.21)
    d.ellipse(
        [medallion_pad, medallion_pad, size - medallion_pad, size - medallion_pad],
        fill=BG_DEEP,
    )
    ring_pad = medallion_pad - int(size * 0.005)
    d.ellipse(
        [ring_pad, ring_pad, size - ring_pad, size - ring_pad],
        outline=AMBER, width=int(size * 0.011),
    )
    _draw_glyph(d, size, AMBER)
    img.save(out)
    print(f'wrote {out} ({size}x{size}, transparent)')


def make_splash(out: Path):
    """Splash centrepiece: amber-ringed medallion on transparent background.
    The splash plugin then composites this over `BG_DEEP` so it matches the
    very first frame Flutter paints."""
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pad = int(size * 0.04)
    d.ellipse(
        [pad, pad, size - pad, size - pad],
        outline=AMBER, width=int(size * 0.018),
    )
    inner_pad = int(size * 0.08)
    d.ellipse(
        [inner_pad, inner_pad, size - inner_pad, size - inner_pad],
        fill=SURFACE,
    )
    _draw_glyph(d, size, AMBER)
    img.save(out)
    print(f'wrote {out} ({size}x{size}, transparent)')


if __name__ == '__main__':
    make_full_logo(OUT_DIR / 'logo_1024.png')
    make_foreground(OUT_DIR / 'logo_foreground_1024.png')
    make_splash(OUT_DIR / 'splash_512.png')
