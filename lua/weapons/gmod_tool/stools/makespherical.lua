

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

AddCSLuaFile( "makespherical.lua" )

TOOL.Category 		= "Construction"
TOOL.Name 			= "#tool.makespherical.name"
TOOL.Command 		= nil
TOOL.ConfigName 	= nil

TOOL.ClientConVar[ "radius" ] 		= "20"
TOOL.ClientConVar[ "offset" ] 		= "0"
TOOL.ClientConVar[ "offset_x" ] 	= "0"
TOOL.ClientConVar[ "offset_y" ] 	= "0"
TOOL.ClientConVar[ "offset_z" ] 	= "0"
TOOL.ClientConVar[ "useobbcenter" ] = "0"

if CLIENT then
	
	language.Add( "tool.makespherical.name", "Make Spherical" )
	language.Add( "tool.makespherical.desc", "Gives entities a spherical collisions with a defined radius" )
	language.Add( "tool.makespherical.0", "Left click to make an entity have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	language.Add( "tool.makespherical.1", "Left click to make an entity have spherical collisions based on its size. Right click to set collisions with a custom radius" )
	
	function TOOL.BuildCPanel( panel )
		
		panel:AddControl( "Header", { Text = "#tool.makespherical.name", Description = "#tool.makespherical.desc" } )
		
		panel:AddControl( "Slider", 
		{
			Label 	= "Set radius: ",
			Type 	= "Float",
			Min 	= "1",
			Max 	= "200",
			Command = "makespherical_radius"
		})
		
		panel:AddControl( "CheckBox",
		{
			Label = "Offset render origin?",
			Command = "makespherical_offset"
		})
		
		panel:AddControl( "Label",
		{
			Text = "Note: This only changes the position the prop's model is drawn at, getting the position or bounding box center in Lua or in "
					.. "E2 will give the exact same coordinates.\nThe prop's position will still be the center of the sphere."
		})
		
		panel:AddControl( "Slider",
		{
			Label 	= "X Offset",
			Type 	= "Float",
			Min 	= "-100",
			Max 	= "100",
			Command = "makespherical_offset_x"
		})
		
		panel:AddControl( "Slider",
		{
			Label 	= "Y Offset",
			Type 	= "Float",
			Min 	= "-100",
			Max 	= "100",
			Command = "makespherical_offset_y"
		})
		
		panel:AddControl( "Slider",
		{
			Label 	= "Z Offset",
			Type 	= "Float",
			Min		= "-100",
			Max 	= "100",
			Command = "makespherical_offset_z"
		})
		
		panel:AddControl( "CheckBox",
		{
			Label = "Offset position by bounding box center instead",
			Command = "makespherical_useobbcenter"
		})
	
	end

end

function TOOL:LeftClick( trace )

	local ent = trace.Entity
	if not MakeSpherical.CanTool( ent ) then return false end
	if CLIENT then return true end

	if not ent.noradius then
	
		local OBB = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 
		
	end
	
	ent.obbcenter = ent.obbcenter or ent:OBBCenter()
	local offsetvec = Vector( self:GetClientNumber( "offset_x" ), self:GetClientNumber( "offset_y" ), self:GetClientNumber( "offset_z" ) )
	
	local data = 
	{
		-- I store the obbcenter and "obb radius" because they are altered when SetCollisionBounds is used
		-- This allows the spherical collisions to be reset even after duping
		obbcenter 		= ent.obbcenter,
		noradius 		= ent.noradius,
		radius 			= ent.noradius,
		mass 			= ent:GetPhysicsObject():GetMass(),
		enabled 		= true,
		isrenderoffset 	= self:GetClientNumber( "offset" ),
		renderoffset 	= ( self:GetClientNumber( "useobbcenter" ) == 1 ) and -ent.obbcenter or offsetvec
	}
	
	local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
	MakeSpherical.ApplySphericalCollisions( self:GetOwner(), ent, data )
	timer.Simple( 0.01, function() MakeSpherical.ApplyConstraintData( ent, constraintdata ) end )
		
	return true

end

function TOOL:RightClick( trace )

	local ent = trace.Entity
	if not MakeSpherical.CanTool( ent ) then return false end
	if CLIENT then return true end

	if not ent.noradius then
	
		local OBB = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 
		
	end
	
	ent.obbcenter = ent.obbcenter or ent:OBBCenter()
	local offsetvec = Vector( self:GetClientNumber( "offset_x" ), self:GetClientNumber( "offset_y" ), self:GetClientNumber( "offset_z" ) )

	local data = 
	{
		obbcenter		= ent.obbcenter,							
		noradius 		= ent.noradius,
		radius 			= self:GetClientNumber( "radius" ),
		mass			= ent:GetPhysicsObject():GetMass(),
		enabled 		= true,
		isrenderoffset 	= self:GetClientNumber( "offset" ),
		renderoffset 	= ( self:GetClientNumber( "useobbcenter" ) == 1 ) and -ent.obbcenter or offsetvec
	}
	
	local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
	MakeSpherical.ApplySphericalCollisions( self:GetOwner(), ent, data )
	timer.Simple( 0.01, function() MakeSpherical.ApplyConstraintData( ent, constraintdata ) end )
	
	return true

end

function TOOL:Reload( trace )

	local ent = trace.Entity
	if not MakeSpherical.CanTool( ent ) then return false end
	if CLIENT then return true end
	
	if not ent.noradius then
	
		local OBB = ent:OBBMaxs() - ent:OBBMins()
		ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2 
		
	end
	
	ent.obbcenter = ent.obbcenter or ent:OBBCenter()
	
	local data = 
	{
		obbcenter 		= ent.obbcenter,
		noradius 		= ent.noradius,
		radius 			= ent.noradius,
		mass 			= ent:GetPhysicsObject():GetMass(),
		enabled 		= false,
		isrenderoffset 	= 0,
		renderoffset 	= nil
	}
	
	local constraintdata = MakeSpherical.CopyConstraintData( ent, true )
	MakeSpherical.ApplySphericalCollisions( self:GetOwner(), ent, data )
	timer.Simple( 0.01, function() MakeSpherical.ApplyConstraintData( ent, constraintdata ) end )
	
	return true
	
end