r"""Build authentic ANEURISM IV stat-bar textures from the wiki reference crop.

Run with a Python that has Pillow:
  C:\Users\geiad\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe tools\make_bar_textures.py

The reference (docs/refs/hud_bars_reference.png, 363x310) is a real in-game
screenshot from aneurism.wiki.gg (File:HUDBarsUpdate17.png). The blood row sits
at y=51..94, the air row at y=94..137, and the capsule itself spans x=50..315.

Outputs (into materials/aneurism_hud/):
  bar_frame.png  - the original worn grey capsule with its interior blacked
                   out, so we can draw a dynamic noisy fill ourselves.
  bar_noise.png  - the original red speckle pattern converted to greyscale,
                   used as a tintable 1-texel = 1-pixel noise surface.
"""

from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
REF = ROOT / "docs" / "refs" / "hud_bars_reference.png"
OUT = ROOT / "materials" / "aneurism_hud"

# Capsule bounding box inside one 43 px row of the reference.
X0, X1 = 50, 315
Y0, Y1 = 0, 39
# Interior (fill area) inside the cropped capsule.
IX0, IX1 = 20, 245
IY0, IY1 = 8, 31

im = Image.open(REF).convert("RGB")
OUT.mkdir(parents=True, exist_ok=True)

# --- frame: take the blood capsule, erase the interior --------------------
frame = im.crop((X0, 51 + Y0, X1, 51 + Y1)).convert("RGBA")
px = frame.load()
for x in range(IX0, IX1):
    for y in range(IY0, IY1):
        px[x, y] = (0, 0, 0, 255)
frame.save(OUT / "bar_frame.png")

# --- noise: use the real red speckles from the blood bar -----------------
# Take a label-free slice; the baked "blood" text would otherwise end up in
# the noise tile and show through our own uppercase label.
noise = im.crop((75, 51 + IY0, 150, 51 + IY1)).convert("L")
noise = ImageOps.autocontrast(noise, cutoff=1)
noise = noise.resize((128, 32), Image.Resampling.NEAREST)
noise.convert("RGB").save(OUT / "bar_noise.png")

print("generated bar_frame.png and bar_noise.png from", REF.name)
