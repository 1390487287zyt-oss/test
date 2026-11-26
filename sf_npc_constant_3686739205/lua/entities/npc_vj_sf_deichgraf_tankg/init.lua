AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/gflvj/sf/sf_deichgraf_tank_turret.mdl"}
ENT.VJ_NPC_Class = {"CLASS_SANGVIS"}

-- Параметры танковой стрельбы (для базового класса)
ENT.Tank_Shell_SpawnPos = Vector(160,0,128)
ENT.Tank_Shell_DynamicLightPos = Vector(160,0,0)
ENT.Tank_Shell_MuzzleFlashPos = Vector(160,0,128)
ENT.Tank_Shell_ParticlePos = Vector(160,0,128)
ENT.Tank_AngleDiffuseNumber = 0
ENT.Tank_UseNegativeAngleDiffuseNumber = false
ENT.Tank_AngleDiffuseGeneralNumber = 2.5
ENT.Tank_UsesRightAngles = false
ENT.Tank_NotFacingTargetShootPos = 100

-- Настройки ракетной атаки
ENT.RocketBurstCount = 6               -- Сколько ракет в залпе
ENT.RocketBurstDelay = 1             -- Задержка между ракетами в залпе (сек)
ENT.RocketSalvoCooldown = 30            -- Задержка между залпами (сек)

-- Смещения для каждой ракеты (позиция относительно турели)
ENT.RocketOffsets = {
    { up = 600, right = 200, pitch = 33 },
    { up = 700, right = 200, pitch = 28 },
    { up = 700, right = 200, pitch = 25 }
}

util.AddNetworkString("vj_ksso_t45coeus_shooteffects")

function ENT:StartShootEffects()
    net.Start("vj_ksso_t45coeus_shooteffects")
    net.WriteEntity(self)
    net.Broadcast()
end

-- Пулемётная стрельба (ближняя дистанция)
function ENT:FireGun() 
    local Bullet = {}
    Bullet.Num = 1 
    Bullet.Spread = Vector(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
    Bullet.Damage = 15
    Bullet.Force = 5
    Bullet.AmmoType = "SMG1"
    Bullet.Tracer = 1
    Bullet.TracerName = "Tracer"
    Bullet.Src = self:GetAttachment(1).Pos
    Bullet.Dir = (self:GetEnemy():GetPos()+self:GetEnemy():OBBCenter())-self:GetAttachment(1).Pos
    self:FireBullets(Bullet)
    VJ_EmitSound(self, "vj_underhell/snpc/pmc_sentry_gun/shoot1.wav", 90, self:VJ_DecideSoundPitch(100, 110))
    
    ParticleEffectAttach("vj_bms_turret_full", PATTACH_POINT_FOLLOW, self, 1)
    timer.Simple(0.3, function() if IsValid(self) then self:StopParticles() end end)

    local muzzlelight = ents.Create("light_dynamic")
    muzzlelight:SetKeyValue("brightness", "4")
    muzzlelight:SetKeyValue("distance", "120")
    muzzlelight:Fire("Color", "255 150 60")
    muzzlelight:SetPos(self:GetAttachment(1).Pos)
    muzzlelight:SetLocalAngles(self:GetAngles())
    muzzlelight:Spawn()
    muzzlelight:Activate()
    muzzlelight:SetParent(self)
    muzzlelight:Fire("TurnOn", "", 0)
    muzzlelight:Fire("Kill", "", 0.07)
    self:DeleteOnRemove(muzzlelight)
end

-- Ракетная стрельба (дальняя дистанция)
function ENT:FireRocket()
    if not IsValid(self:GetEnemy()) then return end
    
    self:StartShootEffects()
    VJ_EmitSound(self, "weapons/rpg/rocketfire1.wav", 100, 100)

    local function CreateMissile(offsetUp, offsetRight, pitchAngle)
        if not IsValid(self) then return end
        local ent = ents.Create("obj_vj_mcl_mlrs_he_art")
        if not IsValid(ent) then return end
        
        local Forward = self:GetAimVector()
        local pos = self:GetPos() 
                    + (self:GetUp() * offsetUp) 
                    + (self:GetRight() * offsetRight) 
                    + Forward * 2
        
        ent:SetPos(pos)
        ent:SetAngles(Angle(pitchAngle, self:EyeAngles().yaw, 0))
        ent:SetOwner(self)
        ent:SetSaveValue("m_flDamage", 200)
        ent:Spawn()
        ent:Activate()
        
        local phys = ent:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetVelocity(Forward * 1500)
        end
    end

    -- Выпускаем ракеты с заданной задержкой
    local count = math.min(self.RocketBurstCount, #self.RocketOffsets)
    for i = 1, count do
        local offset = self.RocketOffsets[i]
        timer.Simple((i-1) * self.RocketBurstDelay, function()
            if IsValid(self) then
                CreateMissile(offset.up, offset.right, offset.pitch)
            end
        end)
    end
end

-- Основная логика атаки
function ENT:CustomAttack()
    if not IsValid(self:GetEnemy()) or self.VJ_IsBeingControlled then return end
    if not self.Tank_FacingTarget then return end

    local enemyDistance = self:GetEnemy():GetPos():Distance(self:GetPos())
    
    if enemyDistance <= 1500 then
        -- Ближняя дистанция: пулемёт
        self:FireGun()
    elseif enemyDistance <= 3000 then
        -- Дальняя дистанция: ракеты с кулдауном
        if not self.NextRocketTime or self.NextRocketTime < CurTime() then
            self:FireRocket()
            self.NextRocketTime = CurTime() + self.RocketSalvoCooldown
        end
    end
end

-- Опционально: поддержка анимационных ключей (если нужно вызывать ракеты по ключу "Pewew")
function ENT:CustomOnAcceptInput(key, activator, caller, data)
    if key == "Pewew" then
        self:FireRocket()
    end
end