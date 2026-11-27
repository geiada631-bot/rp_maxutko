--[[---------------------------------------------------------------------------
 MYRP <-> ANEURISM IV HUD bridge (client)

 1. Suppresses the legacy "MYRP.CustomHUD.Paint" hook (bottom-left glass panel
    and ammo panel) so only the Aneurism IV HUD is visible.
 2. Feeds the HUD from live Helix state: health -> blood, "stm" -> air/leg,
    character "sanity" -> sanity. Inventory/book UI was removed by request.

 The legacy plugin's other hooks (ShouldHideBars, CanDrawAmmoHUD, HUDShouldDraw)
 are intentionally left in place - they hide Helix/Source HUD panels that our
 HUD replaces anyway.
---------------------------------------------------------------------------]]

local PREFIX = "[MYRP:ANIV_BRIDGE]"

local function Log(msg)
    MsgC(Color(120, 210, 120), PREFIX .. " " .. tostring(msg) .. "\n")
end

local function Install()
    if not ANIV then
        Log("WARN: addons/aneurism_hud is not installed; legacy HUD left untouched.")
        return
    end

    -- Remove the old MYRP HUD painter. Keep its Helix bar/ammo suppression.
    hook.Remove("HUDPaint", "MYRP.CustomHUD.Paint")

    local nextSync = 0

    hook.Add("Think", "MYRP.ANIVBridge.Sync", function()
        if (CurTime() < nextSync) then return end
        nextSync = CurTime() + 0.15

        local client = LocalPlayer()
        if (not IsValid(client) or not client.GetCharacter) then return end

        local character = client:GetCharacter()
        if (not character) then return end

        -- Blood: health percentage.
        local maxHealth = math.max(1, tonumber(client:GetMaxHealth()) or 100)
        local health = math.max(0, tonumber(client:Health()) or 0)
        ANIV.SetStat("blood", health / maxHealth * 100)

        -- Air / leg: Helix stamina localvar, falling back to saved character data.
        local stamina = tonumber(client:GetLocalVar("stm", nil))
        if (not stamina) then
            stamina = tonumber(character:GetData("stamina", 100)) or 100
        end
        stamina = math.Clamp(stamina, 0, 100)
        ANIV.SetStat("air", stamina)
        ANIV.SetStat("leg", stamina)

        -- Sanity: use character data when your gamemode tracks it, else full.
        local sanity = tonumber(character:GetData("sanity", 100)) or 100
        ANIV.SetStat("sanity", math.Clamp(sanity, 0, 100))

        -- Bone: optional character data (injury system), else full.
        local bone = tonumber(character:GetData("bones", character:GetData("bone", 100))) or 100
        ANIV.SetStat("bone", math.Clamp(bone, 0, 100))

        -- Six stat bars: thirst / hunger / sepsis. Fall back to inert values
        -- when the schema does not track them yet.
        local moisture = tonumber(character:GetData("moisture", 100)) or 100
        local nourishment = tonumber(character:GetData("nourishment", 100)) or 100
        local sepsis = tonumber(character:GetData("sepsis", character:GetData("sepsis_level", 0))) or 0
        ANIV.SetStat("moisture", math.Clamp(moisture, 0, 100))
        ANIV.SetStat("nourishment", math.Clamp(nourishment, 0, 100))
        ANIV.SetStat("sepsis", math.Clamp(sepsis, 0, 100))

    end)

    Log("installed; legacy HUD painter suppressed, Helix state -> ANIV HUD.")
end

-- Addons load before gamemode plugins on a dedicated server, but defer one
-- tick anyway so we always win against late-registering plugins.
timer.Simple(0, Install)

concommand.Add("myrp_aniv_hud_status", function()
    Log("addon=" .. tostring(ANIV ~= nil)
        .. "; enabled=" .. tostring(ANIV and ANIV.State.hudVisible or false)
        .. "; items=" .. tostring(ANIV and ANIV.InventoryCount() or 0))
end)



