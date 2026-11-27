if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("gfl_npc_pack/ground_shadow.lua")
    AddCSLuaFile("gfl_npc_pack/aegis.lua")
    AddCSLuaFile("gfl_npc_pack/aegis_weapon_resources.lua")
    AddCSLuaFile("effects/gfl_pack_aegis_bolter_tracer.lua")
    AddCSLuaFile("gfl_npc_pack_hydra/spawn.lua")
    AddCSLuaFile("effects/gfl_aa02_warp_cannon.lua")
    for _, name in ipairs({"config", "shared", "rig", "geometry", "meshes", "shield", "client"}) do
        AddCSLuaFile("gfl_ares/" .. name .. ".lua")
    end
end

local hydra = include("gfl_npc_pack_hydra/spawn.lua")
local aa02 = include("gfl_ares/config.lua")
local aegis = include("gfl_npc_pack/aegis.lua")
include("gfl_npc_pack/aegis_weapon_resources.lua")
local category = "[GFL] NPC PACK"
local units = {
    {name = "KCCO - Hydra", class = hydra.class, assets = "gfl_hydra_snpc", health = hydra.health},
    {name = "Sangvis Ferri - Manticore", class = "npc_vj_gfl_manticore", assets = "gfl_manticore_snpc"},
}
for class, profile in pairs(aa02.profiles) do
    units[#units + 1] = {name = profile.name, class = class, assets = "gfl_ares", health = profile.health}
end

if SERVER then
    local sharedAssets = {}
    for _, unit in ipairs(units) do
        resource.AddSingleFile("materials/entities/" .. unit.class .. ".png")
        if not sharedAssets[unit.assets] then
            sharedAssets[unit.assets] = true
            local materials = "materials/models/" .. unit.assets .. "/"
            for _, filename in ipairs(file.Find(materials .. "*", "GAME")) do
                resource.AddSingleFile(materials .. filename)
            end
            local geometry = "data_static/" .. unit.assets .. "/"
            for _, filename in ipairs(file.Find(geometry .. "*.txt", "GAME")) do
                resource.AddSingleFile(geometry .. filename)
            end
        end
    end
    for _, unit in ipairs(aegis.units) do
        resource.AddSingleFile("materials/entities/" .. unit.class .. ".png")
    end
    for _, model in ipairs(aegis.modelNames) do
        for _, extension in ipairs({".mdl", ".vvd", ".dx80.vtx", ".dx90.vtx", ".phy"}) do
            resource.AddSingleFile("models/npc/" .. model .. extension)
        end
    end
    for _, material in ipairs(aegis.materialFolders) do
        local folder = "materials/models/" .. material .. "/"
        for _, filename in ipairs(file.Find(folder .. "*", "GAME")) do
            resource.AddSingleFile(folder .. filename)
        end
    end
    local shield = aa02.shieldVisual
    local modelPath = shield.model:sub(1, -5)
    for _, extension in ipairs({".mdl", ".vvd", ".dx80.vtx", ".dx90.vtx", ".sw.vtx"}) do
        resource.AddSingleFile(modelPath .. extension)
    end
    local folder = shield.material:match("^(.*/)")
    for _, extension in ipairs({".vmt", ".vtf"}) do
        for _, filename in ipairs(file.Find(shield.material .. "*" .. extension, "GAME")) do
            resource.AddSingleFile(folder .. filename)
        end
    end
    for _, texture in ipairs({"n", "toon_main", "phong_exp"}) do
        resource.AddSingleFile("materials/models/gfl2/project/shader/" .. texture .. ".vtf")
    end
    resource.AddSingleFile("sound/" .. shield.deploySound)
    resource.AddSingleFile("sound/" .. shield.breakSound)
end

local function register()
    if not (VJ and VJ.AddNPC) then return false end
    for _, unit in ipairs(units) do
        -- Sandbox applies NPC list health after Spawn and Activate.
        local options = unit.health and {Health = unit.health}
        VJ.AddNPC(unit.name, unit.class, category, options)
    end
    for _, unit in ipairs(aegis.units) do
        VJ.AddNPC(unit.name, unit.class, category, {Health = unit.health, Weapons = {unit.weapon}})
    end
    return true
end

if not register() then
    hook.Add("Initialize", "GFL_NPCPack_RegisterUnits", function()
        if not register() and CLIENT then
            MsgC(Color(255, 142, 71), "[GFL] NPC PACK requires VJ Base.\n")
        end
    end)
end
