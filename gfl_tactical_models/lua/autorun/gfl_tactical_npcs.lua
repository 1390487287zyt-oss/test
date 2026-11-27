if SERVER then
    AddCSLuaFile()
    AddCSLuaFile("gfl_tactical_npcs/config.lua")
end

local config = include("gfl_tactical_npcs/config.lua")

for _, unit in ipairs(config.units) do
    local playerModelName = unit[5]
    if playerModelName then
        local path = "models/" .. unit[3]
        player_manager.AddValidModel(playerModelName, path .. "_pm.mdl")
        player_manager.AddValidHands(playerModelName, path .. "_arms.mdl", 0, "000000")
    end
end

if SERVER then
    local function tagResistance(npc)
        if not IsValid(npc) then return end
        local values = npc:GetKeyValues()
        local citizenType = tonumber(npc:GetInternalVariable("m_Type")) or tonumber(values.citizentype)
        if citizenType ~= (CT_REBEL or 3) or values.hostile == true or tonumber(values.hostile) == 1 then return end

        -- A separate tag lets ELMO Enemy ally with rebels while remaining hostile to players.
        local classes = {}
        for _, tag in ipairs(npc.VJ_NPC_Class or {"CLASS_PLAYER_ALLY"}) do
            if tag == config.resistanceTag or tag == "CLASS_COMBINE" then return end
            classes[#classes + 1] = tag
        end
        classes[#classes + 1] = config.resistanceTag
        npc.VJ_NPC_Class = classes
    end

    hook.Add("OnEntityCreated", "GFLTacticalTagResistance", function(ent)
        if ent:GetClass() ~= "npc_citizen" then return end
        timer.Simple(0, function() tagResistance(ent) end)
    end)
    hook.Add("InitPostEntity", "GFLTacticalTagMapResistance", function()
        for _, ent in ipairs(ents.FindByClass("npc_citizen")) do tagResistance(ent) end
    end)
end

local function register()
    if not VJ or not VJ.AddNPC then return false end

    for _, unit in ipairs(config.units) do
        for _, side in ipairs(config.sides) do
            local variant = config.Variant(unit[1], side)
            local icon = "entities/" .. variant.class .. ".png"
            VJ.AddNPC(variant.name, variant.class, config.category, {Weapons = {variant.weapon}, IconOverride = icon})
            if SERVER then resource.AddSingleFile("materials/" .. icon) end
        end
    end
    return true
end

if not register() then
    hook.Add("Initialize", "GFLTacticalRegisterNPCs", function()
        if not register() and CLIENT then
            MsgN(config.category .. " requires VJ Base.")
        end
    end)
end
