ENT.Base 			= "npc_vj_tankg_base" -- List of all base types: https://github.com/DrVrej/VJ-Base/wiki/Base-Types
ENT.Type 			= "ai"
ENT.PrintName 		= "SF Deichgraf tank"
ENT.Author 			= "Model And Base:BUTTHE4D, edited: Sokolnichij"
ENT.Contact 		= "https://steamcommunity.com/profiles/76561198180831682/"
ENT.Purpose 		= "Spawn it and fight with it!"
ENT.Instructions 	= "Click on the spawnicon to spawn it."
ENT.Category		= "GFL"

net.Receive("vj_sf_deichgraf_tank_shooteffects", function()
	local ent = net.ReadEntity()
	if ent:IsValid() then
	ent.Emitter = ParticleEmitter(ent:GetPos())
	ent.SmokeEffect2 = ent.Emitter:Add("particles/smokey",ent:GetPos() +ent:GetForward()*-230 +ent:GetRight()*0 +ent:GetUp()*72)
	ent.SmokeEffect2:SetVelocity( ent:GetForward() * math.Rand(0,-50) + Vector(0,-30,math.Rand(-10,-20)) + ent:GetVelocity() )
	ent.SmokeEffect2:SetDieTime(2)
	ent.SmokeEffect2:SetStartAlpha(30)
	ent.SmokeEffect2:SetEndAlpha(0)
	ent.SmokeEffect2:SetStartSize(3)
	ent.SmokeEffect2:SetEndSize(50)
	ent.SmokeEffect2:SetRoll(math.Rand(-0.2,0.2))
	ent.SmokeEffect2:SetColor(150,150,150,255)
	ent.Emitter:Finish()
	end
end)