r"""Extract the original ANEURISM IV UI sprites used by this project.

Run with a Python that has UnityPy + Pillow, for example:
  C:\Users\geiad\.dsh\dsh-runtimes\dsh-primary-runtime\dependencies\python\python.exe tools\extract_unity_ui.py

Source:
  D:\SteamLibrary\steamapps\common\ANEURISM IV\ANEURISM IV_Data\data.unity3d

Outputs into materials/aneurism_hud/:
  ui_button_bg.png  - Sprite "button_bg" (352x48), the grimy interaction button.
  ui_panel.png      - Sprite "panel" (640x576), the dark scratched panel.
  icon_check.png    - Sprite "UICheckMark" (11x11) if you want to refresh it.

These are original Vellocet Software assets. Do NOT redraw them procedurally.
"""

from pathlib import Path
import UnityPy

ROOT = Path(__file__).resolve().parent.parent
DATA = Path(r"D:\SteamLibrary\steamapps\common\ANEURISM IV\ANEURISM IV_Data\data.unity3d")
OUT = ROOT / "materials" / "aneurism_hud"
WANT = {
    "button_bg": "ui_button_bg.png",
    "panel": "ui_panel.png",
    "UICheckMark": "icon_check.png",
}

env = UnityPy.load(str(DATA))
OUT.mkdir(parents=True, exist_ok=True)
done = set()

for obj in env.objects:
    if obj.type.name != "Sprite":
        continue
    name = obj.peek_name() or ""
    if name not in WANT or WANT[name] in done:
        continue
    try:
        sprite = obj.read()
        sprite.image.save(OUT / WANT[name])
        print(name, "->", WANT[name], sprite.image.size)
        done.add(WANT[name])
    except Exception as exc:
        print("ERR", name, exc)

print("extracted", len(done), "of", len(WANT), "sprites")
