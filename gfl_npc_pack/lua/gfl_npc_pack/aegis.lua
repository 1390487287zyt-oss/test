-- Default Aegis loadouts follow the corresponding SF NPC Constant units.
local sangvisHealth = 800
local sangvisSwapHealth = 1000
local kccoHealth = 1800
local kccoSwapHealth = 2000

local aegis = {
    units = {
        {name = "Sangvis Ferri - Aegis Firefighters", class = "npc_vj_gfl_aegis_sand_firefighters", weapon = "weapon_vj_gfl_pack_aegis_firefighters", health = sangvisHealth},
        {name = "Sangvis Ferri - Aegis Myrmidon", class = "npc_vj_gfl_aegis_sand_myrmidon", weapon = "weapon_vj_gfl_pack_aegis_myrmidon", health = sangvisHealth},
        {name = "Sangvis Ferri - Aegis", class = "npc_vj_gfl_aegis_sand_bolter", weapon = "weapon_vj_gfl_pack_aegis_bolter", health = sangvisHealth},
        {name = "Sangvis Ferri - Aegis SWAP Firefighters", class = "npc_vj_gfl_aegis_sand_swap_firefighters", weapon = "weapon_vj_gfl_pack_aegis_firefighters", health = sangvisSwapHealth},
        {name = "Sangvis Ferri - Aegis SWAP Myrmidon", class = "npc_vj_gfl_aegis_sand_swap_myrmidon", weapon = "weapon_vj_gfl_pack_aegis_myrmidon", health = sangvisSwapHealth},
        {name = "Sangvis Ferri - Aegis SWAP", class = "npc_vj_gfl_aegis_sand_swap_bolter", weapon = "weapon_vj_gfl_pack_aegis_bolter", health = sangvisSwapHealth},
        {name = "KCCO - Aegis Firefighters", class = "npc_vj_gfl_aegis_green_firefighters", weapon = "weapon_vj_gfl_pack_aegis_firefighters", health = kccoHealth},
        {name = "KCCO - Aegis Myrmidon", class = "npc_vj_gfl_aegis_green_myrmidon", weapon = "weapon_vj_gfl_pack_aegis_myrmidon", health = kccoHealth},
        {name = "KCCO - Aegis", class = "npc_vj_gfl_aegis_green_bolter", weapon = "weapon_vj_gfl_pack_aegis_bolter", health = kccoHealth},
        {name = "KCCO - Aegis SWAP Firefighters", class = "npc_vj_gfl_aegis_green_swap_firefighters", weapon = "weapon_vj_gfl_pack_aegis_firefighters", health = kccoSwapHealth},
        {name = "KCCO - Aegis SWAP Myrmidon", class = "npc_vj_gfl_aegis_green_swap_myrmidon", weapon = "weapon_vj_gfl_pack_aegis_myrmidon", health = kccoSwapHealth},
        {name = "KCCO - Aegis SWAP", class = "npc_vj_gfl_aegis_green_swap_bolter", weapon = "weapon_vj_gfl_pack_aegis_bolter", health = kccoSwapHealth},
    },
    modelNames = {"gfl_aegis_green", "gfl_aegis_green_swap", "gfl_aegis_sand", "gfl_aegis_sand_swap"},
    materialFolders = {"gfl_aegis_green", "gfl_aegis_sand", "gfl_aegis_shared"},
}

local unitsByClass = {}
for _, unit in ipairs(aegis.units) do
    unitsByClass[unit.class] = unit
end

function aegis.setSpawnHealth(npc)
    local unit = unitsByClass[npc:GetClass()]
    if not unit then return end

    -- Match NPC list health when created directly, after VJ Base scales health.
    npc.StartHealth = unit.health
    npc:SetMaxHealth(unit.health)
    npc:SetHealth(unit.health)
end

function aegis.equipOnSpawn(npc)
    local unit = unitsByClass[npc:GetClass()]
    if not unit then return end

    -- Let Sandbox finish applying its equipment and assigning the creator.
    timer.Simple(engine.TickInterval(), function()
        if not IsValid(npc) or npc.Dead or npc.Weapon_Disabled or IsValid(npc:GetActiveWeapon()) then return end

        local weapon = npc.Equipment
        if weapon == "none" then return end
        if type(weapon) ~= "string" or weapon == "" then
            local creator = npc:GetCreator()
            if IsValid(creator) and creator:IsPlayer() and creator:GetInfo("gmod_npcweapon") == "none" then return end
            weapon = unit.weapon
        end

        if IsValid(npc:DoChangeWeapon(weapon)) then
            npc.Equipment = weapon
        end
    end)
end

return aegis
