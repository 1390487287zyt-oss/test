AddCSLuaFile("shared.lua")
include('shared.lua')

ENT.Model = {"models/yo_ponika/sf_mdl/sf_vespid.mdl"} -- The game will pick a random model from the table when the SNPC is spawned | Add as many as you want
ENT.StartHealth = 500
ENT.HullType = HULL_HUMAN
---------------------------------------------------------------------------------------------------------------------------------------------
ENT.VJ_NPC_Class = {"CLASS_SANGVIS"} 

ENT.BloodColor = "Black" 
ENT.SightDistance = 8000 -- How far it can see
ENT.HasMeleeAttack = true

ENT.ShootDistance = 2750
ENT.MeleeAttackDamage = 32
ENT.SquadName = "vj_vespid" -- Squad name, console error will happen if two groups that are enemy and try to squad!
ENT.FootStepTimeRun = 0.4 -- Next foot step sound when it is running
ENT.FootStepTimeWalk = 0.5 -- Next foot step sound when it is walking
ENT.HasGrenadeAttack = false -- Should the SNPC have a grenade attack
ENT.CallForHelp = true -- Does the SNPC call for help
ENT.CallForHelpDistance = 600 -- -- How far away the SNPC's call for help goes | Counted in World Units
ENT.HasCallForHelpAnimation = true -- if true, it will play the call for help animation
ENT.AnimTbl_CallForHelp = {ACT_SIGNAL_ADVANCE,ACT_SIGNAL_FORWARD,ACT_SIGNAL_GROUP} -- Call For Help Animations
ENT.NextCallForHelpTime = 10 -- Time until it calls for help again
ENT.WaitForEnemyToComeOutTime1 = 2 -- How much time should it wait until it starts chasing the enemy | First number in math.random
ENT.WaitForEnemyToComeOutTime2 = 3 -- How much time should it wait until it starts chasing the enemy | Second number in math.random
ENT.AnimTbl_Flinch = {ACT_FLINCH_PHYSICS} -- If it uses normal based animation, use this
ENT.OnlyDoKillFriendlyWhenClear = true
ENT.HasOnKilledFriendlySound = true
ENT.wep = "weapon_vj_magnrifle"

--21397 pnv

ENT.SoundTbl_FootStep = {"npc/fear_soldier/gear1.wav","npc/fear_soldier/gear2.wav","npc/fear_soldier/gear3.wav","npc/fear_soldier/gear4.wav","npc/fear_soldier/gear5.wav","npc/fear_soldier/gear6.wav","npc/fear_soldier/gear7.wav","npc/fear_soldier/gear8.wav","npc/fear_soldier/gear9.wav","npc/fear_soldier/gear10.wav"}
ENT.FootStepPitch1 = 100
ENT.FootStepPitch2 = 100
ENT.FootStepSoundLevel = 55
ENT.AllyDeathSoundChance = 1

ENT.HasGrenadeAttack = true -- Should the SNPC have a grenade attack
ENT.GrenadeAttackEntity = "obj_vj_adv_he_grenade" -- The entity that the SNPC throws | Half Life 2 Grenade: "npc_grenade_frag"
ENT.GrenadeAttackModel = "models/advent/advent_frag_grenade.mdl" -- The model for the grenade entity
ENT.AnimTbl_GrenadeAttack = {"grenThrow"} -- Grenade Attack Animations
ENT.GrenadeAttackAnimationDelay = 0 -- It will wait certain amount of time before playing the animation
ENT.GrenadeAttackAnimationFaceEnemy = true -- Should it face the enemy while playing the grenade attack animation
ENT.NextThrowGrenadeTime1 = 8 -- Time until it runs the throw grenade code again | The first # in math.random
ENT.NextThrowGrenadeTime2 = 14 -- Time until it runs the throw grenade code again | The second # in math.random
ENT.ThrowGrenadeChance = 2 -- Chance that it will throw the grenade | Set to 1 to throw all the time
ENT.GrenadeAttackThrowDistance = 890 -- How far it can throw grenades
ENT.GrenadeAttackThrowDistanceClose = 400 -- How close until it stops throwing grenades
ENT.IdleSoundChance = 2
ENT.AllyDeathSoundChance = 1
ENT.SuppressingSoundChance = 1
ENT.NextSoundTime_Idle1 = 10
ENT.NextSoundTime_Idle2 = 15




--------------------------------------------------------------------------------------------------------------------------------------------
 function ENT:CustomOnInitialize()
