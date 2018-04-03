--[[
	
	Developed By Sir Haza
	Developed by Bobblehead as well.
	
	Copyright (c) Sir Haza 2010
	Copyright (c) Bobblehead 2014
	
]]--

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

/*---------------------------------------------------------
   Name: Initialize
---------------------------------------------------------*/
function ENT:Initialize()
	
	if( self.Mesh && table.Count(self.Mesh) > 0 ) then
	
		self:SetModel( "models/hunter/blocks/cube025x025x025.mdl" )
		self:SetNoDraw(true)
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
	
		local phys = self:GetPhysicsObject()
		
		if(phys:IsValid()) then
			//phys:RebuildFromConvexs(self:GetPos(), self:GetAngles(), self.Mass, 0.001, 0.001, 1, 1, self.Mesh)
			self:PhysicsDestroy()
			self:PhysicsInitMultiConvex(self.Mesh)
			self:EnableCustomCollisions(true)		
		end
		phys = self:GetPhysicsObject() //Get new mesh physobj.
		if phys:IsValid() then
			-- phys:EnableDrag(false)
			phys:SetMass(self.Mass)
			phys:SetMaterial("solidmetal")
			
			for i,ent in pairs(self.Children)do
				local constraints = {}
				for k,constr in pairs(constraint.GetTable(ent))do
					for i=1,6 do
						if not(constr["Ent"..i] != ent and table.HasValue(self.Children,constr["Ent"..i])) then
							if constr["Ent"..i] == ent then
								constr["Ent"..i] = self
								if constr.Entity[i] then
									constr.Entity[i].Entity = self
									constr.Entity[i].Bone = 0
									constr.Entity[i].Index = self:EntIndex()
								end
							end
							table.insert(constraints,constr)
						end
					end
				end
				
				constraint.RemoveAll(ent)
				
				for _,Constraint in pairs(constraints)do
					//Copied from duplicator.CreateConstraintFromTable
					
					local Factory = duplicator.ConstraintType[ Constraint.Type ]
					
					local Args = {}
					for k, Key in pairs( Factory.Args ) do
					
						local Val = Constraint[ Key ]
						
						-- If there's a missing argument then unpack will stop sending at that argument
						if ( Val == nil ) then Val = false end
						
						table.insert( Args, Val )
					
					end
					
					//Create the actual constraint
					Factory.Func( unpack(Args) )
				end
				
			end
			
		end
		
	else
		-- self:Remove()
	end
	
end

/*---------------------------------------------------------
   Name: BuildWeld
---------------------------------------------------------*/
function ENT:BuildWeld(entTable)
	if #entTable < 2 then return end
	self.Children = {}
	for k,ent in pairs(entTable)do
		if(ent:GetParent():IsValid()) then
			continue
		end

		self.Mesh = self.Mesh or {}
		self.Mass = self.Mass or 0
		
		local delta = ent:GetPos() - self:GetPos()
		local phys = ent:GetPhysicsObject()
		
		if( phys:IsValid() ) then
			-- constraint.RemoveAll(ent)
			
			local angle = phys:GetAngles()
			local convexes = phys:GetMeshConvexes()
			for _,convex in pairs(convexes) do
				local entmesh = {}
				for _, point in ipairs(convex) do
					point.pos:Rotate(angle)
					point.pos = point.pos + delta
					
					//Debug:
					-- umsg.Start("debugpoly1")
						-- umsg.Vector(self:LocalToWorld(point.pos))
					-- umsg.End()
					
					-- local unique = true
					-- for index,existingPoint in pairs(self.Mesh)do
						-- -- if point.pos:Distance(existingPoint.pos) <= .05 then
						-- if point.pos==existingPoint.pos then
							-- //If this point is shared by 6 other points, it is not visible.
							-- -- existingPoint.fails = (existingPoint.fails or 0) + 1
							-- -- if existingPoint.fails == 6 then 
								-- -- self.Mesh[index] = nil
							-- -- end
							-- unique = false
						-- end
					-- end
					-- if unique then
						table.insert(entmesh,point.pos)
					-- end
					
				end
				//Debug:
				--BroadcastLua("StopPolyLine()")
				table.insert(self.Mesh,entmesh)
			end
		end
		
		if phys:IsValid() then
			-- ent:SetCollisionGroup(COLLISION_GROUP_NONE)
				
			self.Mass = self.Mass + phys:GetMass()
			
			-- ent:PhysicsDestroy()
				
			ent:SetParent(self)
			
			table.insert(self.Children, ent)
		end
		
		ent.GetPhysicsObject = function(s)
			return self:GetPhysicsObject()
		end
		
	end
	
end

