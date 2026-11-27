--[[---------------------------------------------------------------------------
 ANEURISM IV HUD - rendering
 File: lua/autorun/client/aniv_hud_core.lua

 Draw order: radio -> stat bars (or legacy icons) -> context prompts -> CRT overlay.
 All coordinates are derived from ANIV.Scale() so the layout stays proportional
 from 720p to 4K. Layout rects are exported for the input module.
---------------------------------------------------------------------------]]

-- 12x12 pixel-art icon patterns (one char = one pixel cell).
ANIV.PAT = {
	blood = {
		"....##......",
		"...####.....",
		"..######....",
		".########...",
		"############",
		"############",
		".########...",
		"..######....",
		"...####.....",
		"....##......",
	},
	bone = {
		"............",
		"###.....###.",
		".###...###..",
		"..##...##...",
		"..##...##...",
		".###...###..",
		"###.....###.",
		"............",
	},
	leg = {
		"..###.......",
		"..###.......",
		"..###.......",
		"..###.......",
		"..####......",
		"..####......",
		"..######....",
		"..########..",
		"..########..",
		"............",
	},
	skull = {
		"...####.....",
		"..######....",
		".########...",
		"##.####.##..",
		"##.####.##..",
		".########...",
		"..######....",
		"...##..##...",
		"...##..##...",
		"............",
	},
	check = {
		"..........##",
		".........###",
		"........###.",
		".##....###..",
		".###..###...",
		"..######....",
		"...####.....",
		"....##......",
	},
	eye = {
		"............",
		"...####.....",
		".##.##.##...",
		"##..##..##..",
		"##.####.##..",
		"##.####.##..",
		"##..##..##..",
		".##.##.##...",
		"...####.....",
		"............",
	},
}

--- Generic pixel-grid renderer.
function ANIV.DrawPattern(pat, x, y, size, col)
	surface.SetDrawColor(col)
	local w = #pat[1]
	local cell = size / w
	for row = 1, #pat do
		local line = pat[row]
		for colI = 1, w do
			if string.sub(line, colI, colI) == "#" then
				surface.DrawRect(x + (colI - 1) * cell, y + (row - 1) * cell, cell + 0.5, cell + 0.5)
			end
		end
	end
end

--- Export widget rectangles (used by input.lua for hit-testing).
function ANIV.GetWidgetRects()
	local S = ANIV.S()
	local rw, rh = 250 * S, 278 * S
	local rx, ry = 22 * S, 16 * S

	local is = 44 * S
	local gap = 12 * S
	local total = 4 * is + 3 * gap
	local ix = ScrW() * 0.5 - total * 0.5 - 150 * S
	local iy = ScrH() - is - 34 * S

	return {
		radio = { x = rx, y = ry, w = rw, h = rh },
		icons = { x = ix, y = iy, size = is, gap = gap },
	}
end

--- Rectangle of the faction radio chat input (used by input.lua).
function ANIV.GetRadioChatRect()
	local S = ANIV.S()
	local w = 460 * S
	local h = 34 * S
	return { x = ScrW() * 0.5 - w * 0.5, y = ScrH() * 0.62, w = w, h = h }
end

