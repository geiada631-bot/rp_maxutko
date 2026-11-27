--[[---------------------------------------------------------------------------
 ANEURISM IV HUD for Garry's Mod
 File: lua/autorun/aniv_hud_init.lua
 Author: generated for the user's GMod project

 Shared bootstrap: configuration (convars), fonts, materials, state and the
 public API that other addons / the server can use to drive this HUD.

 The game itself uses TAB + click to mute and X to broadcast, and its
 Company-Broadcaster opens a fate-aligned (faction) text channel. Our faction
 radio follows the brief: it starts OFF, F3 unlocks the cursor, clicking the
 radio turns it ON, X opens faction chat, and clicking again restores normal
 chat. Every binding is a convar so the original layout can still be matched.
---------------------------------------------------------------------------]]

ANIV = ANIV or {}

ANIV.VERSION   = "1.1.0"
ANIV.BASE_W    = 1920
ANIV.BASE_H    = 1080

-- Palette taken from the Aneurism IV UI references (wiki.gg).
ANIV.COL = {
	green      = Color( 94, 214,  92, 255), -- sense bar / "Grab" / selected POI
	greenDark  = Color( 33,  92,  35, 255),
	amber      = Color(224, 156,  74, 255), -- radio LCD backlight
	amberDark  = Color( 78,  52,  26, 255),
	blood      = Color(198,  48,  44, 255),
	bone       = Color(214, 188,  72, 255),
	leg        = Color(196, 158,  54, 255),
	sanity     = Color( 88, 138, 196, 255),
	white      = Color(230, 228, 210, 255),
	dim        = Color(120, 118, 104, 255),
	black      = Color(  8,  10,   8, 255),
	outline    = Color(  6,   8,   6, 255),
}

-- Runtime state. Everything here can be changed from outside via the API.
ANIV.State = {
	hudVisible   = true,
	-- Faction radio. It is OFF on spawn: local chat works until the player
	-- unlocks the cursor (F3) and clicks the radio body.
	radioActive  = false,
	radioChatOpen = false,
	cursorUnlocked = false, -- toggled with F3, independent of TAB
	muted        = true,   -- kept in sync: muted == not radioActive
	broadcasting = false,
	uiMode       = false,  -- cursor is visible (F3 / TAB / chat)
	-- Six HUD bars from ANEURISM IV: blood/air/moisture/nourishment/sanity/sepsis.
	-- bone/leg are kept for the legacy four-icon HUD (aniv_hud_bars_enabled 0).
	stats        = {
		blood = 100, air = 100, moisture = 100, nourishment = 100,
		sanity = 100, sepsis = 0, bone = 100, leg = 100,
	},
}

