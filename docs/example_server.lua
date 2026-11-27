--[[
 Optional server-side example. Copy into your gamemode's lua/ folder if you
 want the server to drive the client HUD. Do NOT ship it as-is in autorun,
 otherwise every player will constantly receive test values.
]]

util.AddNetworkString("ANIV_SetStat")
util.AddNetworkString("ANIV_SetStats")
util.AddNetworkString("ANIV_SetMuted")

local function SendStats(ply)
	net.Start("ANIV_SetStats")
		net.WriteTable({
			blood  = ply:Health() / ply:GetMaxHealth() * 100,
			air    = ply.ANIV_Air or 100,
			sanity = ply.ANIV_Sanity or 100,
			bone   = ply.ANIV_Bone or 100,
			leg    = ply.ANIV_Leg or 100,
		})
	net.Send(ply)
end

hook.Add("PlayerSpawn", "ANIV_ExampleSpawn", function(ply)
	timer.Simple(1, function() if IsValid(ply) then SendStats(ply) end end)
end)

hook.Add("PlayerHurt", "ANIV_ExampleHurt", function(ply)
	SendStats(ply)
end)
