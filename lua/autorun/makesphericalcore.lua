
--[[
	Copyright (C) 2013 David 'Falcqn' Hepworth

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
	documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
	the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
	and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS 
	BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF 
	OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]--

AddCSLuaFile( "makesphericalcore.lua" )

MakeSpherical = MakeSpherical or {}
local MakeSpherical = MakeSpherical

function MakeSpherical.CanTool( ent )

	if (
		not ent:IsValid()
		or string.find( ent:GetClass(), "npc_" ) or ( ent:GetClass() == "player" )
		or string.find( ent:GetClass(), "prop_vehicle_" ) 
		or ( ent:GetClass() == "prop_ragdoll" )
		or ( ent:GetMoveType() ~= MOVETYPE_VPHYSICS )
		or ( SERVER && not ent:GetPhysicsObject():IsValid() ) )
		
		then return false 
	
	end

	return true

end

if SERVER then
	
	MakeSpherical.RenderOffsetEnts = {}
	
	function MakeSpherical.ApplyLegacySphere( ply, ent, data )
		
		local obb = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = ent.noradius or math.max( obb.x, obb.y, obb.z ) / 2
		-- This is the default radius used when left-clicked with the tool, not set by the slider.
		-- It needs to be stored on the entity because it cannot be calculated after the radius has been set manually
		-- The ent's OBB size changes when made spherical
		
		-- In case the legacy dupe is old enough to not include these
		data.mass = ent:GetPhysicsObject():GetMass() or data.mass
		data.noradius = data.noradius or ent.noradius
		data.isrenderoffset = 0
		data.renderoffset = nil
		data.obbcenter = ent:OBBCenter()

		local phys = ent:GetPhysicsObject()
		local ismove = phys:IsMoveable()
		local issleep = phys:IsAsleep()
		
		local radius = math.Clamp( data.radius, 1, 200 )
		if data.enabled then
		
			ent:PhysicsInitSphere( radius, phys:GetMaterial() )
			ent:SetCollisionBounds( Vector( -radius, -radius, -radius ), Vector( radius, radius, radius ) )
		
		else
		
			ent:PhysicsInit( SOLID_VPHYSICS )
			ent:SetMoveType( MOVETYPE_VPHYSICS )
			ent:SetSolid( SOLID_VPHYSICS )
		
		end
		
		-- New physobject after applying spherical collisions
		local phys = ent:GetPhysicsObject()
		phys:SetMass( data.mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end
		
		ent.noradius = data.noradius
		ent.obbcenter = data.obbcenter
		duplicator.StoreEntityModifier( ent, "MakeSphericalCollisions", data )
		duplicator.ClearEntityModifier( ent, "sphere" )
	
	end
	
	function MakeSpherical.ApplySphericalCollisions( ply, ent, data )
		
		local phys = ent:GetPhysicsObject()
		local ismove = phys:IsMoveable()
		local issleep = phys:IsAsleep()
		local radius = math.Clamp( data.radius, 1, 200 )
		
		if data.enabled then
		
			ent:PhysicsInitSphere( radius, phys:GetMaterial() )
			ent:SetCollisionBounds( Vector( -radius, -radius, -radius ) , Vector( radius, radius, radius ) )
		
		else
		
			ent:PhysicsInit( SOLID_VPHYSICS )
			ent:SetMoveType( MOVETYPE_VPHYSICS )
			ent:SetSolid( SOLID_VPHYSICS )
		
		end
		
		if data.isrenderoffset ~= 0 then
		
			umsg.Start( "MakeSphericalAddRenderOffset" )
			
				umsg.Short( ent:EntIndex() )
				umsg.Vector( data.renderoffset )
				
			umsg.End()
			
			MakeSpherical.RenderOffsetEnts[ ent:EntIndex() ] = data.renderoffset
			
		elseif data.isrenderoffset == 0 and MakeSpherical.RenderOffsetEnts[ ent:EntIndex() ] then
		
			umsg.Start( "MakeSphericalRemoveRenderOffset" )
			
				umsg.Short( ent:EntIndex() )
				
			umsg.End()
			
		end
		
		-- New physobject after applying spherical collisions
		local phys = ent:GetPhysicsObject()
		phys:SetMass( data.mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end
		
		data.radius = radius
		ent.noradius = data.noradius
		duplicator.StoreEntityModifier( ent, "MakeSphericalCollisions", data )
		
	end
	
	function MakeSpherical.ApplySphericalCollisionsE2( ent, enabled, radius )
		
		local phys = ent:GetPhysicsObject()
		local mass = phys:GetMass()
		local ismove = phys:IsMoveable()
		local issleep = phys:IsAsleep()
		local radius = math.Clamp( radius, 1, 200 )
		
		if enabled then
		
			ent:PhysicsInitSphere( radius, phys:GetMaterial() )
			ent:SetCollisionBounds( Vector( -radius, -radius, -radius ) , Vector( radius, radius, radius ) )
		
		else
		
			ent:PhysicsInit( SOLID_VPHYSICS )
			ent:SetMoveType( MOVETYPE_VPHYSICS )
			ent:SetSolid( SOLID_VPHYSICS )
		
		end
		
		-- New physobject after applying spherical collisions
		local phys = ent:GetPhysicsObject()
		phys:SetMass( mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end
		
	end
	
	function MakeSpherical.CopyConstraintData( ent, removeconstraints )
	
		local constraintdata = {}
		for _, v in pairs( constraint.GetTable( ent ) ) do

			table.insert( constraintdata, v )
			
		end
		if removeconstraints then constraint.RemoveAll( ent ) end
		return constraintdata
	
	end
	
	function MakeSpherical.ApplyConstraintData( ent, constraintdata )
		
		if not ( table.Count( constraintdata ) > 0 and ent:IsValid() and ent:GetPhysicsObject():IsValid() ) then return end
		
		for k, constr in pairs( constraintdata ) do
			
			local factory = duplicator.ConstraintType[ constr.Type ]
			if not factory then 
			
				Msg( "MakeSpherical: Unknown constraint type '" .. constr.Type .. "', skipping\n" )
				break
			
			end
			
			-- Set up a table with "ent1 = Entity( n )" etc etc for use with the factory function
			local args = {}
			for i = 1, #factory.Args do
				
				args[ i ] = constr[ factory.Args[ i ] ]
			
			end

			-- GG Wire team, spelling "Ctrl" wrong
			-- This section is just to fix stuff like wire hydraulics that need "crontollers"
			if constr.MyCrtl then
				
				-- Apply the constraint & set all the crap wire hydraulics/winches need etc
				local controller = Entity( constr.MyCrtl )
				controller.constraint:Remove()
				
				if constr.Type == "WireHydraulic" then
				
					WireHydraulicTracking[ constr.MyCrtl ] = controller
					
				elseif constr.Type == "WireWinch" then 
				
					WireWinchTracking[ constr.MyCrtl ] = controller
				
				end
			
			end
				
			-- Apply the constraint			
			local constr, misc = factory.Func( unpack( args ) )
			
			-- Wheels need their ent.Motor value set to their motor constraint
			if ent:GetClass() == "gmod_wheel" or ent:GetClass() == "gmod_wire_wheel" then
						
				ent.Motor = constr 
				
			end
			
		end
	
	end
	
	hook.Add( "PlayerConnected", "MakeSphericalSyncOffsetTable", function( ply )
	
		for k, v in pairs( MakeSpherical.ApplySphericalCollisions ) do
		
			umsg.Start( "MakeSphericalAddRenderOffset" )
			
				umsg.Short( k )
				umsg.Vector( v )
			
			umsg.End()
			
		end
		
	end )
	
	duplicator.RegisterEntityModifier( "sphere", MakeSpherical.ApplyLegacySphere )
	duplicator.RegisterEntityModifier( "MakeSphericalCollisions", MakeSpherical.ApplySphericalCollisions )
	
end

if CLIENT then
	
	local temp = {}
	
	usermessage.Hook( "MakeSphericalAddRenderOffset", function( um )
		
		local id = um:ReadShort()
		local offset = um:ReadVector()
		local ent = Entity( id )
		
		if not ent:IsValid() then
		
			temp[ id ] = offset
			return
			
		end
		
		ent.RenderOverride = function( self )
			
			ent:SetRenderOrigin( ent:LocalToWorld( offset ) )
			ent:SetupBones()
			if ent.Draw then ent:Draw() else ent:DrawModel() end
			ent:SetRenderOrigin( nil )
		
		end
		
	end )
	
	usermessage.Hook( "MakeSphericalRemoveRenderOffset", function( um )
		
		local ent = Entity( um:ReadShort() )
		ent.RenderOverride = nil
		
	end )
	
	hook.Add( "OnEntityCreated", "MakeSphericalEntityAddedDelay", function( ent )
		
		local id = ent:EntIndex()
		if not temp[ id ] then return end
		
		ent.RenderOverride = function( self )
		
			ent:SetRenderOrigin( offset )
			ent:SetupBones()
			if ent.Draw then ent:Draw() else ent:DrawModel() end
			ent:SetRenderOrigin( nil )
			
		end
		
		temp[ id ] = nil
		
	end )
	
end