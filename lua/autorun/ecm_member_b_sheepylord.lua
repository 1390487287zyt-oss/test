player_manager.AddValidModel("ECM Member B", "models/sheepylord/girls_frontline_2/ECM_Member_B_pm.mdl");
player_manager.AddValidHands("ECM Member B", "models/sheepylord/girls_frontline_2/ECM_Member_B_arms.mdl" , 0, "000000")

local Category = "Girls' Frontline 2: Exilium"

local NPC = {
    Name = "ECM Member B (Friendly)",
    Class = "npc_citizen",
    Model = "models/sheepylord/girls_frontline_2/ECM_Member_B.mdl",
    Health = "100",
    KeyValues = { citizentype = 4 },
    Weapons = { "weapon_smg1" },
    Category = Category
}

list.Set("NPC", "ECM_Member_B_sheepylord_F", NPC)

local NPC = {
    Name = "ECM Member B (Enemy)",
    Class = "npc_combine_s",
    Model = "models/sheepylord/girls_frontline_2/ECM_Member_B.mdl",
    Health = "100",
    Numgrenades = "4",
    Weapons = { "weapon_ar2" },
    Category = Category
}

list.Set("NPC", "ECM_Member_B_sheepylord_E", NPC)
