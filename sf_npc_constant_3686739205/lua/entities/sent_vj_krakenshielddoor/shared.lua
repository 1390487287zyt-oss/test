if (!file.Exists("autorun/vj_base_autorun.lua","LUA")) then return end

ENT.Base 			= "base_gmodentity"
ENT.Type 			= "anim"
ENT.PrintName 		= "Wotan Shield"
ENT.Author 			= "DrVrej"
ENT.Contact 		= "http://steamcommunity.com/groups/vrejgaming"
ENT.Purpose 		= "protect"
ENT.Instructions 	= "unclear"
ENT.Category		= "redacted"

ENT.Spawnable = false
ENT.AdminOnly = false
---------------------------------------------------------------------------------------------------------------------------------------------
if (CLIENT) then
	function ENT:Draw()
		self:DrawModel()
	end
end
