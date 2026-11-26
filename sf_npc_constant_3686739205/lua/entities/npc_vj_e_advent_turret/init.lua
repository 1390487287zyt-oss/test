AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/advent/ADVENT_Turret.mdl"
ENT.HullType = HULL_LARGE
ENT.StartHealth = 3000
ENT.SightDistance = 5000
ENT.MovementType = VJ_MOVETYPE_STATIONARY
ENT.CanTurnWhileStationary = false
ENT.Bleeds = false
ENT.Immune_Toxic = true
ENT.Immune_Fire = true
ENT.Immune_Sonic = true

ENT.VJ_NPC_Class = {"CLASS_SANGVIS"}
ENT.HasMeleeAttack = false
ENT.HasRangeAttack = false
ENT.AnimTbl_RangeAttack = false

ENT.SoundTbl_Alert = {"turret_alert1","turret_alert2","turret_alert3","turret_alert4"}
ENT.SoundTbl_RangeAttack = {"MF1","MF2","MF3"}

local MAX_PITCH = 18
local FIRE_RATE = 0.05          
local AIM_TOLERANCE = 9

local BURST_MIN_TIME = 3        
local BURST_MAX_TIME = 5        

local COOLDOWN_MIN = 2.5        
local COOLDOWN_MAX = 4.0        

ENT.Turret_CurrentYaw = 0
ENT.Turret_CurrentPitch = 0
ENT.Turret_NextFireT = 0
ENT.Turret_IsFiring = false
ENT.Turret_BurstEndTime = 0
ENT.Turret_CooldownEnd = 0
ENT.Turret_UseWideSpread = false

function ENT:CustomOnInitialize()
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:SetPoseParameter("yaw",0)
    self:SetPoseParameter("pitch",0)
    self.HasSight = true
    self.SightAngle = 360
end

function ENT:CustomOnThink()
    local muzzleID = self:LookupAttachment("1")
    local hasMuzzle = muzzleID and muzzleID > 0

    local enemy = self:GetEnemy()

    if IsValid(enemy) and (not enemy:Alive() or enemy:Health() <= 0) then
        self:SetEnemy(NULL)
        self.Turret_IsFiring = false
        self.Turret_CooldownEnd = 0
        enemy = NULL
    end

    if not IsValid(enemy) then
        self.Turret_CurrentYaw = Lerp(FrameTime() * 5,self.Turret_CurrentYaw,0)
        self.Turret_CurrentPitch = Lerp(FrameTime() * 5,self.Turret_CurrentPitch,0)
        self:SetPoseParameter("yaw",self.Turret_CurrentYaw)
        self:SetPoseParameter("pitch",self.Turret_CurrentPitch)
        self.Turret_IsFiring = false
        return
    end

    local myAng = self:GetAngles()

    local fireSrc
    if hasMuzzle then
        local attFire = self:GetAttachment(muzzleID)
        fireSrc = attFire and attFire.Pos or self:GetPos()
    else
        fireSrc = self:GetPos()
    end

    local targetPos = enemy:WorldSpaceCenter()
    local toEnemy = (targetPos - fireSrc):Angle()

    local yawTarget = math.AngleDifference(myAng.y,toEnemy.y) + 180
    local pitchTarget = math.Clamp(-math.AngleDifference(toEnemy.p,myAng.p),-MAX_PITCH,MAX_PITCH)

    self.Turret_CurrentYaw = Lerp(FrameTime() * 10,self.Turret_CurrentYaw,yawTarget)
    self.Turret_CurrentPitch = Lerp(FrameTime() * 10,self.Turret_CurrentPitch,pitchTarget)
    self:SetPoseParameter("yaw",self.Turret_CurrentYaw)
    self:SetPoseParameter("pitch",self.Turret_CurrentPitch)

    local yawDiff = math.abs(math.AngleDifference(self.Turret_CurrentYaw,yawTarget))
    local pitchDiff = math.abs(math.AngleDifference(self.Turret_CurrentPitch,pitchTarget))
    local canAim = yawDiff <= AIM_TOLERANCE and pitchDiff <= AIM_TOLERANCE

    local curTime = CurTime()

    if self.Turret_IsFiring then
        if curTime > self.Turret_BurstEndTime then
            self.Turret_IsFiring = false
            self.Turret_UseWideSpread = false
            self.Turret_CooldownEnd = curTime + math.Rand(COOLDOWN_MIN,COOLDOWN_MAX)
            return
        end
    else
        if curTime > self.Turret_CooldownEnd then
            self.Turret_IsFiring = true
            self.Turret_BurstEndTime = curTime + math.Rand(BURST_MIN_TIME,BURST_MAX_TIME)
            self.Turret_UseWideSpread = math.random(1,10) == 1
        else
            return
        end
    end

    if canAim and curTime >= self.Turret_NextFireT then
        self.Turret_NextFireT = curTime + FIRE_RATE

        local shootSrc
        if hasMuzzle then
            local attFire = self:GetAttachment(muzzleID)
            shootSrc = attFire and attFire.Pos or self:GetPos()
        else
            shootSrc = self:GetPos()
        end

        local shootDir = (enemy:WorldSpaceCenter() - shootSrc):GetNormalized()
        local spreadVec = self.Turret_UseWideSpread and Vector(0.1,0.1,0) or Vector(0.02,0.02,0)

        self:FireBullets({
            Attacker = self,
            Src = shootSrc,
            Dir = shootDir,
            Spread = spreadVec,
            Tracer = 1,
            TracerName = "magnetic_cannon_tracer",
            Force = 5,
            Damage = 50,
            AmmoType = "SMG1",
            Num = 1,
        })

        if hasMuzzle then
            ParticleEffectAttach("magnet_muzzleflash",PATTACH_POINT_FOLLOW,self,muzzleID)
        end

        VJ.EmitSound(self,self.SoundTbl_RangeAttack,90,math.random(95,105))
    end
