--[[
	
	Developed By Sir Haza
	Developed by Bobblehead as well.
	
	Copyright (c) Sir Haza 2010
	Copyright (c) Bobblehead 2014
	
]]--

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName		= "Poly Weld"
ENT.Author			= "Sir Haza & Bobblehead"
ENT.Contact			= "http://steamcommunity.com/id/bobblackmon"
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable		= false
ENT.AdminSpawnable	= false

-- function ENT:SetColor(color)
	-- for k,v in pairs(self.Children) do
		-- v:SetColor(color or Color(255,255,255))
	-- end
-- end

function ENT:SetupDataTables()
	
end


hook.Add("PhysgunPickup","Don't pick up children", function(ply,ent)
	if ent:GetParent() and ent:GetParent():IsValid() and ent:GetParent():GetClass() == "gmod_poly" then
		return false
	end
end)
-- hook.Add("CanTool","No Toolgun on polys",function( ply, tr, tool )
	 -- if ( IsValid( tr.Entity ) and tr.Entity:GetParent() and tr.Entity:GetParent():IsValid() and tr.Entity:GetParent():GetClass() == "gmod_poly" ) then
		 -- return false
	 -- end
-- end)
