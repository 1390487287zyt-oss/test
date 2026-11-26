player_manager.AddValidModel("MTR Member C", "models/sheepylord/girls_frontline_2/MTR_Member_C_pm.mdl");
player_manager.AddValidHands("MTR Member C", "models/sheepylord/girls_frontline_2/MTR_Member_C_arms.mdl" , 0, "000000")

local Category = "Girls' Frontline 2: Exilium"

local NPC = {
    Name = "MTR Member C (Friendly)",
    Class = "npc_citizen",
    Model = "models/sheepylord/girls_frontline_2/MTR_Member_C.mdl",
    Health = "100",
    KeyValues = { citizentype = 4 },
    Weapons = { "weapon_smg1" },
    Category = Category
}

list.Set("NPC", "MTR_Member_C_sheepylord_F", NPC)

local NPC = {
    Name = "MTR Member C (Enemy)",
    Class = "npc_combine_s",
    Model = "models/sheepylord/girls_frontline_2/MTR_Member_C.mdl",
    Health = "100",
    Numgrenades = "4",
    Weapons = { "weapon_ar2" },
    Category = Category
}

list.Set("NPC", "MTR_Member_C_sheepylord_E", NPC)
