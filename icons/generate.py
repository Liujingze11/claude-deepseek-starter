#!/usr/bin/env python3
"""Generate .png, .ico, .icns from launcher.svg and installer.svg.

Usage: python3 icons/generate.py
Output: icons/launcher.{png,ico,icns}, icons/installer.{png,ico,icns}
"""

import io
import struct
import sys
from pathlib import Path

import cairosvg
from PIL import Image, ImageDraw, ImageFont

ICONS_DIR = Path(__file__).resolve().parent

# .icns icon type constants
ICN_TYPES = {
    16:  b"ic13",
    32:  b"ic11",
    64:  b"ic12",
    128: b"ic07",
    256: b"ic08",
    512: b"ic09",
    1024: b"ic10",
}


def svg_to_png(svg_path: Path, size: int) -> Image.Image:
    """Render SVG to PIL Image at given square size."""
    png_bytes = cairosvg.svg2png(
        url=str(svg_path),
        output_width=size,
        output_height=size,
    )
    return Image.open(io.BytesIO(png_bytes))


def simplified_icon(size: int, bg_color: tuple, fg_color: tuple) -> Image.Image:
    """Generate a simplified 'C' icon for very small sizes (<=32px)."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    radius = max(2, size // 5)
    draw.rounded_rectangle(
        [(0, 0), (size - 1, size - 1)],
        radius=radius,
        fill=bg_color,
    )

    try:
        font_size = int(size * 0.6)
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
    except (OSError, IOError):
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), "C", font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1]
    draw.text((x, y), "C", fill=fg_color, font=font)
    return img


def build_ico(svg_path: Path, out_path: Path, name: str):
    """Build multi-size .ico file (manual construction for Pillow 12 compat)."""
    sizes = [16, 32, 48, 256]
    png_datas = []

    bg = (15, 23, 42)    # #0f172a
    fg = (79, 195, 247)  # #4fc3f7
    if "installer" in name:
        bg = (26, 35, 126)  # #1a237e

    for s in sizes:
        if s <= 32:
            img = simplified_icon(s, bg, fg)
        else:
            img = svg_to_png(svg_path, s)
        buf = io.BytesIO()
        img.save(buf, format="PNG")
        png_datas.append(buf.getvalue())

    # Manual ICO construction: header (6) + N*entry(16) + PNG datas
    entry_size = 16
    header_size = 6
    data_offset = header_size + len(sizes) * entry_size

    with open(out_path, "wb") as f:
        # Header
        f.write(struct.pack("<HHH", 0, 1, len(sizes)))  # reserved, type=ICO, count
        # Entries
        offset = data_offset
        for s, png in zip(sizes, png_datas):
            w = 0 if s >= 256 else s
            h = 0 if s >= 256 else s
            f.write(struct.pack("<BBBBHHII", w, h, 0, 0, 1, 32, len(png), offset))
            offset += len(png)
        # PNG data
        for png in png_datas:
            f.write(png)

    print(f"  Created {out_path} ({out_path.stat().st_size} bytes)")


def build_icns(svg_path: Path, out_path: Path, name: str):
    """Build .icns file from SVG."""
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    png_entries = []

    bg = (15, 23, 42)
    fg = (79, 195, 247)
    if "installer" in name:
        bg = (26, 35, 126)

    for s in sizes:
        if s <= 32:
            img = simplified_icon(s, bg, fg)
        else:
            img = svg_to_png(svg_path, s)

        buf = io.BytesIO()
        img.save(buf, format="PNG")
        png_bytes = buf.getvalue()
        png_entries.append((ICN_TYPES[s], png_bytes))

    header_size = 8
    entry_header_size = 8
    total_size = header_size
    for itype, data in png_entries:
        total_size += entry_header_size + len(data)

    with open(out_path, "wb") as f:
        f.write(b"icns")
        f.write(struct.pack(">I", total_size))
        for itype, data in png_entries:
            entry_size = entry_header_size + len(data)
            f.write(itype)
            f.write(struct.pack(">I", entry_size))
            f.write(data)

    print(f"  Created {out_path} ({out_path.stat().st_size} bytes)")


def build_png(svg_path: Path, out_path: Path):
    """Build 128px PNG for Linux desktop entry."""
    img = svg_to_png(svg_path, 128)
    img.save(out_path, format="PNG")
    print(f"  Created {out_path} ({out_path.stat().st_size} bytes)")


def main():
    names = ["launcher", "installer"]
    for name in names:
        svg = ICONS_DIR / f"{name}.svg"
        if not svg.exists():
            print(f"ERROR: {svg} not found", file=sys.stderr)
            sys.exit(1)

        print(f"Generating icons for {name}...")
        build_ico(svg, ICONS_DIR / f"{name}.ico", name)
        build_icns(svg, ICONS_DIR / f"{name}.icns", name)
        build_png(svg, ICONS_DIR / f"{name}.png")

    print("Done. All icon binaries generated.")


if __name__ == "__main__":
    main()
