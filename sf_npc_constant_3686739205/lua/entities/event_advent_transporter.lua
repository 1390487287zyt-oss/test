AddCSLuaFile()
ENT.Type                = "anim"
ENT.Base                = "base_anim"
ENT.PrintName           = "Dropship Event Controller"
ENT.Category            = "VJ Base"
ENT.Spawnable           = false

ENT.DropshipModel       = "models/gfl2otherprops/Drone_a_01_tpansport.mdl"
ENT.DropshipSpeed       = 3500
ENT.MinSpeed            = 250
ENT.FadeInTime          = 1
ENT.HoverHeight         = 350
ENT.SpawnHeight         = 6000
ENT.ExcludeAngle        = 60
ENT.DecelDistance       = 2000
ENT.LandingSpot         = nil
ENT.StartHealth         = 200
ENT.VJ_NPC_Class        = {"CLASS_SANGVIS"}

ENT.SoldierClasses      = {
	"npc_vj_dinergate" ,
}

ENT.LingerTime          = 7
ENT.FadeOutTime         = 5
ENT.SmokeSys            = nil
ENT.spawnInterval       = 1

ENT.fixedOffsets = {
	Vector(-10,   120, 0),
	Vector(-10,  -120, 0),
	Vector(-60,   120, 0),
	Vector(-60,  -120, 0),
	Vector(-120,  120, 0),
	Vector(-120, -120, 0),
}

ENT.EngineSound = nil
ENT.EnginePhase = nil
ENT.SoundEngine = "misc/transporter_loop.wav"

