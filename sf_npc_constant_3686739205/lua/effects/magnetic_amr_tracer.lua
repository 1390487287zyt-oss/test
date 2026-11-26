function EFFECT:Init(data)
	self.Position   = data:GetStart()
	self.WeaponEnt  = data:GetEntity()
	self.Attachment = data:GetAttachment()
	self.EndPos     = data:GetOrigin()

	local basePos = self:GetTracerShootPos(self.Position, self.WeaponEnt, self.Attachment)
end

function EFFECT:Render()
	return false
end