---------------------------------------------------------------------------
-- Radio (upper-left)
---------------------------------------------------------------------------
local function DrawRadio(S)
	local r = ANIV.GetWidgetRects().radio
	local x, y, w, h = r.x, r.y, r.w, r.h

	-- 1:1 draw: integer-snapped rect, explicit full UV, aspect kept from the
	-- native 371x413 sprite. Falls back to flat colour if the client has no art.
	ANIV.DrawTex(ANIV.MAT.radio, x, y, w, h, Color(38, 42, 34, 255))

	-- LCD. The reference sprite has baked text; cover it with the amber
	-- backlight and draw our own dynamic text on top. The rect is computed from
	-- the real sprite pixels (ANIV.RADIO_LCD_UV), so it always lines up 1:1
	-- with the artwork instead of relying on guessed fractions.
	local uv = ANIV.RADIO_LCD_UV
	local sx = ANIV.Snap(x + uv.u0 * w)
	local sy = ANIV.Snap(y + uv.v0 * h)
	local sw = ANIV.Snap((uv.u1 - uv.u0) * w)
	local sh = ANIV.Snap((uv.v1 - uv.v0) * h)

	-- Two overlapping rects approximate the sprite's rounded LCD corners:
	-- the four corner pixels stay dark, so the bezel is not painted over.
	local inset = math.max(2, ANIV.Snap(3 * S))
	surface.SetDrawColor(186, 150, 84, 255)
	surface.DrawRect(sx + inset, sy, sw - inset * 2, sh)
	surface.DrawRect(sx, sy + inset, sw, sh - inset * 2)
	surface.SetDrawColor(214, 182, 118, 70)
	surface.DrawRect(sx + inset + 2, sy + 2, sw - inset * 2 - 4, sh - 4)
	surface.SetDrawColor(60, 44, 20, 150)
	surface.DrawRect(sx + inset, sy + inset, sw - inset * 2, 1)

	local talkKey = string.upper(GetConVar("aniv_hud_radio_chat_key"):GetString())
	local uiKey   = string.upper(GetConVar("aniv_hud_radio_key"):GetString())
	local active  = ANIV.State.radioActive
	local chatOpen = ANIV.State.radioChatOpen

	-- Same four-line LCD layout as the original, with text that reflects the
	-- faction radio state machine (OFF -> click -> ON -> X -> chat -> click).
	local status, l2, l3, l4
	if chatOpen then
		status = "BROADCASTING"
		l2 = "Type your message."
		l3 = "Enter to send."
		l4 = "Esc to cancel."
	elseif active then
		status = "UNMUTED."
		l2 = "Click to turn off."
		l3 = "Press " .. talkKey .. " to talk."
		l4 = "Faction channel."
	else
		status = "MUTED."
		l2 = "Click to turn on."
		l3 = uiKey .. ": unlock cursor"
		l4 = "Local chat active."
	end

	local statusCol = (chatOpen or ANIV.State.broadcasting) and Color(96, 30, 18)
		or Color(44, 28, 14)
	local lineCol = Color(62, 42, 20)

	-- Positions are fractions of the measured LCD height, then snapped.
	local pad = 7 * S
	ANIV.Text(status, sx + pad, ANIV.Snap(sy + sh * 0.06), 13 * S,
		statusCol, nil, nil, true, 0)
	ANIV.Text(l2, sx + pad, ANIV.Snap(sy + sh * 0.30), 9 * S,
		lineCol, nil, nil, true, 0)
	ANIV.Text(l3, sx + pad, ANIV.Snap(sy + sh * 0.51), 9 * S,
		lineCol, nil, nil, true, 0)
	ANIV.Text(l4, sx + pad, ANIV.Snap(sy + sh * 0.72), 9 * S,
		lineCol, nil, nil, true, 0)

	if ANIV.State.broadcasting then
		local blink = math.floor(CurTime() * 5) % 2 == 0
		if blink then
			-- Square pixel dot in the top-right corner of the LCD.
			local dot = math.max(3, ANIV.Snap(4 * S))
			surface.SetDrawColor(190, 48, 34, 255)
			surface.DrawRect(ANIV.Snap(sx + sw - dot - 5 * S),
				ANIV.Snap(sy + 7 * S), dot, dot)
		end
	end
end

-- The book/counter HUD element was removed entirely by user request.

---------------------------------------------------------------------------
-- Status icons (bottom, slightly left of center)
---------------------------------------------------------------------------
local ICONS = {
	{ name = "blood",  tex = "blood", pat = "blood", col = ANIV.COL.blood  },
	{ name = "bone",   tex = "bone",  pat = "bone",  col = ANIV.COL.bone   },
	{ name = "leg",    tex = "leg",   pat = "leg",   col = ANIV.COL.leg    },
	{ name = "sanity", tex = "skull", pat = "skull", col = ANIV.COL.sanity },
}