---------------------------------------------------------------------------------------------------------------------------------------------
if SERVER then

	function ENT:SpawnSoldier(offset, faceDir, forcedClass)
		local baseXY  = Vector(self.LandingSpot.x + offset.x, self.LandingSpot.y + offset.y, self.LandingSpot.z + offset.z + 50)
		local hullMins = Vector(-20, -20,  0)
		local hullMaxs = Vector( 20,  20, 72)

		local trGround = util.TraceHull({
			start  = baseXY,
			endpos = baseXY - Vector(0, 0, 20000),
			mins   = hullMins,
			maxs   = hullMaxs,
			mask   = MASK_NPCWORLDSTATIC,
			filter = self,
		})

		local groundPos = trGround.Hit and trGround.HitPos + Vector(0, 0, 10) or (baseXY + Vector(0, 0, 5))
		local anchorPos = Vector(baseXY.x, baseXY.y, self:GetPos().z)

		local faceAng = faceDir and faceDir:Angle() or self:GetForward():Angle()
		faceAng.p = 0
		faceAng.r = 0

		local class = forcedClass or self.SoldierClasses[math.random(#self.SoldierClasses)]
		local npc   = ents.Create(class)
		if not IsValid(npc) then return end

		npc:SetPos(anchorPos)
		npc:SetAngles(faceAng)
		npc:Spawn()
		npc:Activate()

		npc:SetMoveType(MOVETYPE_NONE)
		npc:SetSolid(SOLID_BBOX)
		npc:SetCollisionGroup(COLLISION_GROUP_NPC)
		npc:DrawShadow(false)
		npc:SetNPCState(NPC_STATE_SCRIPT)
		npc:SetEnemy(nil)

		local phys0 = npc:GetPhysicsObject()
		if IsValid(phys0) then phys0:EnableMotion(false) end

		local _, animDuration = npc:PlayAnim({"ACT_JUMP"}, true, false, false, 0)
		local startTime       = CurTime()
		local hookName        = "RappelMove_" .. npc:EntIndex()

		hook.Add("Think", hookName, function()
			if not IsValid(npc) then
				hook.Remove("Think", hookName)
				return
			end

			local t = math.Clamp((CurTime() - startTime) / animDuration, 0, 1)
			npc:SetPos(LerpVector(t, anchorPos, groundPos))
			npc:SetEnemy(nil)

			if t >= 1 then
				hook.Remove("Think", hookName)

				local phys = npc:GetPhysicsObject()
				if IsValid(phys) then
					phys:EnableMotion(true)
					phys:EnableGravity(true)
				end

				npc:SetMoveType(MOVETYPE_STEP)
				npc:SetSolid(SOLID_BBOX)
				npc:DrawShadow(true)

				timer.Simple(0.467, function()
					if not IsValid(npc) then return end
					npc:SetNPCState(NPC_STATE_ALERT)
					npc:SetState(VJ_STATE_NONE)
				end)
			end
		end)
	end

	function ENT:Initialize()
		self:SetModel(self.DropshipModel)
		self:DrawShadow(false)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		self.LastPos      = self:GetPos()
		self.RealVelocity = vector_origin

		self.WingBones = {
			self:LookupBone("rfwing"),
			self:LookupBone("lfwing"),
			self:LookupBone("rbwing"),
			self:LookupBone("lbwing"),
		}

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then phys:EnableMotion(false) end

		self:SetHealth(self.StartHealth)
		self:SetMaxHealth(self.StartHealth)
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:SetColor(Color(255, 255, 255, 0))

		self.Origin      = self:GetPos()
		if not self.LandingSpot then self.LandingSpot = self.Origin end

		local mapcenter = navmesh.GetNavAreaCount() > 0 and navmesh.GetAllNavAreas()[1]:GetCenter() or self.Origin
		local edgeDir   = (mapcenter - self.Origin):GetNormalized() * -1
		local edgePos3  = self.Origin + edgeDir * self.SpawnHeight
		local raw2D     = Vector(self.Origin.x, self.Origin.y, 0)

		if self.Origin:DistToSqr(edgePos3) <= (self.SpawnHeight ^ 2) then
			raw2D = Vector(edgePos3.x, edgePos3.y, 0)
		end

		local land2D     = Vector(self.LandingSpot.x, self.LandingSpot.y, 0)
		local toLanding2 = raw2D - land2D
		local minHoriz   = math.tan(math.rad(self.ExcludeAngle)) * self.SpawnHeight

		if toLanding2:Length() < minHoriz then
			toLanding2:Normalize()
			raw2D = land2D + toLanding2 * minHoriz
		end

		self.SpawnPos = Vector(raw2D.x, raw2D.y, self.SpawnHeight)
		self:SetPos(self.SpawnPos)

		local dir = (self.LandingSpot - self.SpawnPos)
		dir.z = 0
		if dir:Length() > 0 then
			self:SetAngles(Angle(0, dir:Angle().y, 0))
		end

		local dirToLand = (self.LandingSpot - self.SpawnPos):GetNormalized()
		self:SetAngles(Angle(0, dirToLand:Angle().y, 0))

		local p2      = self.LandingSpot + Vector(0, 0, self.HoverHeight)
		local mid     = (self.SpawnPos + p2) * 0.5
		local sideDir = Vector(math.random(-1, 1), math.random(-1, 1), 0)
		if sideDir:Length() == 0 then sideDir = Vector(1, 0, 0) end
		sideDir:Normalize()
		local sideOff  = sideDir * math.Rand(300, 600) + Vector(0, 0, math.Rand(200, 500))
		self.IngCtrl   = mid + sideOff

		self:ComputeBezierPath(self.SpawnPos, self.IngCtrl, p2, "Ingress")
		self.PathIndex        = 1
		self.PitchVelocity    = 0
		self.HoverAnimStarted = false
		self.StartTime        = CurTime()
		self.State            = "fading_in"

		sound.Play(self.SoundEngine, self:GetPos(), 120, math.random(85, 115), 1, CHAN_AUTO)
		self.EnginePhase = "approach"
		self:StartThrusters()
	end

	function ENT:UpdateWingTilt()
		if self.State == "destroyed" then
			for bone, ang in pairs(self.WingDestroyedAngles or {}) do
				if bone then self:ManipulateBoneAngles(bone, ang) end
			end
			return
		end

		local ct  = CurTime()
		local dt  = FrameTime()
		local maxYaw    = 45
		local targetYaw = 0

		if self.State == "moving_in" then
			local d              = self:GetPos():Distance(self.LandingSpot or self:GetPos())
			local transitionDist = self.DropshipSpeed * 2
			if d < transitionDist then
				local frac = 1 - math.Clamp(d / transitionDist, 0, 1)
				targetYaw = Lerp(frac, maxYaw, -maxYaw)
			else
				targetYaw = maxYaw
			end
		elseif self.State == "departing" then
			targetYaw = -maxYaw
		end

		self.CurrentWingYaw = Lerp(dt * 4, self.CurrentWingYaw or 0, targetYaw)

		for i, bone in ipairs(self.WingBones) do
			if not bone then continue end

			local offset = 0
			if self.State == "hovering" then
				local amp  = 15
				local freq = 3
				local phases = {0, math.pi * 0.5, math.pi, math.pi * 1.5}
				local mults  = {1, 1, 0.7, 0.7}
				offset = math.sin(ct * freq + phases[i]) * amp * mults[i]
			end

			self:ManipulateBoneAngles(bone, Angle(0, self.CurrentWingYaw + offset, 0))
		end
	end

	function ENT:ComputeBezierPath(p0, p1, p2, key)
		local name     = key .. "PathPoints"
		local hullMins = Vector(-200, -200, -50)
		local hullMaxs = Vector( 200,  200,  200)

		local function sampleBezier(cp)
			local pts   = {}
			local dist  = p0:Distance(p2)
			local steps = math.max(10, math.ceil(dist / 200))
			for i = 0, steps do
				local t = i / steps
				local u = 1 - t
				pts[#pts + 1] = p0 * (u * u) + cp * (2 * u * t) + p2 * (t * t)
			end
			return pts
		end

		local function isBlocked(pts)
			for i = 1, #pts - 1 do
				local tr = util.TraceHull({
					start  = pts[i],
					endpos = pts[i + 1],
					mins   = hullMins,
					maxs   = hullMaxs,
					mask   = MASK_NPCWORLDSTATIC,
				})
				if tr.Hit and not tr.HitSky then return true end
			end
			return false
		end

		local candidates = {p1}
		local mid    = (p0 + p2) * 0.5
		local apexZ  = math.max(p0.z, p1.z, p2.z) + 200
		for ang = 0, 315, 45 do
			local dir = Angle(0, ang, 0):Forward()
			local cp  = mid + dir * 300
			cp.z      = apexZ
			candidates[#candidates + 1] = cp
		end

		local bestPath
		for _, cp in ipairs(candidates) do
			local pts = sampleBezier(cp)
			if not isBlocked(pts) then
				bestPath = pts
				break
			end
		end

		if not bestPath then bestPath = sampleBezier(p1) end

		local straightDir = (p2 - p0):GetNormalized()
		local stepSize    = p0:Distance(p2) / math.max(1, math.ceil(p0:Distance(p2) / 200))
		if #bestPath >= 2 then bestPath[2] = p0 + straightDir * stepSize end

		self[name] = bestPath
	end

	function ENT:OnLanded()
		if IsValid(self.RedLight) then self.RedLight:Remove() end

		local light = ents.Create("env_projectedtexture")
		if IsValid(light) then
			light:SetParent(self)
			light:SetLocalPos(Vector(0, 0, -10))
			light:SetLocalAngles(Angle(90, 0, 0))
			light:SetKeyValue("enableshadows", 0)
			light:SetKeyValue("farz", 600)
			light:SetKeyValue("nearz", 10)
			light:SetKeyValue("lightfov", 130)
			light:SetKeyValue("lightcolor", "220 0 0 255")
			light:Spawn()
			light:Input("SpotlightTexture", NULL, NULL, "effects/flashlight001")
			light:Input("TurnOn")
			self.RedLight = light
		end

		self.State = "hovering"
		self:SetCycle(0)
		self:SetPlaybackRate(1)

		if self.EnginePhase == "decelerating" then
			sound.Play(self.SoundEngine, self:GetPos(), 100, math.random(85, 115), 1, CHAN_AUTO)
			self.EnginePhase = "hovering"
		end

		local mecClass  = "npc_vj_e_advent_mec"
		local mecUsed   = false
		local numSpawns = math.random(2, 4)
		local available = table.Copy(self.fixedOffsets)
		local chosenOffsets = {}
		local chosenClasses = {}

		for i = 1, numSpawns do
			local relOff
			if #available > 0 then
				local ridx = math.random(#available)
				relOff = available[ridx]
				table.remove(available, ridx)
			else
				relOff = self.fixedOffsets[math.random(#self.fixedOffsets)]
			end
			chosenOffsets[#chosenOffsets + 1] = relOff

			local classPool = {}
			for _, cls in ipairs(self.SoldierClasses) do
				if cls ~= mecClass or not mecUsed then
					classPool[#classPool + 1] = cls
				end
			end

			local chosen = classPool[math.random(#classPool)]
			if chosen == mecClass then mecUsed = true end
			chosenClasses[#chosenClasses + 1] = chosen
		end

		for idx, relOff in ipairs(chosenOffsets) do
			timer.Simple(self.spawnInterval * (idx - 1), function()
				if not IsValid(self) or self.Destroyed then return end

				local fwd      = self:GetForward()
				local right    = self:GetRight()
				local up       = self:GetUp()
				local worldOff = fwd * relOff.x + right * relOff.y + up * relOff.z
				local faceDir  = relOff.y > 0 and right or -right

				self:SpawnSoldier(worldOff, faceDir, chosenClasses[idx])
			end)
		end

		timer.Simple(self.LingerTime, function()
			if IsValid(self) then self:BeginDeparture() end
		end)
	end

	function ENT:BeginDeparture()
		if IsValid(self.RedLight) then self.RedLight:Remove() end
		if self.State ~= "hovering" then return end

		self.State = "departing"

		if self.EnginePhase == "hovering" then
			sound.Play(self.SoundEngine, self:GetPos(), 100, math.random(85, 115), 1, CHAN_AUTO)
			self.EnginePhase = "departing"
		end

		self:SetCycle(0)
		self:SetPlaybackRate(1)

		local start    = self:GetPos()
		local center   = navmesh.GetNavAreaCount() > 0 and navmesh.GetAllNavAreas()[1]:GetCenter() or self.Origin
		local edgeDir  = (center - self.LandingSpot):GetNormalized() * -1
		local edge     = self.LandingSpot + edgeDir * self.SpawnHeight
		local goal     = edge + Vector(0, 0, self.SpawnHeight)
		local mid      = (start + goal) * 0.5
		local sd       = Vector(math.random(-1, 1), math.random(-1, 1), 0)
		if sd:Length() == 0 then sd = Vector(1, 0, 0) end
		sd:Normalize()
		local off = sd * math.Rand(300, 600) + Vector(0, 0, math.Rand(200, 500))

		self:ComputeBezierPath(start, mid + off, goal, "Depart")
		self.PathIndex = 1

		timer.Simple(5, function()
			if not IsValid(self) then return end
			self:StopSound(self.SoundEngine)
			SafeRemoveEntity(self)
		end)
	end

	function ENT:Think()
		if self.Destroyed then
			self:NextThink(CurTime())
			return true
		end

		if not IsValid(self) then return end

		local ct = CurTime()
		local dt = FrameTime()

		if self.State == "fading_in" then
			local t = math.min((ct - self.StartTime) / self.FadeInTime, 1)
			self:SetColor(Color(255, 255, 255, t * 255))
			if t >= 1 then self.State = "moving_in" end

		elseif self.State == "moving_in" then
			local d = self:GetPos():Distance(self.LandingSpot)
			if d < self.DecelDistance and not self.HoverAnimStarted then
				self:SetCycle(0)
				self:SetPlaybackRate(1)
				self.HoverAnimStarted = true

				if self.EnginePhase == "approach" then
					sound.Play(self.SoundEngine, self:GetPos(), 115, math.random(85, 115), 1, CHAN_AUTO)
					self.EnginePhase = "decelerating"
				end
			end
			self:FollowPath(dt, self.IngressPathPoints)

		elseif self.State == "hovering" then
			local ang   = self:GetAngles()
			local pitch = math.sin(ct * 2.5) * 1.5
			local roll  = math.cos(ct * 2.2) * 2
			local err   = 0 - ang.p
			local K, C  = 8, 2
			self:SetAngles(Angle(pitch, ang.y, roll))
			self.PitchVelocity = (self.PitchVelocity + K * err * dt) / (1 + C * dt)

		elseif self.State == "departing" then
			self:FollowPath(dt, self.DepartPathPoints, true)

		elseif self.State == "fading_out" then
			local elapsed = ct - (self.FadeOutStart or ct)
			local t       = math.min(elapsed / self.FadeOutTime, 1)
			self:SetColor(Color(255, 255, 255, math.floor(255 * (1 - t))))
			self:StopSound(self.SoundEngine)
			if t >= 1 then
				SafeRemoveEntity(self)
				return
			end
		end

		local currentPos      = self:GetPos()
		self.RealVelocity     = (currentPos - self.LastPos) / math.max(FrameTime(), 0.001)
		self.LastPos          = currentPos
		self:UpdateWingTilt()
		self:FrameAdvance(dt)
		self:NextThink(ct)
		return true
	end

	function ENT:FollowPath(dt, path, fade)
		local idx = self.PathIndex
		local tgt = path[idx]

		if not tgt then
			if fade then self:Remove() else self:OnLanded() end
			return
		end

		local dir   = tgt - self:GetPos()
		local dist  = dir:Length()
		local dL    = self:GetPos():Distance(self.LandingSpot)
		local speed = self.DropshipSpeed

		if dL < self.DecelDistance then
			speed = Lerp(dL / self.DecelDistance, self.MinSpeed, self.DropshipSpeed)
		end

		if dist < 10 or dist <= speed * dt then
			self.PathIndex = idx + 1
		else
			self:SetPos(self:GetPos() + dir:GetNormalized() * speed * dt)

			local ang    = self:GetAngles()
			local tgtAng = dir:Angle()
			tgtAng.y     = tgtAng.y - 90
			local y      = Lerp(dt * 1.5, ang.y, tgtAng.y)
			local err    = 0 - ang.p
			local K, C   = 8, 2
			self.PitchVelocity = (self.PitchVelocity + K * err * dt) / (1 + C * dt)
			self:SetAngles(Angle(ang.p + self.PitchVelocity * dt, y, 0))
		end
	end

	function ENT:StartThrusters()
		if self.Destroyed then return end

		self.ActiveThrusters = {}

		for _, attName in ipairs({"thruster_rf", "thruster_lf", "thruster_rb", "thruster_lb"}) do
			local attID = self:LookupAttachment(attName)
			if attID and attID > 0 then
				ParticleEffectAttach("advent_transporter_thruster", PATTACH_POINT_FOLLOW, self, attID)
			end
		end
	end

	function ENT:OnTakeDamage(dmginfo)
		if self.Destroyed then return end
		if dmginfo:GetDamageType() == DMG_BLAST then
			self:SetHealth(self:Health() - dmginfo:GetDamage())
			if self:Health() <= 0 then self:HandleDestruction() end
		end
	end

	function ENT:HandleDestruction()
		if self.Destroyed then return end
		self.Destroyed = true
		self.State     = "destroyed"

		self:StopThrusters()
		self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		self:AddFlags(FL_NOTARGET)

		if IsValid(self.RedLight) then self.RedLight:Remove() end
		self:StopSound(self.SoundEngine)

		local pos = self:GetPos()
		local ang = self:GetAngles()
		local vel = self.RealVelocity or vector_origin

		self:SetMoveType(MOVETYPE_NONE)
		self:PhysicsDestroy()
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetPos(pos)
		self:SetAngles(ang)

		local phys = self:GetPhysicsObject()
		if IsValid(phys) then
			phys:Wake()
			phys:EnableMotion(true)
			phys:EnableGravity(true)
			phys:SetVelocity(vel)
			phys:AddAngleVelocity(Vector(
				math.random(-90,  90),
				math.random(-90,  90),
				math.random(-180, 180)
			))
		end

		ParticleEffect("transp_d_air", pos, ang, nil)

		local function pickExplosionSound()
			local closestDist = math.huge
			for _, ply in ipairs(player.GetAll()) do
				local d = pos:Distance(ply:GetPos())
				if d < closestDist then closestDist = d end
			end
			if closestDist <= 2000 then
				return math.random(1, 2) == 1 and "Transp_exp_close_1" or "Transp_exp_close_2"
			else
				return math.random(1, 2) == 1 and "Transp_exp_far_1" or "Transp_exp_far_2"
			end
		end

		self:EmitSound(pickExplosionSound(), 140, 100)
		self:SetSubMaterial(0, "models/minic23/xcom2/advent/advent_transporter_destroyed")
		self:SetSubMaterial(1, "models/minic23/xcom2/advent/advent_transporter_window_destroyed")
		self:Ignite(math.random(30, 50), 0)

		timer.Simple(math.random(9, 15), function()
			if not IsValid(self) then return end

			local dmgInfo = DamageInfo()
			dmgInfo:SetAttacker(game.GetWorld())
			dmgInfo:SetInflictor(game.GetWorld())
			dmgInfo:SetDamage(200)
			dmgInfo:SetDamageType(DMG_BLAST + DMG_BURN)
			util.BlastDamageInfo(dmgInfo, self:GetPos(), 1000)

			ParticleEffect("transp_d_ground", self:GetPos(), Angle(0, 0, 0), nil)
			self:EmitSound(pickExplosionSound(), 140, 100)

			local debrisModels = {
				"models/gibs/helicopter_brokenpiece_03.mdl",
				"models/gibs/helicopter_brokenpiece_01.mdl",
				"models/gibs/helicopter_brokenpiece_02.mdl",
				"models/container_chunk03.mdl",
				"models/combine_apc_destroyed_gib02.mdl",
				"models/combine_apc_destroyed_gib04.mdl",
				"models/combine_apc_destroyed_gib05.mdl",
			}

			for i = 1, math.random(8, 12) do
				local mdl = debrisModels[i]
				if not mdl then break end

				local prop = ents.Create("prop_physics")
				if not IsValid(prop) then continue end

				prop:SetModel(mdl)
				prop:SetPos(self:GetPos() + VectorRand() * 50)
				prop:SetAngles(AngleRand())
				prop:Spawn()
				prop:SetSubMaterial(0, "models/minic23/xcom2/advent/advent_transporter_destroyed")

				local physObj = prop:GetPhysicsObject()
				if IsValid(physObj) then
					physObj:SetMass(physObj:GetMass() * 3)
					physObj:SetVelocity(VectorRand() * math.random(500, 1500) + Vector(0, 0, 300))
					physObj:AddAngleVelocity(VectorRand() * math.random(100, 300))
				end

				prop:Ignite(math.random(30, 50), 0)
				prop:SetRenderMode(RENDERMODE_TRANSALPHA)
				prop:SetColor(Color(255, 255, 255, 255))

				timer.Create("DebrisFade_" .. prop:EntIndex(), 120, 1, function()
					if not IsValid(prop) then return end
					local fadeStart = CurTime()
					local fadeTime  = 3
					local hookKey   = "DebrisFadeThink_" .. prop:EntIndex()
					hook.Add("Think", hookKey, function()
						if not IsValid(prop) then
							hook.Remove("Think", hookKey)
							return
						end
						local t = (CurTime() - fadeStart) / fadeTime
						if t >= 1 then
							prop:Remove()
							hook.Remove("Think", hookKey)
							return
						end
						prop:SetColor(Color(255, 255, 255, math.floor(255 * (1 - t))))
					end)
				end)
			end

			self:Remove()
		end)
	end

end

---------------------------------------------------------------------------------------------------------------------------------------------
function ENT:StopThrusters()
	self:StopParticles()
	self.ActiveThrusters = nil
end

function ENT:OnRemove()
	self:StopSound(self.SoundEngine)
end