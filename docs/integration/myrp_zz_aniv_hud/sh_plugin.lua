-- ANEURISM IV HUD bridge for MYRP.
-- Loads last (zz) so it can safely suppress the legacy myrp_hud paint hook.
-- The actual HUD code lives in garrysmod/addons/aneurism_hud.

PLUGIN.name = "ANEURISM IV HUD (MYRP bridge)"
PLUGIN.author = "MYRP Development"
PLUGIN.description = "Replaces the legacy MYRP HUD with the Aneurism IV HUD and feeds it live Helix state."

ix.util.Include("cl_plugin.lua", "client")
