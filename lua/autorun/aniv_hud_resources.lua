--[[---------------------------------------------------------------------------
 ANEURISM IV HUD for Garry's Mod
 File: lua/autorun/aniv_hud_resources.lua

 Why this file exists
 --------------------
 A dedicated GMod server only streams *Lua* to clients automatically. Materials,
 VMTs and fonts sitting in an addon are NOT sent, so the client renders the
 pink/black checkerboard "error" material instead of the HUD artwork.

 resource.AddFile() registers each file for client download (built-in UDP
 download or FastDL / sv_downloadurl). This is the fix for the checkerboard.

 Runs on the server only; the client side of this file does nothing.
---------------------------------------------------------------------------]]

if not SERVER then return end
if not resource or not resource.AddFile then return end

local FILES = {
	-- Radio sprite + its material (both are required: the VMT points at the PNG).
	"materials/aneurism_hud/walkie_talkie.vmt",
	"materials/aneurism_hud/walkie_talkie.png",
	-- Procedural surfaces (paper / plastic / metal).
	"materials/aneurism_hud/paper.vmt",
	"materials/aneurism_hud/paper.png",
	"materials/aneurism_hud/plastic.vmt",
	"materials/aneurism_hud/plastic.png",
	"materials/aneurism_hud/metal.vmt",
	"materials/aneurism_hud/metal.png",
	-- Status glyphs + context-prompt glyphs (original game sprites).
	"materials/aneurism_hud/icon_blood.vmt",
	"materials/aneurism_hud/icon_blood.png",
	"materials/aneurism_hud/icon_bone.vmt",
	"materials/aneurism_hud/icon_bone.png",
	"materials/aneurism_hud/icon_leg.vmt",
	"materials/aneurism_hud/icon_leg.png",
	"materials/aneurism_hud/icon_skull.vmt",
	"materials/aneurism_hud/icon_skull.png",
	"materials/aneurism_hud/icon_check.vmt",
	"materials/aneurism_hud/icon_check.png",
	"materials/aneurism_hud/icon_eye.vmt",
	"materials/aneurism_hud/icon_eye.png",
	-- Real ANEURISM IV UI sprites used by MYRP menus.
	"materials/aneurism_hud/inv_slot.png",
	"materials/aneurism_hud/ui_button_bg.png",
	"materials/aneurism_hud/ui_panel.png",
	-- Two stat bars: original capsule frame + tintable noise fill.
	"materials/aneurism_hud/bar_frame.vmt",
	"materials/aneurism_hud/bar_frame.png",
	"materials/aneurism_hud/bar_noise.vmt",
	"materials/aneurism_hud/bar_noise.png",
	-- Pixel fonts used by the HUD.
	"resource/fonts/Silkscreen-Regular.ttf",
	"resource/fonts/VT323-Regular.ttf",
}

local missing = 0

for _, path in ipairs(FILES) do
	if file.Exists(path, "GAME") then
		resource.AddFile(path)
		MsgN("[ANIV][SERVER] Added client download: " .. path)
	else
		missing = missing + 1
		MsgN("[ANIV][SERVER][WARN] Missing file: " .. path
			.. " (expected inside addons/aneurism_hud/)")
	end
end

MsgN("[ANIV][SERVER] HUD content registered: " .. (#FILES - missing)
	.. "/" .. #FILES .. " files.")