--[[
/*---------------------------------------------------------
   Name: MergeEntity
---------------------------------------------------------*/
function ENT:MergeEntity(ent)
	if(ent:GetParent():IsValid()) then
		return
	end

	self.Mesh = self.Mesh or {}
	self.Children = self.Children or {}
	self.Mass = self.Mass or 0
	
	local delta = ent:GetPos() - self:GetPos()
	local phys = ent:GetPhysicsObject()
	
	if( phys:IsValid() ) then
		constraint.RemoveAll(ent)
		
		local angle = phys:GetAngles()
		local convex = phys:GetMesh()
		for _, point in pairs(convex) do
			
			point.pos:Rotate(angle)
			point.pos = point.pos + delta
			
			local unique = true
			for index,existingPoint in pairs(self.Mesh)do
				-- if point.pos:Distance(existingPoint.pos) <= .05 then
				if point.pos==existingPoint.pos then
					//If this point is shared by 6 other points, it is not visible.
					-- existingPoint.fails = (existingPoint.fails or 0) + 1
					-- if existingPoint.fails == 6 then 
						-- self.Mesh[index] = nil
					-- end
					unique = false
				end
			end
			if unique then
				table.insert(self.Mesh, point)
			end
			
		end

		ent:SetCollisionGroup(COLLISION_GROUP_NONE)
			
		self.Mass = self.Mass + phys:GetMass()
		
		ent:PhysicsDestroy()
			
		ent:SetParent(self)
		
		table.insert(self.Children, ent)
		
	end
end
]]

local hard = {Sound( "physics/metal/metal_solid_impact_hard1.wav" ),Sound( "physics/metal/metal_solid_impact_hard4.wav" ),Sound( "physics/metal/metal_solid_impact_hard5.wav" )}
local soft = {Sound( "physics/metal/metal_solid_impact_soft1.wav" ),Sound( "physics/metal/metal_solid_impact_soft2.wav" ),Sound( "physics/metal/metal_solid_impact_soft3.wav" )}
function ENT:PhysicsCollide( data, phys )
	if data.DeltaTime > .5 and self:GetPhysicsObject():IsMotionEnabled() then
		if ( data.Speed*self.Mass > 200000 ) then
			self:EmitSound( table.Random(hard),75,100 )
		else
			self:EmitSound( table.Random(soft),55,100 )
		end
	end
end

/*---------------------------------------------------------
   Name: OnRestore
---------------------------------------------------------*/
function ENT:OnRestore()
	
end


/*---------------------------------------------------------
   Name: PreEntityCopy
---------------------------------------------------------*/
function ENT:PreEntityCopy()
	local info = {}
	
	info.Children = {}
	
	for _, v in pairs(self.Children) do
	
		local child = {}
		child.Class = v:GetClass()
		child.Model = v:GetModel()
		child.Pos = v:GetPos() - self:GetPos()
		child.Pos:Rotate(-1 * self:GetAngles())
		child.Ang = v:GetAngles() - self:GetAngles()
		child.Mat = v:GetMaterial()
		child.Skin = v:GetSkin()
		
		table.insert(info.Children, child)
		
	end
	
	info.Mass = self.Mass
	
	info.Frozen = !self:GetPhysicsObject():IsMoveable()
	
	duplicator.StoreEntityModifier(self, "PolyDupe", info)
end

/*---------------------------------------------------------
   Name: PostEntityPaste
---------------------------------------------------------*/
function ENT:PostEntityPaste(ply, ent, createdEnts)
	if(ent.EntityMods and ent.EntityMods.PolyDupe) then
		--PrintTable(ent.EntityMods.PolyDupe)
		local entList = {}
		
		for _, v in pairs(ent.EntityMods.PolyDupe.Children) do
			local prop = ents.Create(v.Class)
			
			prop:SetModel(v.Model)
			
			local pos = Vector(v.Pos.x, v.Pos.y, v.Pos.z)
			pos:Rotate(self:GetAngles())
			pos = pos + self:GetPos()
			
			prop:SetPos(pos)
			prop:SetAngles(v.Ang + self:GetAngles())
			
			prop:Spawn()
			
			prop:SetMaterial(v.Mat)
			prop:SetSkin(v.Skin)
			
			if(SPropProtection) then
				SPropProtection.PlayerMakePropOwner(ply, prop)
			end
			
			table.insert(entList, prop)
		end
		
		
		self:BuildWeld(entList)
		
		self.Mass = ent.EntityMods.PolyDupe.Mass
		
		self:Spawn()
		
		
		if(ent.EntityMods.PolyDupe.Frozen) then
		
			ent:GetPhysicsObject():EnableMotion(false)
		
		end
	end
end

/*---------------------------------------------------------
   Name: OnTakeDamage
---------------------------------------------------------*/
function ENT:OnTakeDamage( dmginfo )
	self:TakePhysicsDamage( dmginfo )
end


/*---------------------------------------------------------
   Name: Think
---------------------------------------------------------*/
function ENT:Think()
	self:NextThink( CurTime() + 0.25 )
	
	return true
end

/*---------------------------------------------------------
   Name: Use
---------------------------------------------------------*/
function ENT:Use( activator, caller )

end