local function DrawStatusIcons(S)
	local r = ANIV.GetWidgetRects().icons
	local is, gap = ANIV.Snap(r.size), r.gap

	for i, def in ipairs(ICONS) do
		local x = ANIV.Snap(r.x + (i - 1) * (r.size + r.gap))
		local y = ANIV.Snap(r.y)
		local v = ANIV.GetStat(def.name) / 100
		local pat = ANIV.PAT[def.pat]
		local empty = Color(42, 46, 42, 255)

		-- Metal backing plate: tiled at 1 texel = 1 px (no stretching), with a
		-- dark inset well so the coloured glyph reads clearly.
		ANIV.DrawTexTiled(ANIV.MAT.metal, x - 3 * S, y - 3 * S, is + 6 * S, is + 6 * S,
			ANIV.TEX.metal.w, ANIV.TEX.metal.h,
			Color(58, 62, 56, 255), Color(150, 160, 148, 255))
		surface.SetDrawColor(14, 16, 14, 235)
		surface.DrawRect(x, y, is, is)

		-- Empty glyph (dark) underneath.
		if not ANIV.DrawIcon(def.tex, x, y, is, empty) then
			ANIV.DrawPattern(pat, x, y, is, empty)
		end

		-- Bright glyph, revealed bottom-up up to the stat value.
		if v > 0 then
			local col = def.col
			if v < 0.3 and math.floor(CurTime() * 6) % 2 == 0 then
				col = Color(236, 70, 56, 255)
			end
			local py = ANIV.Snap(y + is * (1 - v))
			local ph = math.max(1, ANIV.Snap(is * v))
			-- SetScissorRect takes x0,y0,x1,y1 with the origin at the BOTTOM
			-- left, not x,y,w,h. The old call left h nil visually (no fill).
			render.SetScissorRect(x, ScrH() - py - ph, x + is, ScrH() - py, true)
			if not ANIV.DrawIcon(def.tex, x, y, is, col) then
				ANIV.DrawPattern(pat, x, y, is, col)
			end
			render.SetScissorRect(0, 0, 0, 0, false)
		end

		surface.SetDrawColor(ANIV.COL.outline)
		surface.DrawOutlinedRect(x, y, is, is, 1)

		if GetConVar("aniv_hud_icon_labels"):GetBool() then
			ANIV.Text(string.upper(def.name), x + is * 0.5, y + is + 3 * S,
				8 * S, ANIV.COL.dim, TEXT_ALIGN_CENTER, nil, true, 0)
		end
	end
end

---------------------------------------------------------------------------
-- ANEURISM IV stat bars: only BLOOD and AIR (= stamina), from the game art
---------------------------------------------------------------------------
local BARS = {
	{ key = "blood", label = "BLOOD", col = Color(196, 44, 36, 255) },
	{ key = "air",   label = "AIR",   col = Color( 52, 96, 226, 255) },
}

-- Native capsule from the game screenshot: 265x39; interior fill window.
local FRAME_W, FRAME_H = 265, 39
local FILL_X, FILL_Y, FILL_W, FILL_H = 20, 8, 225, 23

--- rectangles of the two bars (bottom-centre, one horizontal row)
function ANIV.GetBarRects()
	local S = ANIV.S()
	local bw = ANIV.Snap(FRAME_W * S)
	local bh = ANIV.Snap(FRAME_H * S)
	local gap = ANIV.Snap(8 * S)
	local total = #BARS * bw + (#BARS - 1) * gap
	local x0 = ANIV.Snap(ScrW() * 0.5 - total * 0.5)
	local y  = ANIV.Snap(ScrH() - bh - 30 * S)

	local out = {}
	for i = 1, #BARS do
		out[i] = { x = x0 + (i - 1) * (bw + gap), y = y, w = bw, h = bh }
	end
	return out
end

