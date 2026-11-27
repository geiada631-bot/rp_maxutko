--[[---------------------------------------------------------------------------
 ANEURISM IV HUD - input / interaction
 File: lua/autorun/client/aniv_hud_input.lua

 Handles: broadcast key, cursor visibility and clicking the radio,
 and the context "Grab" / "Search" interaction (E by default).
---------------------------------------------------------------------------]]

local pressed = {}
local function PressedOnce(keyCode, id, convarName)
	if not keyCode then return false end
	local down = input.IsKeyDown(keyCode)
	if down and not pressed[id] then
		pressed[id] = true
		return true
	end
	if not down then pressed[id] = false end
	return false
end

---------------------------------------------------------------------------
-- Faction radio chat entry. Created lazily so VGUI is fully initialised.
---------------------------------------------------------------------------
local chatEntry

local function EnsureChatEntry()
	if IsValid(chatEntry) then return chatEntry end

	chatEntry = vgui.Create("DTextEntry")
	chatEntry:SetText("")
	chatEntry:SetTextColor(Color(42, 28, 14, 255))
	chatEntry:SetCursorColor(Color(42, 28, 14, 255))
	chatEntry:SetDrawBackground(false)
	chatEntry:SetPaintBackground(false)

	chatEntry.OnEnter = function(pnl)
		local text = string.Trim(pnl:GetText() or "")
		if text ~= "" and GetConVar("aniv_hud_faction_chat"):GetBool() then
			net.Start("ANIV_RadioChat")
				net.WriteString(text)
			net.SendToServer()
			surface.PlaySound("buttons/blip1.wav")
		end
		ANIV.SetRadioChatOpen(false)
	end

	chatEntry.OnKeyCodePressed = function(pnl, code)
		if code == KEY_ESCAPE then
			ANIV.SetRadioChatOpen(false)
		end
	end

	chatEntry:SetVisible(false)
	return chatEntry
end

hook.Add("ANIV_RadioChatStateChanged", "ANIV_HUD_RadioChatPanel", function(open, initialText)
	local e = EnsureChatEntry()
	if open then
		local r = ANIV.GetRadioChatRect and ANIV.GetRadioChatRect()
			or { x = ScrW() * 0.28, y = ScrH() * 0.62, w = ScrW() * 0.44, h = 34 }
		local S = ANIV.S()
		e:SetPos(ANIV.Snap(r.x), ANIV.Snap(r.y))
		e:SetSize(ANIV.Snap(r.w), ANIV.Snap(r.h))
		e:SetFont(ANIV.Font(20 * S, true))
		e:SetText(initialText or "")
		e:SetVisible(true)
		e:MakePopup()
		e:RequestFocus()
		gui.EnableScreenClicker(true)
	else
		e:SetText("")
		e:SetVisible(false)
		e:KillFocus()
		-- MakePopup() changed the clicker behind our back; force a resync.
		ANIV.State.uiMode = nil
		ANIV.UpdateCursor()
	end
end)

hook.Add("ANIV_RadioStateChanged", "ANIV_HUD_RadioNotice", function(active)
	if active then
		chat.AddText(ANIV.COL.green, "[RADIO] ",
			ANIV.COL.white, "Фракционный канал включён. Нажмите X, чтобы говорить.")
	else
		chat.AddText(ANIV.COL.green, "[RADIO] ",
			ANIV.COL.white, "Обычный чат восстановлен.")
	end
end)

function ANIV.UpdateCursor()
	local want = ANIV.State.cursorUnlocked
		or ANIV.State.radioChatOpen
		or input.IsKeyDown(ANIV.Key(GetConVar("aniv_hud_ui_key"):GetString()))
		or GetConVar("aniv_hud_free_cursor"):GetBool()
		or (GetConVar("aniv_hud_ads_click"):GetBool() and input.IsMouseDown(MOUSE_RIGHT))
	want = want and ANIV.State.hudVisible

	if want ~= ANIV.State.uiMode then
		ANIV.State.uiMode = want
		gui.EnableScreenClicker(want)
	end
