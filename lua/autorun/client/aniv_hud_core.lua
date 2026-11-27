--[[---------------------------------------------------------------------------
 ANEURISM IV HUD - rendering
 File: lua/autorun/client/aniv_hud_core.lua

 Draw order: radio -> book -> status icons -> context prompts -> CRT overlay.
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
	local bw, bh = 126 * S, 158 * S
	local bx, by = rx + 56 * S, ry + rh + 10 * S

	local is = 44 * S
	local gap = 12 * S
	local total = 4 * is + 3 * gap
	local ix = ScrW() * 0.5 - total * 0.5 - 150 * S
	local iy = ScrH() - is - 34 * S

	return {
		radio = { x = rx, y = ry, w = rw, h = rh },
		book  = { x = bx, y = by, w = bw, h = bh },
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

---------------------------------------------------------------------------
-- Inventory book (under the radio)
---------------------------------------------------------------------------
local function DrawBookSymbol(cx, cy, sz, col)
	local t = math.max(1.5, sz * 0.075)
	-- stem + crossbar: the "Ψ with an extra line" from the reference
	ANIV.ThickLine(cx, cy - sz * 0.42, cx, cy + sz * 0.42, t, col)
	ANIV.ThickLine(cx - sz * 0.34, cy - sz * 0.16, cx + sz * 0.34, cy - sz * 0.16, t, col)
	-- three prongs
	ANIV.ThickLine(cx - sz * 0.34, cy - sz * 0.16, cx - sz * 0.46, cy - sz * 0.40, t, col)
	ANIV.ThickLine(cx, cy - sz * 0.28, cx, cy - sz * 0.46, t, col)
	ANIV.ThickLine(cx + sz * 0.34, cy - sz * 0.16, cx + sz * 0.46, cy - sz * 0.40, t, col)
end

local function DrawBook(S)
	local r = ANIV.GetWidgetRects().book
	local x, y, w, h = r.x, r.y, r.w, r.h
	-- gui.MousePos() returns two values; assign them first (passing the call
	-- inline would truncate it to one and leave InRect's h nil).
	local mx, my = gui.MousePos()
	local hover = ANIV.InRect(mx, my, x, y, w, h) and (ANIV.State.uiMode or ANIV.State.inventoryOpen)

	ANIV.DrawTex(ANIV.MAT.book, x, y, w, h, Color(74, 64, 48, 255))

	-- worn dark frame
	surface.SetDrawColor(58, 50, 38, 180)
	surface.DrawOutlinedRect(x, y, w, h, math.max(1, 2 * S))

	if hover then
		surface.SetDrawColor(ANIV.COL.green)
		surface.DrawOutlinedRect(x - 2, y - 2, w + 4, h + 4, math.max(1, 2 * S))
	end

	DrawBookSymbol(x + w * 0.5, y + h * 0.46, w * 0.52, Color(38, 32, 24, 235))

	-- counter at the bottom, centered
	ANIV.Text(tostring(ANIV.InventoryCount()), x + w * 0.5, y + h - 26 * S,
		17 * S, Color(42, 34, 22), TEXT_ALIGN_CENTER, nil, false, 0)
end

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
			render.SetScissorRect(x, py, is, ph, true)
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
	DrawBook(S)
	DrawStatusIcons(S)
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
