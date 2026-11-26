player_manager.AddValidModel("Aglleader", "models/sheepylord/BUTTHEAD/Aglleader_pm.mdl");
player_manager.AddValidHands("Aglleader", "models/sheepylord/BUTTHEAD/Aglleader_arms.mdl" , 0, "000000")

local Category = "Girls' Frontline 2: Exilium"

local NPC = {
    Name = "Aglleader (Friendly)",
    Class = "npc_citizen",
    Model = "models/sheepylord/BUTTHEAD/Aglleader.mdl",
    Health = "100",
    KeyValues = { citizentype = 4 },
    Weapons = { "weapon_smg1" },
    Category = Category
}

list.Set("NPC", "Aglleader_sheepylord_F", NPC)

local NPC = {
    Name = "Aglleader (Enemy)",
    Class = "npc_combine_s",
    Model = "models/sheepylord/BUTTHEAD/Aglleader.mdl",
    Health = "100",
    Numgrenades = "4",
    Weapons = { "weapon_ar2" },
    Category = Category
}

list.Set("NPC", "Aglleader_sheepylord_E", NPC)