end

function ENT:CustomOnAlert(ent)
    VJ.EmitSound(self,self.SoundTbl_Alert)
end

function ENT:CustomOnDeath(dmginfo,hitgroup,ent)
end

-- 40% сопротивление физическому урону
function ENT:CustomOnTakeDamage(dmginfo)
    local dmg = dmginfo:GetDamage()
    local dmgtype = dmginfo:GetDamageType()
    
    -- Типы физического урона (пули, дробовики, рубящее, дробящее, снайперское)
    if bit.band(dmgtype, DMG_BULLET) ~= 0 or
       bit.band(dmgtype, DMG_BUCKSHOT) ~= 0 or
       bit.band(dmgtype, DMG_SLASH) ~= 0 or
       bit.band(dmgtype, DMG_CLUB) ~= 0 or
       bit.band(dmgtype, DMG_SNIPER) ~= 0 then
        dmg = dmg * 0.6 -- 40% сопротивления (получает 60% урона)
        dmginfo:SetDamage(dmg)
    end
    
    return dmg
end

local defAng = Angle(0,0,0)

function ENT:OnCreateDeathCorpse(dmginfo,hitgroup,corpse)
    local spawnPos = corpse:GetPos()

    corpse:SetMoveType(MOVETYPE_NONE)
    corpse:SetSolid(SOLID_VPHYSICS)
    corpse:SetCollisionGroup(COLLISION_GROUP_NONE)

    local phys = corpse:GetPhysicsObject()
    if IsValid(phys) then
        phys:EnableMotion(false)
        phys:EnableGravity(false)
    end

    corpse:SetPos(self:GetPos())
    corpse:SetAngles(self:GetAngles())

    if corpse:GetAttachment(1) then
        ParticleEffectAttach("electrotona",PATTACH_POINT_FOLLOW,corpse,1)
    else
        ParticleEffectAttach("electrotona",PATTACH_ABSORIGIN_FOLLOW,corpse,0)
    end

    local zapSounds = {
        "ambient/energy/zap5.wav",
        "ambient/machines/zap1.wav",
        "ambient/energy/zap2.wav",
        "ambient/energy/zap9.wav"
    }

    table.Shuffle(zapSounds)

    for i = 1,#zapSounds do
        timer.Simple((i - 1) * 0.7,function()
            if IsValid(corpse) then
                sound.Play(zapSounds[i],spawnPos,90,100,1)
            end
        end)
    end

    timer.Simple(3,function()
        if not IsValid(corpse) then return end

        corpse:StopParticles()
        corpse:SetBodygroup(1,1)
        corpse:SetSubMaterial(0,"models/advent_turret/Adv_Turret_Base_D")

        local closestDist = math.huge
        for _,ply in ipairs(player.GetAll()) do
            local d = spawnPos:Distance(ply:GetPos())
            if d < closestDist then closestDist = d end
        end

        local explodeSound = closestDist <= 2000
        and (math.random(1,2) == 1 and "Transp_exp_close_1" or "Transp_exp_close_2")
        or (math.random(1,2) == 1 and "Transp_exp_far_1" or "Transp_exp_far_2")

        sound.Play(explodeSound,spawnPos,140,100,1)
        ParticleEffect("transp_d_ground",spawnPos,Angle(0,0,0),nil)

        local dmgInfo = DamageInfo()
        dmgInfo:SetAttacker(game.GetWorld())
        dmgInfo:SetInflictor(game.GetWorld())
        dmgInfo:SetDamage(100)
        dmgInfo:SetDamageType(DMG_BLAST + DMG_BURN)
        util.BlastDamageInfo(dmgInfo,spawnPos,300)

        local debrisList = {
            "models/props_debris/metal_panelchunk01b.mdl",
            "models/props_debris/metal_panelchunk01d.mdl",
            "models/props_debris/metal_panelchunk01e.mdl",
            "models/props_debris/metal_panelchunk01f.mdl",
            "models/props_debris/metal_panelchunk01g.mdl",
            "models/props_debris/metal_panelchunk02d.mdl",
            "models/props_debris/metal_panelchunk02e.mdl",
            "models/props_debris/metal_panelshard01d.mdl",
        }

        for i = 1,math.random(6,10) do
            local mdl = debrisList[math.random(#debrisList)]
            local prop = ents.Create("prop_physics")
            if not IsValid(prop) then continue end

            prop:SetModel(mdl)
            prop:SetPos(spawnPos + VectorRand() * 40)
            prop:SetAngles(AngleRand())
            prop:Spawn()
            prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
            prop:SetSubMaterial(0,"models/minic23/xcom2/advent/advent_transporter_destroyed")

            local pphys = prop:GetPhysicsObject()
            if IsValid(pphys) then
                pphys:SetVelocity(VectorRand() * math.random(400,1200) + Vector(0,0,300))
                pphys:AddAngleVelocity(VectorRand() * math.random(200,600))
            end

            prop:Ignite(math.random(20,40),0)

            timer.Simple(20,function()
                if IsValid(prop) then
                    prop:Remove()
                end
            end)
        end

        ParticleEffectAttach("SmokeFabric",PATTACH_ABSORIGIN_FOLLOW,corpse,0)

        timer.Simple(60,function()
            if not IsValid(corpse) then return end

            corpse:SetRenderMode(RENDERMODE_TRANSALPHA)
            corpse:Fire("Alpha","0",5)

            timer.Simple(5,function()
                if IsValid(corpse) then
                    corpse:Remove()
                end
            end)
        end)
    end)
end

function ENT:CustomOnRemove()
end