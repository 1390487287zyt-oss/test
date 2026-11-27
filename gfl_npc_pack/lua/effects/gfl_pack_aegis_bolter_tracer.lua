function EFFECT:Init(data)
	self.Position   = data:GetStart()
	self.WeaponEnt  = data:GetEntity()
	self.Attachment = data:GetAttachment()

	local basePos = self:GetTracerShootPos(self.Position, self.WeaponEnt, self.Attachment)

	local forward = Vector(0,0,0)

	if IsValid(self.WeaponEnt) and self.Attachment > 0 then
		local att = self.WeaponEnt:GetAttachment(self.Attachment)
		if att then
			forward = att.Ang:Forward()
		end
	end

	self.StartPos = basePos + forward * 50
	self.EndPos   = data:GetOrigin()

	util.ParticleTracerEx("magnet_tracer_heavy", self.StartPos, self.EndPos, 1, 0, -1)
	ParticleEffect("vh_hit", self.EndPos, angle_zero, nil)
end

function EFFECT:Render()
	return false
end

function EFFECT:Think()
    return false
end