local function DrawStatBars(S)
	local rects = ANIV.GetBarRects()
	local noise = ANIV.MAT.barNoise
	local tex = ANIV.TEX.bar_noise

	for i, def in ipairs(BARS) do
		local r = rects[i]
		local x, y = r.x, r.y

		-- The original worn capsule, taken from the real HUD sprite.
		ANIV.DrawTex(ANIV.MAT.barFrame, x, y, r.w, r.h, Color(58, 60, 54, 255))

		-- Its interior window, scaled from the source pixels.
		local ix = ANIV.Snap(x + FILL_X * S)
		local iy = ANIV.Snap(y + FILL_Y * S)
		local iw = ANIV.Snap(FILL_W * S)
		local ih = ANIV.Snap(FILL_H * S)

		-- Unfilled part: grey speckles (the empty segment in the game HUD).
		ANIV.DrawTexTiled(noise, ix, iy, iw, ih, tex.w, tex.h,
			Color(24, 24, 24, 255), Color(96, 98, 92, 255))

		-- Filled part: the real noise pattern tinted red / blue, left to right.
		local v = math.Clamp(ANIV.GetStat(def.key) / 100, 0, 1)
		local fw = ANIV.Snap(iw * v)
		if fw > 0 then
			ANIV.DrawTexTiled(noise, ix, iy, fw, ih, tex.w, tex.h,
				Color(16, 16, 16, 255), def.col)
		end

		-- Uppercase pixel label, exactly as on the screenshot.
		ANIV.Text(def.label, x + r.w * 0.5, y + r.h * 0.5, 15 * S,
			Color(238, 238, 230, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, false, 1)
	end
end

---------------------------------------------------------------------------
-- Context prompts ("Grab" / "Search")
---------------------------------------------------------------------------
function ANIV.GetContextPrompt()
	local ply = LocalPlayer()
	if not IsValid(ply) then return nil end
	local tr = ply:GetEyeTrace()
	local ent = tr.Entity
	if not IsValid(ent) or ent:IsWorld() then return nil end
	if ent.ANIV_HudPrompt == false then return nil end
	if ent.ANIV_HudPrompt then return ent.ANIV_HudPrompt end

	local maxDist = GetConVar("aniv_hud_prompt_dist"):GetFloat()
	if tr.HitPos:Distance(ply:EyePos()) > maxDist then return nil end

	if ent:IsPlayer() or ent:IsNPC() or ent:IsNextBot() then return "Search" end

	local cls = string.lower(ent:GetClass() or "")
	if string.find(cls, "weapon", 1, true) or string.find(cls, "item", 1, true)
		or string.find(cls, "ammo", 1, true) or string.find(cls, "ration", 1, true)
		or string.find(cls, "bandage", 1, true) or ent.ANIV_Grabbable then
		return "Grab"
	end
	if string.find(cls, "trash", 1, true) or string.find(cls, "dumpster", 1, true)
		or string.find(cls, "container", 1, true) or string.find(cls, "crate", 1, true)
		or string.find(cls, "locker", 1, true) or string.find(cls, "chest", 1, true) then
		return "Search"
	end
	if ent:GetMoveType() == MOVETYPE_VPHYSICS then return "Grab" end

	return nil
end

local function DrawPromptLine(label, S, y, kind)
	local iconSize = 16 * S
	local fontSz = 19 * S
	surface.SetFont(ANIV.Font(fontSz))
	local textW = select(1, surface.GetTextSize(label))
	local totalW = iconSize + 7 * S + textW
	local x = ScrW() * 0.5 - totalW * 0.5

	local col = kind == "Grab" and ANIV.COL.green or ANIV.COL.white
	local tex = kind == "Grab" and "check" or "eye"
	if not ANIV.DrawIcon(tex, x, y, iconSize, col) then
		ANIV.DrawPattern(kind == "Grab" and ANIV.PAT.check or ANIV.PAT.eye,
			x, y, iconSize, col)
	end
	ANIV.Text(label, x + iconSize + 7 * S, y - 2 * S, fontSz, col, nil, nil, true, 1)
end

local function DrawPrompts(S)
	local y = ScrH() * 0.57
	if GetConVar("aniv_hud_prompt_preview"):GetBool() then
		DrawPromptLine("Grab", S, y - 16 * S, "Grab")
		DrawPromptLine("Search", S, y + 14 * S, "Search")
		return
	end
	local p = ANIV.GetContextPrompt()
	if p == "Grab" then DrawPromptLine("Grab", S, y, "Grab") end
	if p == "Search" then DrawPromptLine("Search", S, y, "Search") end
end

---------------------------------------------------------------------------
-- Faction radio chat frame (the DTextEntry itself lives in input.lua)
---------------------------------------------------------------------------
local function DrawRadioChatFrame(S)
	if not ANIV.State.radioChatOpen then return end
	local r = ANIV.GetRadioChatRect()
	local x, y = ANIV.Snap(r.x - 4 * S), ANIV.Snap(r.y - 4 * S)
	local w, h = ANIV.Snap(r.w + 8 * S), ANIV.Snap(r.h + 8 * S)

	surface.SetDrawColor(10, 12, 10, 225)
	surface.DrawRect(x, y, w, h)
	surface.SetDrawColor(186, 150, 84, 255)
	surface.DrawOutlinedRect(x, y, w, h, math.max(1, ANIV.Snap(2 * S)))
	surface.SetDrawColor(214, 182, 118, 60)
	surface.DrawRect(x + 2, y + 2, w - 4, math.max(1, ANIV.Snap(2 * S)))

	ANIV.Text("[ FACTION RADIO ]", x, y - 18 * S, 12 * S,
		ANIV.COL.green, nil, nil, true, 1)
end

---------------------------------------------------------------------------
-- CRT / grime overlay
---------------------------------------------------------------------------
local function DrawCRT(S)
	if not GetConVar("aniv_hud_crt"):GetBool() then return end
	local step = math.max(2, math.Round(3 * S))
	local a = 14 + math.sin(CurTime() * 13) * 3
	surface.SetDrawColor(0, 0, 0, a)
	for y = 0, ScrH(), step do
		surface.DrawRect(0, y, ScrW(), 1)
	end
	-- faint sickly green bias and corner darkening
	surface.SetDrawColor(24, 58, 24, 7)
	surface.DrawRect(0, 0, ScrW(), ScrH())
	surface.SetDrawColor(0, 0, 0, 46)
	surface.DrawRect(0, 0, ScrW(), math.Round(10 * S))
	surface.DrawRect(0, ScrH() - math.Round(10 * S), ScrW(), math.Round(10 * S))
	surface.DrawRect(0, 0, math.Round(10 * S), ScrH())
	surface.DrawRect(ScrW() - math.Round(10 * S), 0, math.Round(10 * S), ScrH())
end

---------------------------------------------------------------------------
-- Main paint hook
---------------------------------------------------------------------------
hook.Add("HUDPaint", "ANIV_HUD_Paint", function()
	if not ANIV.State.hudVisible then return end
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	-- IsSpec() exists in some gamemodes (e.g. DarkRP) but not in base GMod.
	if not ply:Alive() and (ply:Team() == TEAM_SPECTATOR or (ply.IsSpec and ply:IsSpec())) then return end

	local S = ANIV.Scale()
	DrawRadio(S)
	if GetConVar("aniv_hud_bars_enabled"):GetBool() then
		DrawStatBars(S)
	else
		DrawStatusIcons(S) -- legacy four-icon HUD
	end
	DrawPrompts(S)
	DrawRadioChatFrame(S)
	DrawCRT(S)
end)

-- Hide the stock GMod HUD chunks; this addon replaces them.
hook.Add("HUDShouldDraw", "ANIV_HUD_HideStock", function(name)
	if not ANIV.State.hudVisible then return end
	if name == "CHudHealth" or name == "CHudBattery" or name == "CHudAmmo"
		or name == "CHudSecondaryAmmo" or name == "CHudDamageIndicator" then
		return false
	end
end)
