# -*- coding: utf-8 -*-
"""Prepare the HUD icon materials for the ANEURISM IV GMod HUD.

The game (ANEURISM IV) ships its UI glyphs as 16x16 white sprites taken from
the open game-icons.net set.  We reuse the *original* in-game files whenever
they exist so the HUD matches the game pixel for pixel:

    blood_1708.png       -> icon_blood.png   (red drop)
    skull_812.png        -> icon_skull.png   (blue skull)
    eye_552.png          -> icon_eye.png     (Search)
    UICheckMark_1389.png -> icon_check.png   (Grab)

Two glyphs are not present in the game's texture dump (a broken bone and a
leg).  They are rendered from the same game-icons.net source set, so the
style, stroke weight and anti-aliasing match the rest of the HUD:

    game-icons.net/lorc/broken-bone.svg   -> icon_bone.png
    game-icons.net/delapouite/leg.svg     -> icon_leg.png

Usage (paths are only needed when regenerating the PNGs):

    py tools/prepare_icons.py [game_texture_dir] [rasterised_icons_dir]

The PNGs are committed to materials/aneurism_hud/, so running this script is
optional for a normal install.
"""

import os
import shutil
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAT = os.path.join(ROOT, "materials", "aneurism_hud")

SRC = sys.argv[1] if len(sys.argv) > 1 else r"C:\Users\geiad\AppData\Local\Temp\opencode\a4tex"
GI = sys.argv[2] if len(sys.argv) > 2 else r"C:\Users\geiad\AppData\Local\Temp\opencode\gicons\out"

# name in the addon -> source file
RAW = {
    "icon_blood.png": os.path.join(SRC, "blood_1708.png"),
    "icon_skull.png": os.path.join(SRC, "skull_812.png"),
    "icon_eye.png": os.path.join(SRC, "eye_552.png"),
    "icon_check.png": os.path.join(SRC, "UICheckMark_1389.png"),
}

# Icons that need transparent margins trimmed and the glyph re-centred.
FIT = {
    "icon_bone.png": (os.path.join(GI, "broken-bone-32.png"), 32),
    "icon_leg.png": (os.path.join(GI, "leg.png"), 16),
}


def save_raw(src, dst):
    im = Image.open(src).convert("RGBA")
    im.save(dst)
    print("copied  %-18s %dx%d" % (os.path.basename(dst), im.size[0], im.size[1]))


def save_fit(src, dst, size):
    im = Image.open(src).convert("RGBA")
    bbox = im.getbbox()
    if bbox:
        im = im.crop(bbox)
    if im.size[0] > size or im.size[1] > size:
        im.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(im, ((size - im.size[0]) // 2, (size - im.size[1]) // 2))
    canvas.save(dst)
    print("fitted  %-18s %dx%d" % (os.path.basename(dst), size, size))


def write_vmt(name):
    path = os.path.join(MAT, name + ".vmt")
    text = (
        '"UnlitGeneric"\n'
        "{\n"
        '\t"$basetexture" "aneurism_hud/%s"\n'
        '\t"$translucent" "1"\n'
        '\t"$vertexalpha" "1"\n'
        '\t"$vertexcolor" "1"\n'
        '\t"$nocull" "1"\n'
        '\t"$pointsample" "1"\n'
        "}\n"
    ) % name
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    print("vmt     %-18s" % (name + ".vmt"))


def main():
    os.makedirs(MAT, exist_ok=True)
    missing = False
    for dst_name, src in RAW.items():
        if not os.path.exists(src):
            print("MISSING", src)
            missing = True
            continue
        save_raw(src, os.path.join(MAT, dst_name))
    for dst_name, (src, size) in FIT.items():
        if not os.path.exists(src):
            print("MISSING", src)
            missing = True
            continue
        save_fit(src, os.path.join(MAT, dst_name), size)

    for name in ("icon_blood", "icon_skull", "icon_bone", "icon_leg",
                 "icon_check", "icon_eye"):
        write_vmt(name)

    if missing:
        raise SystemExit("some source sprites were not found")


if __name__ == "__main__":
    main()
