AddCSLuaFile()
if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Type 			= "anim"
ENT.Base 			= "obj_vj_projectile_base"
ENT.PrintName		= "«ADVENT» Officer Signal Grenade"
ENT.Author 			= "DrVrej"
ENT.Category		= "VJ Base"
ENT.SoundTbl_OnCollide = "gren_collision"
ENT.PhysicsSounds = true

ENT.Spawnable = false

if !SERVER then return end

-- Основные параметры
ENT.Model = "models/advent/advent_grenade.mdl"
ENT.ProjectileType = VJ.PROJ_TYPE_PROP
ENT.CollisionBehavior = VJ.PROJ_COLLISION_NONE
ENT.VJ_ID_Grenade = false
ENT.VJ_ID_Grabbable = false

function ENT:Init()
    self:SetSubMaterial(0,"models/advent_grenades/decoygrenade")
    self:SetUseType(SIMPLE_USE)
    self:AddFlags(FL_GRENADE)

    timer.Simple(1.5, function()
        if not IsValid(self) then return end

        self:EmitSound("OfficerSmokeSignal")

        local envFlare = ents.Create("env_flare")
        if not IsValid(envFlare) then return end

        local attach = self:GetAttachment(self:LookupAttachment("1"))
        if attach then
            envFlare:SetPos(attach.Pos)
        else
            envFlare:SetPos(self:GetPos())
        end

        envFlare:SetAngles(self:GetAngles())
        envFlare:SetParent(self)
        envFlare:SetKeyValue("Scale", "5")
        envFlare:SetKeyValue("spawnflags", "4")
        envFlare:Spawn()
        envFlare:Activate()
        envFlare:SetOwner(self)

        envFlare:SetRenderMode(RENDERMODE_TRANSCOLOR)
        envFlare:SetColor(Color(255, 255, 255, 0))

        self.CurrentIdleSound = CreateSound(self, "weapons/flaregun/burn.wav")
        self.CurrentIdleSound:SetSoundLevel(70)
        self.CurrentIdleSound:PlayEx(1, 100)

        self.EnvFlare = envFlare

        local ringTimer = "OfficerSignalRing_" .. self:EntIndex()
        timer.Create(ringTimer, 2, 0, function()
            if not IsValid(envFlare) or not IsValid(self) then
                timer.Remove(ringTimer)
                return
            end
            self:EmitSound("OfficerSignalRing")
        end)

        -- Удаление flare через 40 секунд
        timer.Simple(40, function()
            if IsValid(envFlare) then
                envFlare:Remove()
            end
            timer.Remove(ringTimer)
        end)
    end)

    timer.Simple(60, function()
        if IsValid(self) then
            self:Remove()
        end
    end)
end

function ENT:Use(activator, caller)
	if IsValid(activator) and activator:IsPlayer() and activator:Alive() then
		activator:PickupObject(self)
	end
end