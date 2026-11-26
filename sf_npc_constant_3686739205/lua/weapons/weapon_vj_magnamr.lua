if !file.Exists("autorun/vj_base_autorun.lua","LUA") then return end

SWEP.Base 						= "weapon_vj_base"
SWEP.PrintName					= "Magnetic Anti-Material Rifle"
SWEP.Author 					= "Nikolai"
SWEP.Purpose					= "This weapon is made for NPCs"

-- Main Settings
SWEP.MadeForNPCsOnly 			= true
SWEP.WorldModel					= "models/dih/gf/jaeger_rifle.mdl"
SWEP.HoldType 					= "ar2"
SWEP.Spawnable					= false
SWEP.AdminSpawnable				= false

-- NPC Settings
SWEP.NPC_HasReloadSound 		= true
SWEP.NPC_ReloadSound 			= {"MagnetReload"}
SWEP.Primary.ClipSize 			= 10
SWEP.NPC_FiringDistanceScale 	= 3
SWEP.NPC_CustomSpread 			= 0.01
SWEP.NPC_TimeUntilFire          = 2
SWEP.NPC_NextPrimaryFire        = 3

SWEP.WorldModel_UseCustomPosition = true
SWEP.WorldModel_CustomPositionAngle = Vector(-10,0,190)
SWEP.WorldModel_CustomPositionOrigin = Vector(-2, 0, 0.8)
SWEP.WorldModel_CustomPositionBone = "ValveBiped.Bip01_R_Hand"

SWEP.Primary.Sound              = {}
SWEP.Primary.Damage				= 150
SWEP.Primary.Force				= 25
SWEP.Primary.Tracer				= 1
SWEP.Primary.TracerType			= "magnetic_amr_tracer"
SWEP.Primary.Automatic			= false
SWEP.Primary.Ammo				= "ar2"
SWEP.PrimaryEffects_MuzzleFlash = true
SWEP.PrimaryEffects_MuzzleParticles = {"magnet_muzzleflash"}
SWEP.PrimaryEffects_MuzzleAttachment = "1"
SWEP.PrimaryEffects_SpawnShells = false
SWEP.PrimaryEffects_DynamicLightColor = Color(255, 0, 0)

if CLIENT then
    local laser2mat = Material("effects/blueblacklargebeam")
    local laserdotmat = Material("particle/particle_glow_03")
    local laserwidth = 2
    local laserMaxDist = 10000

    function SWEP:CustomOnInitialize()
        self.SinRandMult1 = math.Rand(0.9, 1.1)
        self.SinRandMult2 = math.Rand(0.9, 1.1)
    end

    function SWEP:CustomOnDrawWorldModel()
        local laserstartpos
        local attach = self:GetAttachment(1)
        if attach then
            laserstartpos = attach.Pos
        else
            laserstartpos = self:GetPos() + self:OBBCenter()
        end

        local dir = self:GetNWVector("EnemyDir")
        local laserOn = self:GetNWBool("Laser_Setting")

        if dir ~= Vector(0,0,0) and laserOn then
            local sin1 = math.sin(CurTime() * 2) * self.SinRandMult1
            local sin2 = math.sin(CurTime() * 2) * self.SinRandMult2
            local idealPos = laserstartpos + dir * laserMaxDist

            if not self.trEndPos then self.trEndPos = idealPos end
            self.trEndPos = LerpVector(0.15, self.trEndPos, idealPos)

            local tr = util.TraceLine({
                start = laserstartpos,
                endpos = self.trEndPos + Vector(sin1, sin2, sin1) * 75,
                mask = MASK_SHOT,
                filter = {self, self:GetOwner()}
            })

            render.SetMaterial(laser2mat)
            render.SetShadowsDisabled(true)
            render.OverrideDepthEnable(true, true)
            render.DrawBeam(laserstartpos, tr.HitPos, laserwidth, 0, 1, Color(255, 0, 0))
            render.SetMaterial(laserdotmat)
            render.DrawSprite(tr.HitPos, laserwidth * 3, laserwidth * 3, Color(255, 50, 50))
            render.OverrideDepthEnable(false, false)
        end
        return true
    end
end

function SWEP:CustomOnThink()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:SetNWBool("Laser_Setting", true)

    local dir
    if owner:IsNPC() then
        local enemy = owner:GetEnemy()
        if IsValid(enemy) then
            dir = (enemy:GetPos() + enemy:OBBCenter() - self:GetPos() - self:OBBCenter()):GetNormalized()
        else
            dir = owner:GetAimVector()
        end
    else
        dir = owner:GetAimVector()
    end

    self:SetNWVector("EnemyDir", dir)
end

function SWEP:CustomOnPrimaryAttack_AfterShoot()
    if not SERVER then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    local shootPos = owner:GetPos()
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        local dist = ply:GetPos():Distance(shootPos)
        local snd  = dist <= 3000 and "AMRF" or "AMRF_FAR"
        net.Start("magnamr_fire_sound")
            net.WriteVector(shootPos)
            net.WriteString(snd)
        net.Send(ply)
    end

    local startPos = owner:GetShootPos()
    local endPos   = startPos + owner:GetAimVector() * 10000
    local tr = util.TraceLine({ start = startPos, endpos = endPos, filter = owner })
    if tr.Hit then
        sound.Play("AMRF_IMPACT", tr.HitPos, 85, 100, 1)
    end
end

function SWEP:OnReload(status)
    if status == "Start" then
        self:SetBodygroup(2, 1)
    end
    if status == "Finish" then
        self:SetBodygroup(2, 0)
    end
end

if SERVER then
    util.AddNetworkString("magnamr_fire_sound")
end

if CLIENT then
    net.Receive("magnamr_fire_sound", function()
        local pos = net.ReadVector()
        local snd = net.ReadString()
        sound.Play(snd, pos, 85, 100, 1)
    end)
end

function SWEP:CustomOnPrimaryAttack_BulletCallback(attacker, tr, dmginfo)
    if not SERVER then return end

    local ang = tr.HitNormal:Angle()
    ang:RotateAroundAxis(ang:Right(), -90)

    local matType = tr.MatType or 0

    if matType == 0 and IsValid(tr.Entity) then
        if tr.Entity.GetMaterialType then
            matType = tr.Entity:GetMaterialType() or 0
        end
        if matType == 0 and (tr.Entity:IsPlayer() or tr.Entity:IsNPC()) then
            matType = MAT_FLESH
        end
    end

    if matType == MAT_FLESH or matType == MAT_BLOODYFLESH then
        ParticleEffect("amr_blood_impact", tr.HitPos, ang)
    elseif matType == MAT_ALIENFLESH or matType == MAT_ANTLION then
        ParticleEffect("amr_alien_blood_impact", tr.HitPos, ang)
    else
        ParticleEffect("vh_hit_amr", tr.HitPos, ang)
    end
end