self.SquadSound = false	
if math.random(1,2) == 1  then self.DisableWandering = true end
if math.random(1,5) == 1 then self.IsMedicSNPC = true end
self:SetCollisionBounds(Vector(13, 13, 72), -Vector(13, 13, 2))
self:SetSkin(14)
self:SetBodygroup(7,1)
self:SetBodygroup(11,1)
self:SetBodygroup(12,1)
						local lamp2 = ents.Create("env_sprite")
					lamp2:SetKeyValue("model","vj_base/sprites/vj_glow1.vmt")
					lamp2:SetKeyValue("scale","0.011")
					lamp2:SetKeyValue("rendermode","5")
					lamp2:SetKeyValue("rendercolor","255 150 0")
					lamp2:SetKeyValue("spawnflags","1") -- If animated
					lamp2:SetParent(self)
					lamp2:Fire("SetParentAttachment","eyes3",0)
					lamp2:Spawn()
					lamp2:Activate()

				self:DeleteOnRemove(lamp2)
						local lamp3 = ents.Create("env_sprite")
					lamp3:SetKeyValue("model","vj_base/sprites/vj_glow1.vmt")
					lamp3:SetKeyValue("scale","0.031")
					lamp3:SetKeyValue("rendermode","5")
					lamp3:SetKeyValue("rendercolor","50 25 0")
					lamp3:SetKeyValue("spawnflags","1") -- If animated
					lamp3:SetParent(self)
					lamp3:Fire("SetParentAttachment","eyes1",0)
					lamp3:Spawn()
					lamp3:Activate()

					self:DeleteOnRemove(lamp3)	
						local lamp = ents.Create("env_sprite")
					lamp:SetKeyValue("model","vj_base/sprites/vj_glow1.vmt")
					lamp:SetKeyValue("scale","0.051")
					lamp:SetKeyValue("rendermode","5")
					lamp:SetKeyValue("rendercolor","15 7 0")
					lamp:SetKeyValue("spawnflags","1") -- If animated
					lamp:SetParent(self)
					lamp:Fire("SetParentAttachment","eyes1",0)
					lamp:Spawn()
					lamp:Activate()

					self:DeleteOnRemove(lamp)
					
					
						local lamp4 = ents.Create("env_sprite")
					lamp4:SetKeyValue("model","vj_base/sprites/vj_glow1.vmt")
					lamp4:SetKeyValue("scale","0.011")
					lamp4:SetKeyValue("rendermode","5")
					lamp4:SetKeyValue("rendercolor","255 150 0")
					lamp4:SetKeyValue("spawnflags","1") -- If animated
					lamp4:SetParent(self)
					lamp4:Fire("SetParentAttachment","eyes2",0)
					lamp4:Spawn()
					lamp4:Activate()

				self:DeleteOnRemove(lamp4)
						local lamp5 = ents.Create("env_sprite")
					lamp5:SetKeyValue("model","vj_base/sprites/vj_glow1.vmt")
					lamp5:SetKeyValue("scale","0.031")
					lamp5:SetKeyValue("rendermode","5")
					lamp5:SetKeyValue("rendercolor","50 25 0")
					lamp5:SetKeyValue("spawnflags","1") -- If animated
					lamp5:SetParent(self)
					lamp5:Fire("SetParentAttachment","eyes4",0)
					lamp5:Spawn()
					lamp5:Activate()

					self:DeleteOnRemove(lamp5)	
						local lamp6 = ents.Create("env_sprite")
					lamp6:SetKeyValue("model","vj_base/sprites/vj_glow1.vmt")
					lamp6:SetKeyValue("scale","0.051")
					lamp6:SetKeyValue("rendermode","5")
					lamp6:SetKeyValue("rendercolor","15 7 0")
					lamp6:SetKeyValue("spawnflags","1") -- If animated
					lamp6:SetParent(self)
					lamp6:Fire("SetParentAttachment","eyes4",0)
					lamp6:Spawn()
					lamp6:Activate()

					self:DeleteOnRemove(lamp6)		
end
 ENT.NextSoundTime_Idle = VJ.SET(10, 15)
ENT.IdleSoundPitch = VJ.SET(100, 100)
ENT.IdleDialogueSoundPitch = VJ.SET(100, 100) -- Controls "self.SoundTbl_IdleDialogue", "self.SoundTbl_IdleDialogueAnswer"
ENT.CombatIdleSoundPitch = VJ.SET(100, 100)
ENT.ReceiveOrderSoundPitch = VJ.SET(100, 100)
ENT.FollowPlayerPitch = VJ.SET(100, 100) -- Controls "self.SoundTbl_FollowPlayer", "self.SoundTbl_UnFollowPlayer"
ENT.YieldToPlayerSoundPitch = VJ.SET(100, 100)
ENT.MedicBeforeHealSoundPitch = VJ.SET(100, 100)
ENT.MedicOnHealSoundPitch = VJ.SET(100, 100)
ENT.MedicReceiveHealSoundPitch = VJ.SET(100, 100)
ENT.OnPlayerSightSoundPitch = VJ.SET(100, 100)
ENT.InvestigateSoundPitch = VJ.SET(100, 100)
ENT.LostEnemySoundPitch = VJ.SET(100, 100)
ENT.AlertSoundPitch = VJ.SET(100, 100)
ENT.CallForHelpSoundPitch = VJ.SET(100, 100)
ENT.BecomeEnemyToPlayerPitch = VJ.SET(100, 100)
ENT.BeforeMeleeAttackSoundPitch = VJ.SET(100, 100)
ENT.MeleeAttackSoundPitch = VJ.SET(100, 100)
ENT.ExtraMeleeSoundPitch = VJ.SET(100, 100)
ENT.MeleeAttackMissSoundPitch = VJ.SET(100, 100)
ENT.SuppressingPitch = VJ.SET(100, 100)
ENT.WeaponReloadSoundPitch = VJ.SET(100, 100)
ENT.GrenadeAttackSoundPitch = VJ.SET(100, 100)
ENT.DangerSightSoundPitch = VJ.SET(100, 100) -- Controls "self.SoundTbl_DangerSight", "self.SoundTbl_GrenadeSight"
ENT.KilledEnemySoundPitch = VJ.SET(100, 100)
ENT.AllyDeathSoundPitch = VJ.SET(100, 100)
ENT.PainSoundPitch = VJ.SET(100, 100)
ENT.ImpactSoundPitch = VJ.SET(100, 100)
ENT.DamageByPlayerPitch = VJ.SET(100, 100)
ENT.DeathSoundPitch = VJ.SET(100, 100)