end

hook.Add("Think", "ANIV_HUD_Think", function()
	if not IsValid(LocalPlayer()) then return end

	-- Keep the clicker state in sync with F3 / TAB / chat.
	ANIV.UpdateCursor()

	-- While typing into the radio, let the text entry own the keyboard.
	if ANIV.State.radioChatOpen then
		ANIV.SetBroadcasting(true)
		return
	end

	-- F3: toggle the cursor so the radio can be clicked. Starts unlocked=off.
	if PressedOnce(ANIV.Key(GetConVar("aniv_hud_radio_key"):GetString()), "radioUi", "radioUi") then
		ANIV.ToggleCursorUnlocked()
		surface.PlaySound("buttons/blip1.wav")
	end

	-- X (when the radio is ON): open the faction radio chat input.
	if ANIV.IsRadioActive()
		and PressedOnce(ANIV.Key(GetConVar("aniv_hud_radio_chat_key"):GetString()), "radioTalk", "radioTalk") then
		ANIV.SetRadioChatOpen(true)
		surface.PlaySound("buttons/lightswitch2.wav")
		return
	end

	-- Hold-to-transmit visual indicator (C by default; game uses X for voice).
	ANIV.SetBroadcasting(ANIV.IsRadioActive()
		and input.IsKeyDown(ANIV.Key(GetConVar("aniv_hud_broadcast_key"):GetString())))

	-- The inventory VGUI was removed by user request: C/Q do nothing here.

	-- Context interaction (E in the original game).
	if PressedOnce(ANIV.Key(GetConVar("aniv_hud_interact_key"):GetString()), "use", "interact") then
		ANIV.Interact()
	end
end)

-- While the faction radio is ON, ordinary chat is disabled. Whatever the
-- player types in the normal chat box is redirected into the radio channel;
-- to get normal chat back the radio must be clicked again (turned OFF).
hook.Add("PlayerSay", "ANIV_HUD_RadioSay", function(ply, text, teamChat)
	if not IsValid(ply) or ply ~= LocalPlayer() then return end
	if not ANIV.IsRadioActive() then return end
	ANIV.SetRadioChatOpen(true, text)
	return ""
end)

---------------------------------------------------------------------------
-- Clicking the HUD widgets
---------------------------------------------------------------------------
hook.Add("GUIMousePressed", "ANIV_HUD_Click", function(code)
	if code ~= MOUSE_LEFT then return end
	if not ANIV.State.hudVisible then return end
	if ANIV.State.radioChatOpen then return end -- typing: ignore widget hits
	if not ANIV.State.uiMode then return end

	local mx, my = gui.MousePos()
	local R = ANIV.GetWidgetRects()

	if ANIV.InRect(mx, my, R.radio.x, R.radio.y, R.radio.w, R.radio.h) then
		-- Clicking the body toggles the faction radio. It starts OFF; clicking
		-- it again turns it OFF and restores ordinary chat.
		local turningOn = not ANIV.IsRadioActive()
		ANIV.ToggleRadio()
		surface.PlaySound(turningOn and "buttons/lightswitch2.wav" or "buttons/blip1.wav")
		return true
	end

end)

---------------------------------------------------------------------------
-- "Grab" / "Search" interaction hook
---------------------------------------------------------------------------
function ANIV.Interact()
	local prompt = ANIV.GetContextPrompt()
	if not prompt then return end

	local tr = LocalPlayer():GetEyeTrace()
	local ent = tr.Entity
	hook.Run("ANIV_Interact", prompt, ent)

	if not IsValid(ent) then return end

	if prompt == "Grab" then
		surface.PlaySound("items/ammo_pickup.wav")
		-- Only remove entities explicitly marked by your gamemode.
		if ent.ANIV_RemoveOnGrab == true then ent:Remove() end
	elseif prompt == "Search" then
		surface.PlaySound("buttons/lightswitch2.wav")
	end
end
