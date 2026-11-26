VJ.AddPlugin("[GF] Sangvis Ferri", "NPC","BETA")

local vCat = "[GF] Sangvis Ferri"
VJ.AddCategoryInfo(vCat, {Icon = "icons/gf2.png"})

VJ.AddNPC("Golyat","npc_vj_gf2_golyat_base",vCat)
VJ.AddNPC("Golyat Electric","npc_vj_gf2_golyat_electric",vCat)
VJ.AddNPC("Golyat Red","npc_vj_gf2_golyat_red",vCat)
VJ.AddNPC("Golyat Football","npc_vj_gf2_golyat_football",vCat)
VJ.AddNPC("Golyat Fire","npc_vj_gf2_golyat_fire",vCat)
VJ.AddNPC("Golyat Ice","npc_vj_gf2_golyat_ice",vCat)
VJ.AddNPC("Deichgraf", "npc_vj_gf2_deichgraf",vCat)
VJ.AddNPC("Deploy Rippers (Automaton Dropship)","npc_vj_gf2_dropship",vCat)
VJ.AddNPC("Deploy Deichgraf (Automaton Dropship)","npc_vj_gf2_dropship_deichgraf",vCat)

-- Menu --
local AddConvars = {}
AddConvars["vj_gf2_npc_golyat_damage_friendly"] = 1 -- Golyat deals damage to all NPCs.
AddConvars["vj_gf2_npc_deichgraf_missile_count"] = 6 -- How many missiles to launch in a roll.

for k, v in pairs(AddConvars) do
	if !ConVarExists( k ) then CreateConVar( k, v, {FCVAR_ARCHIVE} ) end
end

VJ.AddClientConVar("vj_gf2_draw_shield", 1, "Draw Shield.")
VJ.AddClientConVar("vj_gf2_attachment_draw_laser", 1, "Draw Laser.")
VJ.AddClientConVar("vj_gf2_draw_bullets", 1, "Draw Bullets.")