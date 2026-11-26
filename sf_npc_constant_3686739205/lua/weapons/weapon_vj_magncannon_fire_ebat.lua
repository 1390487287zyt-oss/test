if not file.Exists("autorun/vj_base_autorun.lua", "LUA") then return end

SWEP.Base                     = "weapon_vj_base"
SWEP.PrintName                = "Flamethrower"
SWEP.Author                   = "Nikolai"
SWEP.WorldModel_UseCustomPosition = true -- Should the gun use custom position? This can be used to fix guns that are in the crotch
SWEP.WorldModel_CustomPositionAngle = Vector(-10, 0, 180)
SWEP.WorldModel_CustomPositionOrigin = Vector(-1, 8, 1)
SWEP.WorldModel_CustomPositionBone = "ValveBiped.Bip01_R_Hand" -- The bone it will use as the main point (Owner's bone)

if CLIENT then
    SWEP.Slot                 = 2
    SWEP.SlotPos              = 4
    SWEP.UseHands             = true
end

SWEP.MadeForNPCsOnly          = true
SWEP.NPC_HasSecondaryFire     = false
SWEP.NPC_NextPrimaryFire      = VJ.PICK(1,3)
SWEP.NPC_TimeUntilFire        = 0.2

SWEP.WorldModel               = "models/advent_flamethrower.mdl"
SWEP.HoldType                 = "shotgun"
SWEP.Spawnable                = true
SWEP.AdminSpawnable           = false

SWEP.NPC_FiringDistanceMax = 100000
SWEP.Primary.DisableBulletCode= true
SWEP.Primary.Damage           = 60
SWEP.Primary.Force            = 40
SWEP.Primary.ClipSize         = 75
SWEP.Primary.Delay            = 0.1
SWEP.Primary.TracerType       = ""
SWEP.Primary.Automatic        = true
SWEP.Primary.Ammo             = "AR2"
SWEP.Primary.Sound            = {"FLAMETHROWER.FlameLoop"}
SWEP.Primary.DistantSound     = {"FLAMETHROWER.FlameLoop"}
SWEP.PrimaryEffects_SpawnShells = false
SWEP.PrimaryEffects_DynamicLightColor = Color(0, 31, 225)

SWEP.HasReloadSound           = true
SWEP.ReloadSound              = {"weapons/ar2/ar2_reload.wav"}
SWEP.Reload_TimeUntilAmmoIsSet= 0.8
SWEP.NPC_CustomSpread         = 2
SWEP.NextDamageTime = 0

SWEP.hookID = ""
SWEP.owner = ""

-----------------------
-- FLAME CONE LOGIC --
-----------------------

function SWEP:StartFlameCone()
    if IsValid(self.FlameCone) then return end
    local att = self:GetAttachment(1)
    if not att then return end

    local cone = ents.Create("prop_physics")
    if not IsValid(cone) then return end

    cone:SetModel("models/hunter/misc/cone2x2.mdl")
    cone:SetParent(self, 1)
    cone:SetLocalPos(Vector(0,0,0))
    cone:SetLocalAngles(Angle(0, -5, 0))
    cone:SetMoveType(MOVETYPE_NONE)
    cone:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
    cone:SetRenderMode(RENDERMODE_TRANSALPHA)
    cone:SetColor(Color(255, 140, 0, 0))
    cone:SetMaterial("invisible")
    cone:SetPos(att.Pos)
    cone:SetAngles(att.Ang)
    cone:DrawShadow(false)
    cone:Spawn()

    self.FlameCone = cone
end

function SWEP:UpdateFlameCone()
    if not IsValid(self.FlameCone) then return end

    local origin  = self.FlameCone:GetPos()
    local forward = self.FlameCone:GetForward()

    local coneLength = 1300        -- Длина конуса вперёд
    local coneRadius = 120        -- Радиус у конца конуса

    for _, ent in ipairs(ents.FindInSphere(origin, coneLength)) do
        if (ent:IsPlayer() or ent:IsNPC()) and ent:Alive() then

            local toEnt = ent:NearestPoint(origin) - origin

            -- Расстояние вперёд по оси конуса
            local forwardDist = toEnt:Dot(forward)

            if forwardDist > 0 and forwardDist <= coneLength then

                -- Точка на центральной оси конуса
                local axisPoint = origin + forward * forwardDist

                -- Боковое расстояние от оси
                local sideDist = (ent:NearestPoint(origin) - axisPoint):Length()

                -- Радиус конуса увеличивается к концу
                local allowedRadius = (forwardDist / coneLength) * coneRadius

                if sideDist <= allowedRadius then
                    local d = DamageInfo()
                    d:SetDamage(self.Primary.Damage)
                    d:SetDamageType(DMG_BURN)
                    d:SetAttacker(self:GetOwner() or self)
                    d:SetInflictor(self)

                    ent:TakeDamageInfo(d)
                    ent:Ignite(8, 0)
                end
            end
        end
    end
end

function SWEP:StopFlameCone()
    if IsValid(self.FlameCone) then
        self.FlameCone:Remove()
        self.FlameCone = nil
    end
end

function SWEP:OnThink()
    if not self.FlameStartTime then return end
    local now    = CurTime()
    local stillOn= now <= (self.FlameStartTime + 3)

    self.hookID = self:EntIndex()
    self.owner = self:GetOwner()

    if self.isActive then
        if not stillOn then
            self:StopFire()
        else
            if now > self.NextDamageTime then
                self:UpdateFlameCone()
                self.NextDamageTime = now + 0.5
            end
        end
    end

    -- stop loop when *this* NPC dies
    hook.Add("OnNPCKilled", self.hookID .. "_ParentDeath", function(npc, attacker, inflictor)
        if npc ~= self.owner then return end
        self:StopFire()
    end)
end

function SWEP:OnPrimaryAttack(status, statusData)
    local now = CurTime()
    if not self.isActive or now > (self.FlameStartTime + math.random(4,6)) then
        self.FlameStartTime = now
        self.isActive      = true
    end

    if self.isActive then
        -- particle
        if not IsValid(self.Fire_Particle) then
            local att = self:GetAttachment(1)
            local par = ents.Create("info_particle_system")
            par:SetKeyValue("effect_name", "flamethrower_long")
            par:SetKeyValue("start_active", "1")
            par:SetParent(self, 1)
            par:SetPos(att.Pos+att.Ang:Forward()*0+att.Ang:Right()*0+att.Ang:Up()*0)
            par:SetAngles(att.Ang + Angle(3, -3, 0))
            par:Spawn()
            par:Activate()
            self.Fire_Particle = par
        else
            self.Fire_Particle:Fire("Start")
        end

        -- cone
        self:StartFlameCone()

        -- sound
        if not self.Flame_Sound then
            self.Flame_Sound = CreateSound(self, "FLAMETHROWER.FlameLoop")
            self.Flame_Sound:Play()
        else
            self.Flame_Sound:Play()
        end
    end

    self.NPC_NextPrimaryFire = math.random(3, 6)
end

function SWEP:StopFire()
    self.isActive = false

    -- stop particle
    if IsValid(self.Fire_Particle) then
        self.Fire_Particle:Fire("Stop")
    end

    -- stop looping sound
    if self.Flame_Sound and self.Flame_Sound:IsPlaying() then
        self.Flame_Sound:Stop()
    end

    -- remove cone
    self:StopFlameCone()

    -- stop sound
    self:EmitSound("FLAMETHROWER.FlameStop")
end

function SWEP:CustomOnRemove()
    self:StopFlameCone()
    self.isActive = false
    -- stop particle
    if IsValid(self.Fire_Particle) then
        self.Fire_Particle:Fire("Stop")
    end
    -- stop looping sound
    if self.Flame_Sound and self.Flame_Sound:IsPlaying() then
        self.Flame_Sound:Stop()
        self:StopSound("FLAMETHROWER.FlameStop")
    end
end

function SWEP:OnReload(status)

	if status == "Start" then
		self:SetBodygroup(1, 1)	
	end
	if status == "Finish" then
		self:SetBodygroup(1, 0)
	end
end