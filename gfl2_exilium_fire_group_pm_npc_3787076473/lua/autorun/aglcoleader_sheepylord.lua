player_manager.AddValidModel("Aglcoleader", "models/sheepylord/BUTTHEAD/Aglcoleader_pm.mdl");
player_manager.AddValidHands("Aglcoleader", "models/sheepylord/BUTTHEAD/Aglcoleader_arms.mdl" , 0, "000000")

local Category = "Girls' Frontline 2: Exilium"

local NPC = {
    Name = "Aglcoleader (Friendly)",
    Class = "npc_citizen",
    Model = "models/sheepylord/BUTTHEAD/Aglcoleader.mdl",
    Health = "100",
    KeyValues = { citizentype = 4 },
    Weapons = { "weapon_smg1" },
    Category = Category
}

list.Set("NPC", "Aglcoleader_sheepylord_F", NPC)

local NPC = {
    Name = "Aglcoleader (Enemy)",
    Class = "npc_combine_s",
    Model = "models/sheepylord/BUTTHEAD/Aglcoleader.mdl",
    Health = "100",
    Numgrenades = "4",
    Weapons = { "weapon_ar2" },
    Category = Category
}

list.Set("NPC", "Aglcoleader_sheepylord_E", NPC)
