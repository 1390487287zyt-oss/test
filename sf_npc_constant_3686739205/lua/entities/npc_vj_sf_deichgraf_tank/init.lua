AddCSLuaFile("shared.lua")
include('shared.lua')

---------------------------------------------------------------------------------------------------
-- Оригинальные настройки шасси (без изменений)
---------------------------------------------------------------------------------------------------
ENT.Model = {"models/gflvj/sf/sf_deichgraf_tank_Chassis.mdl"}
ENT.StartHealth = 6700

ENT.VJ_NPC_Class = {"CLASS_SANGVIS"}

ENT.Tank_GunnerENT = "npc_vj_sf_deichgraf_tankg"
ENT.Tank_CollisionBoundSize = 90
ENT.Tank_CollisionBoundUp = 100
ENT.Tank_AngleDiffuseNumber = 0

util.AddNetworkString("vj_sf_deichgraf_tank_spawneffects")
util.AddNetworkString("vj_sf_deichgraf_tank_moveeffects")

function ENT:StartSpawnEffects()
	net.Start("vj_sf_deichgraf_tank_spawneffects")
	net.WriteEntity(self)
	net.Broadcast()
end

function ENT:StartMoveEffects()
	net.Start("vj_sf_deichgraf_tank_moveeffects")
	net.WriteEntity(self)
	net.Broadcast()
end

function ENT:GetNearDeathSparkPositions()
	local randpos = math.random(1,7)
	if randpos == 1 then return self.Spark1:SetLocalPos(self:GetPos() +self:GetForward()*100 +self:GetUp()*60) else
	if randpos == 2 then return self.Spark1:SetLocalPos(self:GetPos() +self:GetForward()*30 +self:GetUp()*60) end
	if randpos == 5 then return self.Spark1:SetLocalPos(self:GetPos() +self:GetForward()*10 +self:GetUp()*60 +self:GetRight()*50) end
	if randpos == 6 then return self.Spark1:SetLocalPos(self:GetPos() +self:GetForward()*80 +self:GetUp()*60 +self:GetRight()*-50) end
	if randpos == 7 then return self.Spark1:SetLocalPos(self:GetPos() +self:GetForward()*-20 +self:GetUp()*60 +self:GetRight()*-30) end
	end
end

---------------------------------------------------------------------------------------------------
-- ДОБАВЛЕНО: Инициализация состояний для щита
---------------------------------------------------------------------------------------------------
function ENT:CustomOnInitialize()
	-- Фазы: true = обычное состояние, false = активирован щит
	self.Phase1 = true
	self.ShieldActive = false
	self.ShieldHealth = 2000
	self.ShieldEntity = nil

	-- === НОВОЕ: 90% сопротивление урону от пуль (DMG_BULLET) ===
	self.BulletResistance = 90
end

---------------------------------------------------------------------------------------------------
-- ДОБАВЛЕНО: Проверка перехода в фазу со щитом и состояние щита
---------------------------------------------------------------------------------------------------
function ENT:CustomOnThink()
	if not self:IsValid() then return end

	-- Активируем щит при здоровье ≤ 1500 (можно изменить)
	if self.Phase1 and self:Health() <= 1500 then
		self.Phase1 = false
		self:SetHealth(1500)
		self:ActivateShield()
	end

	-- Если щит разрушен, отключаем его
	if self.ShieldActive and self.ShieldHealth <= 0 then
		self:DestroyShield()
	end
end

---------------------------------------------------------------------------------------------------
-- ДОБАВЛЕНО: Функция создания щита
---------------------------------------------------------------------------------------------------
function ENT:ActivateShield()
	if self.ShieldActive then return end
	self.ShieldActive = true
	self.ShieldHealth = 2000

	-- Создаём визуальный щит (если энтити доступна)
	self.ShieldEntity = ents.Create("sent_vj_krakenshielddoor")
	if IsValid(self.ShieldEntity) then
		self.ShieldEntity:SetPos(self:GetPos() + Vector(0,0,0))
		self.ShieldEntity:SetModelScale(1.5, 0) -- увеличить в 1.5 раза
		self.ShieldEntity:SetAngles(self:GetAngles())
		self.ShieldEntity:Spawn()
		self.ShieldEntity:Activate()
		self.ShieldEntity:SetParent(self)
		self.ShieldEntity:SetOwner(self)
		self:DeleteOnRemove(self.ShieldEntity)
	end

	-- Звук и частицы активации
	VJ_EmitSound(self, "wotan/Behemothshieldstart1.mp3", 90, 100)
	ParticleEffect("BehemothShieldCreate", self:GetPos() + Vector(0,0,150), Angle(0,0,0), nil)
end

---------------------------------------------------------------------------------------------------
-- ДОБАВЛЕНО: Функция уничтожения щита
---------------------------------------------------------------------------------------------------
function ENT:DestroyShield()
	self.ShieldActive = false
	if IsValid(self.ShieldEntity) then
		self.ShieldEntity:Remove()
	end
	VJ_EmitSound(self, "wotan/Behemothshieldend1.mp3", 90, 100)
	ParticleEffect("BehemothShieldBreak", self:GetPos() + Vector(0,0,150), Angle(0,0,0), nil)
end

---------------------------------------------------------------------------------------------------
-- ИЗМЕНЕНО: Обработка урона с поглощением щитом + игнорирование холодного оружия
---------------------------------------------------------------------------------------------------
function ENT:CustomOnTakeDamage_BeforeDamage(dmginfo, hitgroup)
	-- === НОВОЕ: Игнорируем урон от холодного оружия ===
	-- DMG_SLASH  - режущий урон (ножи, мечи, когти)
	-- DMG_CLUB   - дробящий урон (дубинки, биты, монтировки)
	-- DMG_CRUSH  - раздавливающий урон (кувалды, падающие предметы)
	if dmginfo:IsDamageType(DMG_SLASH) or dmginfo:IsDamageType(DMG_CLUB) or dmginfo:IsDamageType(DMG_CRUSH) then
		dmginfo:ScaleDamage(0) -- полностью отменяем урон
		return -- выходим, дальнейшая обработка не требуется
	end

	-- Далее идёт стандартная логика щита (не затрагивает холодное оружие)
	if self.ShieldActive then
		local dmg = dmginfo:GetDamage()
		-- Разные типы урона по-разному влияют на щит
		if dmginfo:IsDamageType(DMG_BURN) then
			self.ShieldHealth = self.ShieldHealth - dmg * 0.5
		elseif dmginfo:IsDamageType(DMG_SHOCK) then
			self.ShieldHealth = self.ShieldHealth - dmg * 2
		else
			self.ShieldHealth = self.ShieldHealth - dmg
		end

		-- Визуальный эффект попадания в щит
		ParticleEffect("shieldabsorb", dmginfo:GetDamagePosition(), Angle(0,0,0), self)
		dmginfo:ScaleDamage(0) -- весь урон поглощается щитом
	else
		-- Без щита урон проходит как обычно (можно добавить свои модификаторы)
	end
end