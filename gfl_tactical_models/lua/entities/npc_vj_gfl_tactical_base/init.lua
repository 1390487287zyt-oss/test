AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:PreInit()
    -- The VJ convar setup can append classes. Give each instance its own list.
    local classes = {}
    for _, tag in ipairs(self.VJ_NPC_Class) do classes[#classes + 1] = tag end
    self.VJ_NPC_Class = classes
end

local function equipDefault(npc, retry)
    if not IsValid(npc) or npc.Dead or npc.Weapon_Disabled or IsValid(npc:GetActiveWeapon()) then return end

    local weapon
    for _, owned in ipairs(npc:GetWeapons()) do
        if IsValid(owned) and owned:GetClass() == npc.GFLTacticalWeapon then
            weapon = owned
            break
        end
    end
    if not weapon then weapon = npc:Give(npc.GFLTacticalWeapon) end
    if IsValid(weapon) then
        npc:SelectWeapon(weapon)
        if npc.IsInitialized and IsValid(npc:GetActiveWeapon()) then
            npc:DoChangeWeapon()
        end
    end

    if retry and not IsValid(npc:GetActiveWeapon()) then
        timer.Simple(.2, function()
            equipDefault(npc, false)
        end)
    end
end

function ENT:Init()
    -- VJ's medic uses GetMaxHealth to select injured allies and cap healing.
    self:SetMaxHealth(self:Health())
    if not self.GFLTacticalWeapon then return end
    -- Let Sandbox apply any selected weapon before equipping the built-in default.
    timer.Simple(.01, function()
        equipDefault(self, true)
    end)
end

local rifles = {
    smg = {
        idle = ACT_HL2MP_IDLE_SMG1, fire = ACT_GESTURE_RANGE_ATTACK_SMG1,
        reload = ACT_RELOAD_SMG1, reloadGesture = ACT_HL2MP_GESTURE_RELOAD_SMG1,
    },
    ar2 = {
        idle = ACT_HL2MP_IDLE_AR2, fire = ACT_GESTURE_RANGE_ATTACK_AR2,
        reload = ACT_RELOAD_AR2, reloadGesture = ACT_HL2MP_GESTURE_RELOAD_AR2,
    },
}

local function nativeActivity(npc, act, first, second, third)
    local translations = npc.AnimationTranslations
    local animation = translations[act]
    if VJ.AnimExists(npc, animation) then return end

    if istable(animation) then
        local usable = {}
        for _, candidate in ipairs(animation) do
            if VJ.AnimExists(npc, candidate) then usable[#usable + 1] = candidate end
        end
        if #usable > 0 then
            translations[act] = usable
            return
        end
    end
    if VJ.AnimExists(npc, act) then
        translations[act] = nil
    elseif VJ.AnimExists(npc, first) then
        translations[act] = first
    elseif VJ.AnimExists(npc, second) then
        translations[act] = second
    elseif VJ.AnimExists(npc, third) then
        translations[act] = third
    else
        translations[act] = nil
    end
end

function ENT:SetAnimationTranslations(holdType)
    -- Detect locomotion supported by the active model. The AGL model also has its own NPC activities.
    if VJ.AnimExists(self, ACT_HL2MP_IDLE) and VJ.AnimExists(self, ACT_HL2MP_WALK) then
        self.AnimModelSet = VJ.ANIM_SET_PLAYER
    end
    local base = baseclass.Get("npc_vj_human_base")
    base.SetAnimationTranslations(self, holdType)

    nativeActivity(self, ACT_IDLE, ACT_HL2MP_IDLE, VJ.SequenceToActivity(self, "idle_all_01"))
    nativeActivity(self, ACT_WALK, ACT_HL2MP_WALK, VJ.SequenceToActivity(self, "walk_all"))
    nativeActivity(self, ACT_RUN, ACT_HL2MP_RUN, VJ.SequenceToActivity(self, "run_all"))
    nativeActivity(self, ACT_WALK_AIM, self.AnimationTranslations[ACT_WALK], ACT_WALK, ACT_HL2MP_WALK)
    nativeActivity(self, ACT_RUN_AIM, self.AnimationTranslations[ACT_RUN], ACT_RUN, ACT_HL2MP_RUN)

    local rifle = rifles[holdType]
    if not rifle then return end
    nativeActivity(self, ACT_IDLE_ANGRY, rifle.idle, ACT_IDLE)
    nativeActivity(self, ACT_RANGE_ATTACK1, rifle.idle, self.AnimationTranslations[ACT_IDLE_ANGRY], ACT_IDLE_ANGRY)
    nativeActivity(self, ACT_GESTURE_RANGE_ATTACK1, rifle.fire)
    nativeActivity(self, ACT_RELOAD, rifle.reload, rifle.reloadGesture, ACT_RELOAD_LOW)
    nativeActivity(self, ACT_RELOAD_LOW, self.AnimationTranslations[ACT_RELOAD], ACT_RELOAD)
    local reload = self.AnimationTranslations[ACT_RELOAD] or ACT_RELOAD
    self.DisableWeaponReloadAnimation = not VJ.AnimExists(self, reload)
end

function ENT:HandlePerceivedRelationship(observer)
    local faction = self.GFLTacticalFaction
    local other = observer.GFLTacticalFaction
    -- Two independent units can both be friendly to ELMO without being each other's allies.
    if (faction == "gunfox" and other == "lab_ingrid")
        or (faction == "lab_ingrid" and other == "gunfox") then
        return D_NU
    end
end