if SERVER then
	util.AddNetworkString("ANIV_SetStat")
	util.AddNetworkString("ANIV_SetStats")
	util.AddNetworkString("ANIV_SetMuted")
	util.AddNetworkString("ANIV_RadioChat")
	util.AddNetworkString("ANIV_RadioChatReceive")

	net.Receive("ANIV_SetStat", function(len, ply)
		-- Reserved for client -> server sync if needed by your gamemode.
	end)

	-- Faction (channel) lookup. Prefers the Helix character faction and falls
	-- back to team, so the radio works even outside Helix.
	local function RadioFaction(ply)
		local index = nil
		local character = ply.GetCharacter and ply:GetCharacter()
		if character and character.GetFaction then
			index = character:GetFaction()
		end
		if index == nil then index = ply:Team() end

		local faction = (ix and ix.faction and ix.faction.indices)
			and ix.faction.indices[index] or nil
		local uid   = faction and (faction.uniqueID or faction.name) or ("team_" .. tostring(index))
		local name  = faction and faction.name or tostring(uid)
		local color = faction and faction.color or Color(150, 90, 90, 255)

		return index, tostring(uid), tostring(name), color
	end

	-- Server-authoritative faction chat. The client only sends text; the
	-- server decides which channel it belongs to and who may hear it. This
	-- mirrors ANEURISM IV, where Cortex and Scum use separate channels.
	net.Receive("ANIV_RadioChat", function(len, ply)
		if not IsValid(ply) then return end

		local text = string.Trim(net.ReadString() or "")
		if text == "" then return end
		if #text > 160 then text = string.sub(text, 1, 160) end

		-- Anti-spam: at most one transmission every 0.5 seconds.
		local now = CurTime()
		if (ply.ANIVLastRadio or 0) + 0.5 > now then return end
		ply.ANIVLastRadio = now

		local index, uid, name, color = RadioFaction(ply)
		local recipients = {}
		for _, other in ipairs(player.GetAll()) do
			if RadioFaction(other) == index then
				recipients[#recipients + 1] = other
			end
		end

		net.Start("ANIV_RadioChatReceive")
			net.WriteEntity(ply)
			net.WriteString(uid)
			net.WriteString(name)
			net.WriteUInt(math.Clamp(math.floor(color.r or 150), 0, 255), 8)
			net.WriteUInt(math.Clamp(math.floor(color.g or 90), 0, 255), 8)
			net.WriteUInt(math.Clamp(math.floor(color.b or 90), 0, 255), 8)
			net.WriteString(text)
		net.Send(recipients)

		MsgN("[ANIV][RADIO] " .. ply:Nick() .. " [" .. uid .. "]: " .. text)
	end)
end

if CLIENT then

	---------------------------------------------------------------------------
	-- Convars
	---------------------------------------------------------------------------
	CreateClientConVar("aniv_hud_enabled",        "1",    true, false, "Show the Aneurism IV HUD.")
	CreateClientConVar("aniv_hud_scale",          "1",    true, false, "Global HUD scale (1 = 1080p reference).")
	CreateClientConVar("aniv_hud_crt",            "1",    true, false, "Scanlines / CRT vignette.")
	CreateClientConVar("aniv_hud_broadcast_key",  "C",    true, false, "Hold key for the visual TX indicator (unchanged, as requested).")
	CreateClientConVar("aniv_hud_radio_key",      "F3",   true, false, "Toggle the cursor so the radio can be clicked.")
	CreateClientConVar("aniv_hud_radio_chat_key", "X",    true, false, "Open faction radio chat while the radio is ON.")
	CreateClientConVar("aniv_hud_faction_chat",   "1",    true, false, "Route radio messages only to the sender's faction channel.")
	CreateClientConVar("aniv_hud_interact_key",   "E",    true, false, "Use / interact key shown in the UI.")
	CreateClientConVar("aniv_hud_ui_key",         "TAB",  true, false, "Hold this key to interact with HUD widgets.")
	CreateClientConVar("aniv_hud_free_cursor",    "0",    true, false, "Always show the cursor (testing / click widgets freely).")
	CreateClientConVar("aniv_hud_ads_click",      "0",    true, false, "Enable cursor while aiming (right mouse) so HUD widgets stay clickable.")
	CreateClientConVar("aniv_hud_prompt_preview", "0",    true, false, "Draw both context prompts for previewing.")
	CreateClientConVar("aniv_hud_prompt_dist",    "110",  true, false, "Max trace distance for context prompts.")
	CreateClientConVar("aniv_hud_icon_labels",    "0",    true, false, "Draw tiny labels under status icons.")
	CreateClientConVar("aniv_hud_bars_enabled",   "1",    true, false, "Draw the two ANEURISM IV stat bars instead of the four icons.")

	-- The old inventory key convar and its VGUI panel were removed by request.

	---------------------------------------------------------------------------
	-- Materials. The .vmt uses $pointsample (nearest-neighbour) so a texture
	-- pixel stays a crisp square instead of being bilinear-smeared. `noclamp`
	-- lets us tile a texture with UV > 1 for a true 1 texel = 1 px surface.
	-- If the .vmt is absent we fall back to the raw PNG, and if the artwork is
	-- missing entirely ANIV.DrawTex() draws a flat colour (never the pink
	-- checkerboard error material).
	---------------------------------------------------------------------------
	ANIV.MAT = ANIV.MAT or {}
	-- A .vmt whose $basetexture has no matching .vtf still returns a *valid*
	-- material object - but its texture is the pink/black checkerboard. GMod
	-- loads PNG/JPG directly through Material(), so always try the PNG first.
	local function M(name)
		local m = Material("aneurism_hud/" .. name .. ".png", "noclamp")
		if m:IsError() then
			m = Material("aneurism_hud/" .. name, "noclamp")
		end
		return m
	end

	ANIV.MAT.radio  = M("walkie_talkie")
	ANIV.MAT.paper  = M("paper")
	ANIV.MAT.plastic= M("plastic")
	ANIV.MAT.metal  = M("metal")
	ANIV.MAT.barNoise = M("bar_noise") -- speckled fill, tinted per stat
	ANIV.MAT.barFrame = M("bar_frame") -- original worn capsule from the game sprite

	-- UI glyphs. The first four are the *original* 16x16 sprites shipped with
	-- ANEURISM IV (game-icons.net set); bone/leg are rendered from the same
	-- set, so the stroke weight and anti-aliasing match.
	ANIV.MAT.icon_blood = M("icon_blood")
	ANIV.MAT.icon_bone  = M("icon_bone")
	ANIV.MAT.icon_leg   = M("icon_leg")
	ANIV.MAT.icon_skull = M("icon_skull")
	ANIV.MAT.icon_check = M("icon_check")
	ANIV.MAT.icon_eye   = M("icon_eye")

	-- Native texture dimensions (px). Used to preserve aspect ratio and to
	-- compute tiling so 1 texture pixel maps to exactly 1 output pixel.
	ANIV.TEX = {
		radio   = { w = 371, h = 413 }, -- File:Walkie talkie (1).png, 371x413
		paper   = { w = 128, h = 128 },
		plastic = { w = 128, h = 128 },
		metal   = { w = 128, h = 128 },
		bar_noise = { w = 128, h = 32 },
		bar_frame = { w = 265, h = 39 },
	}

	-- Exact UV rect of the LCD on the radio sprite (measured in source px:
	-- the bright amber panel sits at x 93..232, y 254..339 inside the
	-- 371x413 sprite; 1 px of bezel is kept on each side).
	-- u = px_x / 371, v = px_y / 413.
	ANIV.RADIO_LCD_UV = { u0 = 93 / 371, v0 = 254 / 413, u1 = 233 / 371, v1 = 340 / 413 }

	-- Native size of every glyph. DrawIcon() keeps the aspect ratio, so the
	-- 11x11 check mark and the 32x32 bone both sit centred in the same box.
	ANIV.ICON = {
		blood = { key = "icon_blood", w = 16, h = 16 },
		bone  = { key = "icon_bone",  w = 32, h = 32 },
		leg   = { key = "icon_leg",   w = 16, h = 16 },
		skull = { key = "icon_skull", w = 16, h = 16 },
		check = { key = "icon_check", w = 11, h = 11 },
		eye   = { key = "icon_eye",   w = 16, h = 16 },
	}

	-- If a generated texture is missing, fall back to the next best one.
	if ANIV.MAT.paper:IsError()  then ANIV.MAT.paper   = ANIV.MAT.metal   end
	if ANIV.MAT.plastic:IsError()then ANIV.MAT.plastic = ANIV.MAT.metal   end
	if ANIV.MAT.metal:IsError()  then ANIV.MAT.metal   = ANIV.MAT.plastic end

	---------------------------------------------------------------------------
	-- Fonts. Integer sizes are pre-created so we never hit a fallback font at
	-- an awkward scaled size (antialias = false keeps the pixel look).
	---------------------------------------------------------------------------
	ANIV.FONTS = {}
	local function BuildFonts()
		for size = 6, 48 do
			surface.CreateFont("ANIV_PX_" .. size, {
				font = "Silkscreen", size = size, weight = 0,
				antialias = false, additive = false, outline = false,
			})
			surface.CreateFont("ANIV_TT_" .. size, {
				font = "VT323", size = size, weight = 0,
				antialias = false, additive = false, outline = false,
			})
		end
	end
	BuildFonts()
	hook.Add("OnScreenSizeChanged", "ANIV_RebuildFonts", BuildFonts)

	---------------------------------------------------------------------------
	-- Helpers
	---------------------------------------------------------------------------

	-- Scale relative to a 1080p reference height. Clamped so 4K doesn't become
	-- unusably large and 720p doesn't become unreadable.
	function ANIV.Scale()
		local s = ScrH() / ANIV.BASE_H
		s = math.Clamp(s, 0.55, 1.65)
		return s * GetConVar("aniv_hud_scale"):GetFloat()
	end

	function ANIV.S()
		return ANIV.Scale()
	end

	-- Nearest pre-created font for a (possibly fractional) size.
	function ANIV.Font(size, terminal)
		local n = math.Clamp(math.floor(size + 0.5), 6, 48)
		return (terminal and "ANIV_TT_" or "ANIV_PX_") .. n
	end

	-- Pixel text with a 1px dark outline for readability on any background.
	function ANIV.Text(text, x, y, size, col, ax, ay, terminal, outline)
		draw.SimpleText(text, ANIV.Font(size, terminal), x, y, col or ANIV.COL.white,
			ax or TEXT_ALIGN_LEFT, ay or TEXT_ALIGN_TOP, outline or 1, ANIV.COL.outline)
	end

	function ANIV.InRect(px, py, x, y, w, h)
		-- Be defensive: a truncated multi-return call used to pass nil here and
		-- produced an error every frame. A bad hit is just "not hovered".
		if not px or not py or not x or not y or not w or not h then return false end
		return px >= x and px <= x + w and py >= y and py <= y + h
	end

	function ANIV.Key(code)
		return _G["KEY_" .. string.upper(code or "")]
	end

	-- Thick pixel line used for the book symbol.
	function ANIV.ThickLine(x1, y1, x2, y2, t, col)
		local dx, dy = x2 - x1, y2 - y1
		local len = math.sqrt(dx * dx + dy * dy)
		if len < 0.01 then return end
		local nx, ny = -dy / len, dx / len
		local half = t * 0.5
		surface.SetDrawColor(col)
		for i = 0, t - 1 do
			local o = -half + i + 0.5
			surface.DrawLine(x1 + nx * o, y1 + ny * o, x2 + nx * o, y2 + ny * o)
		end
	end

	---------------------------------------------------------------------------
	-- 1:1 texture helpers
	--
	-- Everything is snapped to whole screen pixels and drawn with an explicit
	-- UV rect, so the texture is never resampled across a half pixel (that is
	-- what makes a sprite look "blurry / wrong UV"). If the material failed to
	-- load, a flat colour is drawn instead of the pink/black checkerboard.
	---------------------------------------------------------------------------

	function ANIV.Snap(v)
		return math.floor(v + 0.5)
	end

	-- IsError() is not enough: a VMT can load while its basetexture is still
	-- the engine's pink/black "_error" texture. Check the real texture name
	-- and cache the result (materials are resolved once, not every frame).
	local matReadyCache = {}
	function ANIV.MatReady(mat)
		if not mat then return false end
		local key = tostring(mat)
		local cached = matReadyCache[key]
		if cached ~= nil then return cached end

		local ok = not mat:IsError()
		if ok then
			local got, tex = pcall(mat.GetTexture, mat, "$basetexture")
			if got and tex and tex.GetName then
				local name = tostring(tex:GetName() or "")
				if name == "_error" or string.find(name, "error", 1, true) then
					ok = false
				end
			end
		end

		matReadyCache[key] = ok
		return ok
	end

	function ANIV.RefreshMaterials()
		matReadyCache = {}
	end
	hook.Add("InitPostEntity", "ANIV_RefreshMaterials", ANIV.RefreshMaterials)
	-- Downloaded textures can finish loading a moment after initial spawn.
	timer.Simple(3, ANIV.RefreshMaterials)

	-- Draw a whole texture into an integer rect, full UV (0,0)-(1,1).
	function ANIV.DrawTex(mat, x, y, w, h, fallback, tint)
		x, y = ANIV.Snap(x), ANIV.Snap(y)
		w, h = ANIV.Snap(w), ANIV.Snap(h)
		if w < 1 then w = 1 end
		if h < 1 then h = 1 end

		if ANIV.MatReady(mat) then
			surface.SetMaterial(mat)
			surface.SetDrawColor(tint or Color(255, 255, 255, 255))
			surface.DrawTexturedRectUV(x, y, w, h, 0, 0, 1, 1)
		else
			surface.SetDrawColor(fallback or Color(46, 50, 42, 255))
			surface.DrawRect(x, y, w, h)
		end
	end

	-- Draw a texture at 1 texel = 1 screen pixel (tiled, not stretched).
	-- texW/texH are the native texture dimensions (ANIV.TEX.*).
	function ANIV.DrawTexTiled(mat, x, y, w, h, texW, texH, fallback, tint)
		x, y = ANIV.Snap(x), ANIV.Snap(y)
		w, h = ANIV.Snap(w), ANIV.Snap(h)
		if w < 1 then w = 1 end
		if h < 1 then h = 1 end

		if ANIV.MatReady(mat) then
			surface.SetMaterial(mat)
			surface.SetDrawColor(tint or Color(255, 255, 255, 255))
			surface.DrawTexturedRectUV(x, y, w, h, 0, 0, w / texW, h / texH)
		else
			surface.SetDrawColor(fallback or Color(46, 50, 42, 255))
			surface.DrawRect(x, y, w, h)
		end
	end

	-- Draw only a sub-rect of a texture (UV given in 0..1 texture space).
	function ANIV.DrawTexUV(mat, x, y, w, h, u0, v0, u1, v1, fallback, tint)
		x, y = ANIV.Snap(x), ANIV.Snap(y)
		w, h = ANIV.Snap(w), ANIV.Snap(h)

		if ANIV.MatReady(mat) then
			surface.SetMaterial(mat)
			surface.SetDrawColor(tint or Color(255, 255, 255, 255))
			surface.DrawTexturedRectUV(x, y, w, h, u0, v0, u1, v1)
		else
			surface.SetDrawColor(fallback or Color(46, 50, 42, 255))
			surface.DrawRect(x, y, w, h)
		end
	end

	-- Draw a glyph centred inside a square box, preserving its native aspect.
	-- Returns false when the material is missing, so the caller can fall back
	-- to the built-in pixel-art grid instead of showing a checkerboard.
	function ANIV.DrawIcon(name, x, y, size, tint)
		local def = ANIV.ICON[name]
		if not def then return false end
		local mat = ANIV.MAT[def.key]
		if not ANIV.MatReady(mat) then return false end

		local k = math.min(size / def.w, size / def.h)
		local w = math.max(1, ANIV.Snap(def.w * k))
		local h = math.max(1, ANIV.Snap(def.h * k))
		local ox = ANIV.Snap(x + (size - w) * 0.5)
		local oy = ANIV.Snap(y + (size - h) * 0.5)

		ANIV.DrawTex(mat, ox, oy, w, h, tint, tint)
		return true
	end

	---------------------------------------------------------------------------
	-- Public API - call these from your gamemode / other addons
	---------------------------------------------------------------------------

	function ANIV.SetStat(name, value)
		if not ANIV.State.stats[name] then return end
		ANIV.State.stats[name] = math.Clamp(tonumber(value) or 0, 0, 100)
		hook.Run("ANIV_StatChanged", name, ANIV.State.stats[name])
	end

	function ANIV.GetStat(name)
		return ANIV.State.stats[name] or 0
	end

	-- Aliases for the original game's stat names.
	function ANIV.SetBlood(v)   ANIV.SetStat("blood", v)  end
	function ANIV.SetAir(v)     ANIV.SetStat("air", v)    end
	function ANIV.SetSanity(v)  ANIV.SetStat("sanity", v) end
	function ANIV.SetMoisture(v)    ANIV.SetStat("moisture", v)    end
	function ANIV.SetNourishment(v) ANIV.SetStat("nourishment", v) end
	function ANIV.SetSepsis(v)      ANIV.SetStat("sepsis", v)      end

	-- Faction radio -----------------------------------------------------------
	-- "Muted" is just the inverse of "radio active". SetMuted() is kept as an
	-- alias so gamemode code written for v1.0 keeps working.
	function ANIV.SetRadioActive(v)
		v = v and true or false
		if ANIV.State.radioActive == v then return end
		ANIV.State.radioActive = v
		ANIV.State.muted = not v
		if not v then
			ANIV.SetBroadcasting(false)
			ANIV.SetRadioChatOpen(false)
		end
		hook.Run("ANIV_RadioStateChanged", v)
		hook.Run("ANIV_MuteChanged", ANIV.State.muted)
	end
	function ANIV.ToggleRadio() ANIV.SetRadioActive(not ANIV.State.radioActive) end
	function ANIV.IsRadioActive() return ANIV.State.radioActive end

	function ANIV.SetMuted(v) ANIV.SetRadioActive(not v) end
	function ANIV.ToggleMute() ANIV.ToggleRadio() end

	function ANIV.SetBroadcasting(v) ANIV.State.broadcasting = v and true or false end

	function ANIV.SetRadioChatOpen(open, initialText)
		open = open and true or false
		if open and not ANIV.State.radioActive then open = false end
		ANIV.State.radioChatOpen = open
		hook.Run("ANIV_RadioChatStateChanged", open, initialText)
	end
	function ANIV.IsRadioChatOpen() return ANIV.State.radioChatOpen end

	function ANIV.ToggleCursorUnlocked()
		ANIV.State.cursorUnlocked = not ANIV.State.cursorUnlocked
		if ANIV.UpdateCursor then ANIV.UpdateCursor() end
		hook.Run("ANIV_CursorUnlockedChanged", ANIV.State.cursorUnlocked)
	end
	function ANIV.IsCursorUnlocked() return ANIV.State.cursorUnlocked end

	-- The whole inventory subsystem (VGUI panel, book counter, item list,
	-- net sync and hooks) was removed by user request. These are empty stubs
	-- kept only so gamemode code calling the old API never throws.
	function ANIV.SetInventory(list) end
	function ANIV.AddItem(name) end
	function ANIV.RemoveItem(index) end
	function ANIV.InventoryCount() return 0 end
	function ANIV.OpenInventory() end
	function ANIV.CloseInventory() end
	function ANIV.ToggleInventory() end

	function ANIV.ToggleHUD()
		ANIV.State.hudVisible = not ANIV.State.hudVisible
		hook.Run("ANIV_HUDVisibilityChanged", ANIV.State.hudVisible)
	end

	---------------------------------------------------------------------------
	-- Console commands (the game also has a plain `togglehud`)
	---------------------------------------------------------------------------
	concommand.Add("togglehud", function() ANIV.ToggleHUD() end)
	concommand.Add("aniv_hud_toggle", function() ANIV.ToggleHUD() end)
	concommand.Add("aniv_hud_radio", function(_, _, args)
		local mode = string.lower(args[1] or "")
		if mode == "on" then ANIV.SetRadioActive(true)
		elseif mode == "off" then ANIV.SetRadioActive(false)
		else ANIV.ToggleRadio() end
	end)
	concommand.Add("aniv_hud_reset", function()
		ANIV.State.hudVisible = true
		ANIV.SetRadioActive(false)
		ANIV.State.cursorUnlocked = false
		ANIV.SetBroadcasting(false)
		for k in pairs(ANIV.State.stats) do ANIV.SetStat(k, 100) end
	end)

	-- Server -> client sync helpers (optional, for your gamemode).
	net.Receive("ANIV_SetStat", function()
		ANIV.SetStat(net.ReadString(), net.ReadFloat())
	end)
	net.Receive("ANIV_SetStats", function()
		local t = net.ReadTable()
		for k, v in pairs(t) do ANIV.SetStat(k, v) end
	end)
	net.Receive("ANIV_SetMuted", function()
		ANIV.SetMuted(net.ReadBool())
	end)

	-- Incoming faction radio transmission (server-authoritative routing).
	net.Receive("ANIV_RadioChatReceive", function()
		local sender = net.ReadEntity()
		local uid    = net.ReadString()
		local name   = net.ReadString()
		local r      = net.ReadUInt(8)
		local g      = net.ReadUInt(8)
		local b      = net.ReadUInt(8)
		local text   = net.ReadString()

		local nick = IsValid(sender) and sender:Nick() or "?"
		local fcol = Color(r, g, b, 255)
		chat.AddText(ANIV.COL.green, "[RADIO ", fcol, "· " .. name,
			ANIV.COL.green, "] ", fcol, nick, ANIV.COL.white, ": ", text)
		hook.Run("ANIV_RadioMessageReceived", sender, uid, name, text)
		surface.PlaySound("buttons/blip1.wav")
	end)

	-- Debug: `aniv_hud_debug` prints the current state.
	concommand.Add("aniv_hud_debug", function()
		print("[ANIV HUD] v" .. ANIV.VERSION)
		print("[ANIV HUD] visible=", ANIV.State.hudVisible,
			" radio=", ANIV.State.radioActive,
			" radioChat=", ANIV.State.radioChatOpen,
			" cursorUnlocked=", ANIV.State.cursorUnlocked,
			" broadcasting=", ANIV.State.broadcasting,
			" scale=", ANIV.Scale())
		for k, v in pairs(ANIV.State.stats) do print("  ", k, v) end
	end)

	-- Debug: `aniv_hud_materials` tells you whether the client actually has the
	-- artwork. If any line says error=true, the client did not download the
	-- files (check the server console for "[ANIV][SERVER] Added client download").
	concommand.Add("aniv_hud_materials", function()
		ANIV.RefreshMaterials()
		for _, key in ipairs({ "radio", "paper", "plastic", "metal", "barFrame", "barNoise",
			"icon_blood", "icon_bone", "icon_leg", "icon_skull", "icon_check", "icon_eye" }) do
			local m = ANIV.MAT[key]
			local tex = m and m:GetTexture("$basetexture")
			local name = tex and tex.GetName and tostring(tex:GetName()) or "?"
			print(string.format("[ANIV HUD] material %-10s ready=%-5s texture=%s",
				key, tostring(ANIV.MatReady(m)), name))
		end
		print("[ANIV HUD] native sizes: radio=" .. ANIV.TEX.radio.w .. "x" .. ANIV.TEX.radio.h
			.. " bar_frame=" .. ANIV.TEX.bar_frame.w .. "x" .. ANIV.TEX.bar_frame.h)
	end)

end -- CLIENT
