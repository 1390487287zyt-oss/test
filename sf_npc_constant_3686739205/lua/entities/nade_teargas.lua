AddCSLuaFile()

ENT.Type        = "anim"
ENT.Base        = "base_anim"
ENT.PrintName   = "NeuroToxinNade"
ENT.Author      = "Rycch"
ENT.Purpose     = "Can you feel Air Exchange?"
ENT.Category    = "Rycch's Combine"

ENT.Spawnable    = true
ENT.AdminOnly    = true

ENT.OwnerClass = ""
ENT.OwnerTeam = {}

-- SERVER ONLY
if SERVER then
    util.AddNetworkString("NeuroGas_Ping") -- not strictly needed here, but good practice if you switch to net msgs

    function ENT:Initialize()
        self:SetModel("models/weapons/w_grenade.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:DrawShadow(false)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
        self:SetColor(Color(25, 100, 0, 255))

        self.OwnerClass = self:GetOwner():GetClass()

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
            phys:SetMaterial("metal")
        end

        -- clear the screen‐effect flag on everyone
        for _, ply in ipairs(player.GetAll()) do
            ply:SetNWBool("InNeuroGas", false)
        end

        self:NextThink(CurTime())
    end

    -- Simple LOS check
    local function IsVisible(srcEnt, tgtEnt)
        if not (IsValid(srcEnt) and IsValid(tgtEnt)) then return false end
    
        -- get their positions as vectors
        local startPos = srcEnt:GetPos() + Vector(0, 0, 10)
        local endPos   = tgtEnt:GetPos() + Vector(0, 0, 50)
    
        local tr = util.TraceLine({
            start   = startPos,
            endpos  = endPos,
            filter  = { srcEnt, tgtEnt },
            mask    = MASK_SOLID_BRUSHONLY
        })
    
        return not tr.Hit
    end
    

    function ENT:Think()
        if self.TimerExplode == 1 then
            local ct = CurTime()

            if ct >= (self.NextDamageTime or 0) then
                -- Damage NPCs
                for _, npc in ipairs(ents.GetAll()) do
                    if npc:IsNPC() and npc:GetClass() != self.OwnerClass then
                        local d = npc:GetPos():Distance(self:GetPos())
                        if d < 170 and IsVisible(self, npc) then
                            npc:TakeDamage(1, self, DMG_NERVEGAS)
                        end
                    end
                end

                -- Damage players & set NWBool
                for _, ply in ipairs(player.GetAll()) do
                    local d = ply:GetPos():Distance(self:GetPos())
                    local inGas = ply:Alive()
                       and d < 200
                       and IsVisible(self, ply)
                       and not ply.wearsuit
                       and not ply.GASMASK_Equiped

                    if inGas then
                        ply:TakeDamage(2, self, DMG_NERVEGAS)
                    end

                    ply:SetNWBool("InNeuroGas", inGas)
                end

                self.NextDamageTime = ct + 0.7
            end

            if not self.Sound then
                self.Sound = true
                self:EmitSound("ambient/gas/steam2.wav")

                local smoke = ents.Create("env_smoketrail")
                smoke:SetKeyValue("startsize",  "40000")
                smoke:SetKeyValue("endsize",    "100")
                smoke:SetKeyValue("spawnradius", "100")
                smoke:SetKeyValue("minspeed",   "1")
                smoke:SetKeyValue("maxspeed",   "2")
                smoke:SetKeyValue("startcolor", "255 255 255")
                smoke:SetKeyValue("endcolor",   "33 110 240")
                smoke:SetKeyValue("opacity",    "0.8")
                smoke:SetKeyValue("spawnrate",  "20")
                smoke:SetKeyValue("lifetime",   "5")
                smoke:SetPos(self:GetPos())
                smoke:SetParent(self)
                smoke:Spawn()
                smoke:Fire("kill", "", 20)

                self:Fire("kill", "", 20)
            end
        end

        self:NextThink(CurTime())
        return true
    end

    function ENT:PhysicsCollide(data, phys)
        self.ExplodeScheduledTime = CurTime() + 0.1
        if data.Speed > 50 then
            self:EmitSound("physics/metal/metal_grenade_impact_soft1.wav")
        end
        self.TimerExplode = 1
    end

    function ENT:OnRemove()
        -- stop any gas sound that might still be playing
        self:StopSound("ambient/gas/steam2.wav")
    
        -- clear the screen‐effect flag on everyone
        for _, ply in ipairs(player.GetAll()) do
            ply:SetNWBool("InNeuroGas", false)
        end
    end
end

--//Removed until I can figure out how to stop errors//
-- CLIENT ONLY
if CLIENT then
    -- Called every frame to draw screen‐space posteffects
    hook.Add("RenderScreenspaceEffects", "NeuroGas_PostProcess", function()
        if LocalPlayer():GetNWBool("InNeuroGas") then
            -- Motion blur: arguments are (addalpha, drawalpha, delay)
            DrawMotionBlur(0.2, 0.8, 0.03)

            -- Bokeh depth‐of‐field effect
            -- The first parameter can be the material name or a Material object
            -- DrawMaterialOverlay("pp/blurx", 0.6)
        end
    end)
end
