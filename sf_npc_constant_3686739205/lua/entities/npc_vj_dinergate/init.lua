AddCSLuaFile("shared.lua")
include('shared.lua')
/*-----------------------------------------------
	*** Copyright (c) 2012-2021 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
-----------------------------------------------*/
ENT.Model = {"models/dinergatesnpc/dinergate.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
ENT.StartHealth = 20
ENT.HullType = HULL_TINY
---------------------------------------------------------------------------------------------------------------------------------------------
ENT.VJ_NPC_Class = {"CLASS_SANGVIS"} -- NPCs with the same class with be allied to each other
ENT.BloodColor = "Oil" -- The blood type, this will determine what it should use (decal, particle, etc.)

ENT.AllowIgnition = false 
ENT.Immune_Sonic = true -- Immune to sonic damage
ENT.Immune_AcidPoisonRadiation = false
ENT.Immune_Dissolve = true 

ENT.HasMeleeAttack = false
ENT.Bleeds = false -- Does the SNPC bleed? (Blood decal, particle, etc.)
ENT.HasBloodParticle = false -- Does it spawn a particle when damaged?
ENT.HasBloodDecal = false -- Does it spawn a decal when damaged?
ENT.HasBloodPool = false 

ENT.HasLeapAttack = true -- Should the SNPC have a leap attack?
ENT.AnimTbl_LeapAttack = {ACT_MELEE_ATTACK1} -- Melee Attack Animations
ENT.LeapAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
ENT.LeapAttackAnimationFaceEnemy = false -- Should it face the enemy while playing the leap attack animation?
ENT.LeapAttackAnimationDecreaseLengthAmount = 0 -- This will decrease the time until starts chasing again. Use it to fix animation pauses until it chases the enemy.
ENT.LeapDistance = 256 -- The distance of the leap, for example if it is set to 500, when the SNPC is 500 Unit away, it will jump
ENT.LeapToMeleeDistance = 0 -- How close does it have to be until it uses melee?
ENT.ConstantlyFaceEnemy = true -- Should it face the enemy constantly?
	-- To use event-based attacks, set this to false:
ENT.TimeUntilLeapAttackDamage = 0.60 -- How much time until it runs the leap damage code?
ENT.NextLeapAttackTime = 1.5 -- How much time until it can use a leap attack?
ENT.NextLeapAttackTime_DoRand = false -- False = Don't use random time | Number = Picks a random number between the regular timer and this timer
ENT.NextAnyAttackTime_Leap = 1.5 -- How much time until it can use any attack again? | Counted in Seconds
ENT.NextAnyAttackTime_Leap_DoRand = false -- False = Don't use random time | Number = Picks a random number between the regular timer and this timer
ENT.LeapAttackReps = 1 -- How many times does it run the leap attack code?
ENT.StopLeapAttackAfterFirstHit = true -- Should it stop the leap attack from running rest of timers when it hits an enemy?
ENT.TimeUntilLeapAttackVelocity = 0.1 -- How much time until it runs the velocity code?
ENT.LeapAttackUseCustomVelocity = false -- Should it disable the default velocity system?
ENT.LeapAttackVelocityForward = 110 -- How much forward force should it apply?
ENT.LeapAttackVelocityUp = 150 -- How much upward force should it apply?
ENT.LeapAttackVelocityRight = 0 -- How much right force should it apply?
ENT.LeapAttackDamage = 10
ENT.LeapAttackDamageDistance = 100 -- How far does the damage go?
ENT.LeapAttackDamageType = DMG_SLASH -- Type of Damage
ENT.DisableLeapAttackAnimation = false

ENT.HasMeleeAttackKnockBack = true -- If true, it will cause a knockback to its enemy
ENT.MeleeAttackKnockBack_Forward1 = 300 -- How far it will push you forward | First in math.random
ENT.MeleeAttackKnockBack_Forward2 = 300 -- How far it will push you forward | Second in math.random
ENT.MeleeAttackKnockBack_Up1 = 20 -- How far it will push you up | First in math.random
ENT.MeleeAttackKnockBack_Up2 = 20 -- How far it will push you up | Second in math.random
ENT.MeleeAttackKnockBack_Right1 = 0 -- How far it will push you right | First in math.random
ENT.MeleeAttackKnockBack_Right2 = 0 

ENT.HasDeathAnimation = true -- Does it play an animation when it dies?
ENT.AnimTbl_Death = {ACT_DIESIMPLE} -- Death Animations
ENT.DeathAnimationChance = 2 -- Put 1 if you want it to play the animation all the time
ENT.PushProps = false -- Should it push props when trying to move?
ENT.AttackProps = false -- Should it attack props when trying to move?
ENT.FootStepTimeRun = 0.3 -- Next foot step sound when it is running
ENT.FootStepTimeWalk = 1 -- Next foot step sound when it is walking
ENT.AnimTbl_IdleStand = {ACT_IDLE}
	-- ====== Flinching Code ====== --
ENT.CanFlinch = 2 -- 0 = Don't flinch | 1 = Flinch at any damage | 2 = Flinch only from certain damages
ENT.FlinchChance = 1 -- Chance of it flinching from 1 to x | 1 will make it always flinch
ENT.AnimTbl_Flinch = {ACT_SMALL_FLINCH} -- If it uses normal based animation, use this

ENT.HasRangeAttack = true -- Should the SNPC have a range attack?
ENT.RangeAttackEntityToSpawn = "grenade_spit" -- The entity that is spawned when range attacking
	-- ====== Animation Variables ====== --
ENT.AnimTbl_RangeAttack = {ACT_RANGE_ATTACK1} -- Range Attack Animations
ENT.RangeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
ENT.RangeAttackAnimationFaceEnemy = true -- Should it face the enemy while playing the range attack animation?
ENT.RangeAttackAnimationDecreaseLengthAmount = 0 -- This will decrease the time until starts chasing again. Use it to fix animation pauses until it chases the enemy.
ENT.RangeAttackAnimationStopMovement = true -- Should it stop moving when performing a range attack?
	-- ====== Distance Variables ====== --
ENT.RangeDistance = 4000 -- This is how far away it can shoot
ENT.RangeToMeleeDistance = 300 -- How close does it have to be until it uses melee?
ENT.RangeAttackAngleRadius = 100 -- What is the attack angle radius? | 100 = In front of the SNPC | 180 = All around the SNPC
ENT.TimeUntilRangeAttackProjectileRelease = 0.5 -- How much time until the projectile code is ran?
ENT.NextRangeAttackTime = 4 -- How much time until it can use a range attack?
ENT.NextRangeAttackTime_DoRand = 6.5 -- False = Don't use random time | Number = Picks a random number between the regular timer and this timer
	-- To let the base automatically detect the attack duration, set this to false:
ENT.NextAnyAttackTime_Range = false -- How much time until it can use any attack again? | Counted in Seconds
ENT.NextAnyAttackTime_Range_DoRand = false -- False = Don't use random time | Number = Picks a random number between the regular timer and this timer
ENT.RangeAttackReps = 1 -- How many times does it run the projectile code?
ENT.RangeAttackExtraTimers = {/* Ex: 1,1.4 */} -- Extra range attack timers | it will run the projectile code after the given amount of seconds
	-- ====== Projectile Spawn Position Variables ====== --
ENT.RangeUseAttachmentForPos = false -- Should the projectile spawn on a attachment?
ENT.RangeUseAttachmentForPosID = "muzzle" -- The attachment used on the range attack if RangeUseAttachmentForPos is set to true
ENT.RangeAttackPos_Up = 20 -- Up/Down spawning position for range attack
ENT.RangeAttackPos_Forward = 0 -- Forward/Backward spawning position for range attack
ENT.RangeAttackPos_Right = 0 -- Right/Left spawning position for range attack
	-- ====== Control Variables ====== --
ENT.DisableRangeAttackAnimation = false -- if true, it will disable the animation code
ENT.DisableDefaultRangeAttackCode = true

	-- ====== Sound File Paths ====== --
-- Leave blank if you don't want any sounds to play
ENT.SoundTbl_FootStep = {""}
ENT.SoundTbl_Idle = {""}
ENT.SoundTbl_Alert = {""}
ENT.SoundTbl_BeforeMeleeAttack = {""}
//ENT.SoundTbl_MeleeAttack = {""}
ENT.SoundTbl_Pain = {""}
ENT.SoundTbl_Death = {""}
ENT.SoundTbl_LeapAttackJump = {"npc/box_monster/box_monster_fs_01.wav","npc/box_monster/box_monster_fs_02.wav","npc/box_monster/box_monster_fs_03.wav","npc/box_monster/box_monster_fs_04.wav","npc/box_monster/box_monster_fs_05.wav","npc/box_monster/box_monster_fs_06.wav","npc/box_monster/box_monster_fs_07.wav"}
ENT.SoundTbl_LeapAttackDamage = {"npc/box_monster/box_monster_leg_kick_01.wav","npc/box_monster/box_monster_leg_kick_02.wav","npc/box_monster/box_monster_leg_kick_03.wav","npc/box_monster/box_monster_leg_kick_04.wav"}

ENT.GeneralSoundPitch1 = 100
ENT.GeneralSoundPitch2 = 100
ENT.IdleSoundPitch1 = 100
ENT.IdleSoundPitch2 = 100
ENT.AlertSoundPitch1 = 100
ENT.AlertSoundPitch2 = 100
ENT.EnemyTalkSoundPitch1 = 100
ENT.EnemyTalkSoundPitch2 = 100
ENT.BeforeMeleeAttackSoundPitch1 = 100
ENT.BeforeMeleeAttackSoundPitch2 = 100
ENT.MeleeAttackSoundPitch1 = 100
ENT.MeleeAttackSoundPitch2 = 100
ENT.ExtraMeleeSoundPitch1 = 100
ENT.ExtraMeleeSoundPitch2 = 100
ENT.MeleeAttackMissSoundPitch1 = 100
ENT.MeleeAttackMissSoundPitch2 = 100
ENT.PainSoundPitch1 = 100
ENT.PainSoundPitch2 = 100
ENT.DeathSoundPitch1 = 100
ENT.DeathSoundPitch2 = 100
ENT.GrenadeSoundPitch1 = 100
ENT.GrenadeSoundPitch2 = 100
ENT.SawPlayerPitch1 = 100
ENT.SawPlayerPitch2 = 100
ENT.StupidPlayerPitch1 = 100
ENT.StupidPlayerPitch2 = 100
ENT.FollowPlayerPitch1 = 100
ENT.FollowPlayerPitch2 = 100
ENT.UnFollowPlayerPitch1 = 100
ENT.UnFollowPlayerPitch2 = 100
ENT.BecomeEnemyToPlayerPitch1 = 100
ENT.BecomeEnemyToPlayerPitch2 = 100
ENT.GrenadeAttackSoundPitch1 = 100
ENT.GrenadeAttackSoundPitch2 = 100
ENT.OnGrenadeSightSoundPitch1 = 100
ENT.OnGrenadeSightSoundPitch2 = 100
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomOnInitialize()
	self:SetCollisionBounds(Vector(7, 7, 15), Vector(-7, -7, 0))
	
	local glow = ents.Create("env_sprite")
	glow:SetKeyValue("model","sprites/glow1.vmt")
	glow:SetKeyValue("scale","0.15")
	glow:SetKeyValue("rendermode","5")
	glow:SetKeyValue("rendercolor","255 25 25")
	--glow:SetKeyValue("spawnflags","1") -- If animated
	glow:AddEFlags(EFL_NO_THINK_FUNCTION)
	glow:SetParent(self)
	glow:SetPos(self:GetPos())
	glow:Spawn()
	glow:Activate()
	glow:Fire("setparentattachment","eye")
	self:DeleteOnRemove(glow)
end
---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:CustomRangeAttackCode()

	local bulletscr = ents.Create("info_target")
	bulletscr:SetPos(self:WorldSpaceCenter() + self:GetUp()*18)
	bulletscr:SetParent(self)
	bulletscr:Activate()
	bulletscr:Spawn()
	bulletscr:Fire("kill","",0)

	if IsValid(bulletscr) then
		local bullet = {}
		bullet.Num = 1
		bullet.Spread = Vector(0,0.06,0)
		bullet.IgnoreEntity = self
		bullet.Tracer = 1
		bullet.TracerName = "ToolTracer"
		bullet.Force = 50
		bullet.Dir = self:GetAimVector()
		bullet.AmmoType = "AR2"
		bullet.Src = bulletscr:GetPos()
		bullet.HullSize = 5
		bullet.Callback = function(attacker, tr, dmginfo)
			dmginfo:SetAttacker(self)
			dmginfo:SetInflictor(self)
			dmginfo:SetDamageType(DMG_ENERGYBEAM)
			if IsValid(tr.Entity) and tr.Entity:GetClass() == self:GetClass() then
				dmginfo:ScaleDamage(0)
			end
		end
		bullet.Damage = self:VJ_GetDifficultyValue(10)

		if SERVER then
			local FireLight1 = ents.Create("light_dynamic")
			FireLight1:SetKeyValue("brightness", "4")
			FireLight1:SetKeyValue("distance", "120")
			FireLight1:SetLocalPos(bulletscr:GetPos())
			FireLight1:SetLocalAngles(self:GetAngles())
			FireLight1:Fire("Color", "60 150 255")
			--FireLight1:SetParent(self)
			FireLight1:Spawn()
			FireLight1:Activate()
			FireLight1:Fire("TurnOn","",0)
			FireLight1:Fire("Kill","",0.07)
			self:DeleteOnRemove(FireLight1)

			sound.Play("weapons/376694_daleonfire_laser.wav",self:GetPos() + Vector(0,0,32),80,math.random(95,105))
			--self:EmitSound("turret/tu_fire1.wav",math.random(75,70),math.random(95,105))	
		end
		bulletscr:FireBullets(bullet)
	end
end

/*-----------------------------------------------
	*** Copyright (c) 2012-2021 by DrVrej, All rights reserved. ***
	No parts of this code or any of its contents may be reproduced, copied, modified or adapted,
	without the prior written consent of the author, unless otherwise indicated for stand-alone materials.
--------------------------------------*/---------