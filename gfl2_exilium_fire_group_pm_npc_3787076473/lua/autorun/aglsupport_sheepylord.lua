player_manager.AddValidModel("Aglsupport", "models/sheepylord/BUTTHEAD/Aglsupport_pm.mdl");
player_manager.AddValidHands("Aglsupport", "models/sheepylord/BUTTHEAD/Aglsupport_arms.mdl" , 0, "000000")

local Category = "Girls' Frontline 2: Exilium"

local NPC = {
    Name = "Aglsupport (Friendly)",
    Class = "npc_citizen",
    Model = "models/sheepylord/BUTTHEAD/Aglsupport.mdl",
    Health = "100",
    KeyValues = { citizentype = 4 },
    Weapons = { "weapon_smg1" },
    Category = Category
}

list.Set("NPC", "Aglsupport_sheepylord_F", NPC)

local NPC = {
    Name = "Aglsupport (Enemy)",
    Class = "npc_combine_s",
    Model = "models/sheepylord/BUTTHEAD/Aglsupport.mdl",
    Health = "100",
    Numgrenades = "4",
    Weapons = { "weapon_ar2" },
    Category = Category
}

list.Set("NPC", "Aglsupport_sheepylord_E", NPC)
