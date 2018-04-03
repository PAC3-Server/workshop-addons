--[[
	
	Developed By Sir Haza
	Developed by Bobblehead as well.
	
	Copyright (c) Sir Haza 2010
	Copyright (c) Bobblehead 2014
	
]]--

ENT.RenderGroup = RENDERGROUP_BOTH

include('shared.lua')

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	local phys = self:GetPhysicsObject()
	
	if(phys and phys:IsValid()) then
		phys:EnableCollisions(false)
	end
end

//Debug:
--[[
usermessage.Hook("debugpoly",function(um)
	local pos1 = um:ReadVector()
	local pos2 = um:ReadVector()
	local pos3 = um:ReadVector()
	debugoverlay.Cross(pos1,3,60,Color(255,0,0),false)
	debugoverlay.Cross(pos2,3,60,Color(255,0,0),false)
	debugoverlay.Cross(pos3,3,60,Color(255,0,0),false)
	
	debugoverlay.Line(pos1,pos2,60,Color(0,255,0),false)
	debugoverlay.Line(pos2,pos3,60,Color(0,255,0),false)
	debugoverlay.Line(pos3,pos1,60,Color(0,255,0),false)
end)

local lastpos
usermessage.Hook("debugpoly1",function(um)
	local pos = um:ReadVector()
	debugoverlay.Cross(pos,3,60,Color(255,0,0),false)
	
	if lastpos then
		debugoverlay.Line(pos,lastpos,60,Color(0,255,0),false)
	end
	lastpos = pos
end)

function StopPolyLine()
	lastpos = nil
end
]]


/*---------------------------------------------------------
   Name: Draw
---------------------------------------------------------*/
function ENT:Draw()

	self.BaseClass.Draw( self )
		
end

/*---------------------------------------------------------
   Name: DrawTranslucent
   Desc: Draw translucent
---------------------------------------------------------*/
function ENT:DrawTranslucent()

	self.BaseClass.DrawTranslucent( self )
	
end


/*---------------------------------------------------------
   Name: Think
   Desc: Client Think - called every frame
---------------------------------------------------------*/
function ENT:Think()
	-- local mainPhys = self:GetPhysicsObject()
	-- local possibleChildren = ents.FindByClass("prop_physics")

	-- for _, v in pairs(possibleChildren) do
		-- if(v:GetParent() == self) then
			-- local phys = v:GetPhysicsObject()
			
			-- if(phys and phys:IsValid()) then
				-- phys:EnableCollisions(true)
				-- v:EnableCustomCollisions(true)
				
				-- if(mainPhys:IsAsleep()) then
					-- phys:Sleep()
				-- else
				
					-- phys:Wake()
				-- end
			-- end
		-- end
	-- end
	
	-- self:EnableCustomCollisions()
end

