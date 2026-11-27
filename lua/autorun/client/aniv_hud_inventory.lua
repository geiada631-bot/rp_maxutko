--[[---------------------------------------------------------------------------
 ANEURISM IV HUD - inventory book panel
 File: lua/autorun/client/aniv_hud_inventory.lua

 A clickable VGUI inventory opened by C, by clicking the book icon or by
 ANIV.OpenInventory(). It reuses the same grimy paper / green-border visual
 language as the in-game inventory and waypoint screens.
---------------------------------------------------------------------------]]

local PANEL = {}

function PANEL:Init()
	local S = ANIV.S()
	self.S = S
	self:SetSize(math.Round(560 * S), math.Round(430 * S))
	self:Center()
	self:SetMouseInputEnabled(true)
	self:MakePopup() -- takes keyboard focus; cursor is managed by ANIV.UpdateCursor
end

function PANEL:Paint(w, h)
	local S = self.S
	-- Paper background tiled at 1 texel = 1 px, with a flat fallback colour.
	ANIV.DrawTexTiled(ANIV.MAT.paper, 0, 0, w, h,
		ANIV.TEX.paper.w, ANIV.TEX.paper.h,
		Color(28, 33, 27, 255), Color(96, 92, 74, 255))

	surface.SetDrawColor(12, 14, 12, 220)
	surface.DrawRect(0, 0, w, math.Round(44 * S))
	surface.SetDrawColor(ANIV.COL.green)
	surface.DrawOutlinedRect(0, 0, w, h, math.max(1, math.Round(2 * S)))
	surface.SetDrawColor(ANIV.COL.greenDark)
	surface.DrawRect(0, math.Round(44 * S), w, math.max(1, math.Round(2 * S)))

	ANIV.Text("INVENTORY", math.Round(14 * S), math.Round(9 * S), 20 * S, ANIV.COL.green)
	ANIV.Text(ANIV.InventoryCount() .. " / 16", w - math.Round(14 * S), math.Round(11 * S),
		15 * S, ANIV.COL.white, TEXT_ALIGN_RIGHT)

	-- 4 x 4 slot grid
	local cols, rows = 4, 4
	local pad = math.Round(18 * S)
	local gap = math.Round(10 * S)
	local top = math.Round(56 * S)
	local slot = (w - pad * 2 - gap * (cols - 1)) / cols

	for i = 1, cols * rows do
		local c = (i - 1) % cols
		local r = math.floor((i - 1) / cols)
		local x = pad + c * (slot + gap)
		local y = top + r * (slot + gap)
		-- CursorPos() returns TWO values; passing it as the first argument of a
		-- call with more arguments truncates it to one and broke InRect (h=nil).
		local mx, my = self:CursorPos()
		local hover = ANIV.InRect(mx, my, x, y, slot, slot)

		surface.SetDrawColor(hover and Color(46, 62, 40, 255) or Color(18, 22, 18, 255))
		surface.DrawRect(x, y, slot, slot)
		surface.SetDrawColor(hover and ANIV.COL.green or Color(58, 72, 54, 255))
		surface.DrawOutlinedRect(x, y, slot, slot, 1)

		local item = ANIV.State.inventory[i]
		if item then
			-- tiny pixel "item" glyph, colour derived from the name (stable)
			local seed = 0
			for k = 1, #item do seed = (seed + string.byte(item, k) * k) % 255 end
			surface.SetDrawColor(Color(70 + seed % 120, 70 + (seed * 3) % 120, 50 + (seed * 7) % 100, 255))
			surface.DrawRect(x + slot * 0.22, y + slot * 0.16, slot * 0.56, slot * 0.46)
			surface.SetDrawColor(10, 12, 10, 255)
			surface.DrawOutlinedRect(x + slot * 0.22, y + slot * 0.16, slot * 0.56, slot * 0.46, 1)

			ANIV.Text(item, x + slot * 0.5, y + slot * 0.72, 10 * S,
				ANIV.COL.white, TEXT_ALIGN_CENTER, nil, true, 1)
		end
	end

	ANIV.Text("[LMB] drop item     [C] close     [TAB] HUD widgets",
		math.Round(14 * S), h - math.Round(20 * S), 10 * S, ANIV.COL.dim)
end

function PANEL:OnMousePressed(code)
	if code ~= MOUSE_LEFT then return end
	local S = self.S
	local mx, my = self:CursorPos()
	local pad = math.Round(18 * S)
	local gap = math.Round(10 * S)
	local top = math.Round(56 * S)
	local cols = 4
	local slot = (self:GetWide() - pad * 2 - gap * (cols - 1)) / cols

	for i = 1, 16 do
		local c = (i - 1) % cols
		local r = math.floor((i - 1) / cols)
		local x = pad + c * (slot + gap)
		local y = top + r * (slot + gap)
		if ANIV.InRect(mx, my, x, y, slot, slot) and ANIV.State.inventory[i] then
			local name = ANIV.State.inventory[i]
			ANIV.RemoveItem(i)
			surface.PlaySound("buttons/button15.wav")
			hook.Run("ANIV_ItemDropped", name)
			return
		end
	end
end

vgui.Register("ANIV_Inventory", PANEL, "EditablePanel")

--- Public open / close API -------------------------------------------------
function ANIV.OpenInventory()
	if IsValid(ANIV.InventoryPanel) then return end
	ANIV.InventoryPanel = vgui.Create("ANIV_Inventory")
	ANIV.State.inventoryOpen = true
	ANIV.UpdateCursor()
	hook.Run("ANIV_InventoryOpened")
end

function ANIV.CloseInventory()
	if IsValid(ANIV.InventoryPanel) then
		ANIV.InventoryPanel:Remove()
	end
	ANIV.InventoryPanel = nil
	ANIV.State.inventoryOpen = false
	ANIV.UpdateCursor()
	hook.Run("ANIV_InventoryClosed")
end

function ANIV.ToggleInventory()
	if ANIV.State.inventoryOpen then ANIV.CloseInventory() else ANIV.OpenInventory() end
end
