--[[
	
	Developed By Sir Haza
	Developed by Bobblehead as well.
	
	Copyright (c) Sir Haza 2010
	Copyright (c) Bobblehead 2014
	
]]--

TOOL.Category		= "Constraints"
TOOL.Name			= "#tool.poly.name"
TOOL.Command		= nil
TOOL.ConfigName		= nil

TOOL.ClientConVar[ "radius" ] = "100"
TOOL.ClientConVar[ "drag" ] = "1"

CreateConVar("sbox_maxpolysize",100,{FCVAR_ARCHIVE,FCVAR_NOTIFY,FCVAR_REPLICATED,FCVAR_SERVER_CAN_EXECUTE})

if(CLIENT) then

	language.Add("undone_poly_prop", "Undone Polywelded Prop")
	language.Add("tool.poly.name", "Weld - Poly")
	language.Add("tool.poly.desc", "Permanent Poly Welds")
	language.Add("tool.poly.0", "Left Click to Select, (Hold E to select all in the area)    Right Click to Create Weld    Reload to Clear Selection.")
	language.Add("autoselect.radius.help", "Holding E will select all items in the area of a prop. This changes is how far it selects items.")
	language.Add("autoselect.radius", "Autoselect Radius")
	language.Add("enable.drag", "Enable Drag?")
	language.Add("enable.drag.help", "Air Drag makes the prop slow down through the air, especially for objects with a large volume.")
	language.Add("remove.constraints", "Remove old constraints?")
	language.Add("remove.constraints.help", "Props welded to the world before being Polywelded will be unmovable if the weld is not removed beforehand.")
	
end

/*---------------------------------------------------------
   Name:	LeftClick
   Desc:	Select
---------------------------------------------------------*/  
function TOOL:LeftClick( trace )
	if game.SinglePlayer() and SERVER then self:GetOwner():GetActiveWeapon():CallOnClient("PrimaryAttack") end
	
	if(!trace.Entity) then return false end
	if(!trace.Entity:IsValid()) then return false end
	if(trace.Entity:IsPlayer()) then return false end
	if(trace.Entity:GetClass() == "prop_ragdoll") then return false end
	if(trace.Entity:GetClass() == "gmod_poly") then return false end

	local entList = {trace.Entity}
	local inverse = false
	if self:GetOwner():KeyDown(IN_USE) then
		inverse = true
		entList = ents.FindInSphere(trace.Entity:GetPos(),self:GetClientNumber("radius",100))
	end
	
	self.Selected = self.Selected or {}
	
	for k, v in pairs(entList) do
	
		if IsValid(v) then
			if v:GetClass() == "prop_physics" and IsValid(v:GetParent()) and v:GetParent():GetClass() == "gmod_poly" then
				continue
			end
			
			if(v:IsPlayer()) then continue end
			if(v:GetClass() == "prop_ragdoll") then continue end
			if(v:GetClass() == "gmod_poly") then continue end
			
			-- print(inverse or (not self.Selected[v]))
			self.Selected[v] = inverse or (not self.Selected[v])
			
			if SERVER then
				for v,k in pairs(self.Selected)do
					if IsValid(v) then
						if k and not v._OldColor then
							v._OldColor = v:GetColor()
							v:SetColor(Color(255,0,0))
						else
							v:SetColor(v._OldColor or Color(255,255,255))
							v._OldColor = nil
						end
					else
						v = nil
					end
				end
			end
			
		end
		
	end
	
	return true

end

/*---------------------------------------------------------
   Name:	RightClick
   Desc:	Creat Weld.
---------------------------------------------------------*/  
function TOOL:RightClick( trace )
	if game.SinglePlayer() and SERVER then self:GetOwner():GetActiveWeapon():CallOnClient("SecondaryAttack") end
	
	if( self.Selected and table.Count(self.Selected) <= 1) then
		return true
	end

	local entList = {}
	local meshes = 0
	for v, k in pairs(self.Selected) do
	
		if(IsValid(v)) and IsValid(v:GetPhysicsObject()) and k then
			v:SetColor(v._OldColor or Color(255,255,255))
			
			table.insert(entList, v)
			meshes = meshes + #(v:GetPhysicsObject():GetMeshConvexes())
			
		end
		
	end
	
	if (meshes >= GetConVarNumber("sbox_maxpolysize")) then
		if CLIENT then notification.AddLegacy("Too complex! Might crash server. Reduce your polyweld size.",NOTIFY_ERROR,5) end
		return true
	end
	
	
	self.Selected = {}
	
	
	if (CLIENT) then return true end
	
	for k,v in pairs(entList) do
		undo.ReplaceEntity(v, Entity(-1))
		cleanup.ReplaceEntity(v, Entity(-1))
	end
	
	local drag = tobool(self:GetClientNumber( "drag", 1 ))
	local remove = tobool(self:GetClientNumber( "remove", 1 ))
	local ent = constraint.PolyWeld(entList,drag,trace.HitPos,remove)
	
	if(SPropProtection) then
	
		SPropProtection.PlayerMakePropOwner(self:GetOwner(), ent)
		
	end
	
	undo.Create("Poly_Prop")
		undo.AddEntity(ent)
		undo.SetPlayer(self:GetOwner())
	undo.Finish()
	
	cleanup.Add(self:GetOwner(), "Poly Weld", ent)
	
	return true
	
end

local function SetPhysicsCollisions( Ent, b )

	if ( !IsValid( Ent ) || !IsValid( Ent:GetPhysicsObject() ) ) then return end

	Ent:GetPhysicsObject():EnableCollisions( b )

end

function constraint.PolyWeld(entList,drag,root,clearOldConstraints)
	local ent = ents.Create("gmod_poly")
	
	for k,v in pairs(entList)do
		if v:IsValid() then
			local obj = v:GetPhysicsObject()
			if obj:IsValid() then
				obj:EnableMotion(false)
				obj:EnableCollisions( false )
			end
			if tobool(clearOldConstraints) then
				local c,i = constraint.RemoveAll(v)
			end
		end
	end
	
	timer.Simple(.1,function()
		
		ent:SetPos(root)
		ent:BuildWeld(entList)
		ent:Spawn()
		
		
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableDrag(tobool(drag))
		end
		
	end)
	return ent
end
duplicator.RegisterConstraint("PolyWeld",constraint.PolyWeld,"entList","drag","root","clearOldConstraints")

/*---------------------------------------------------------
   Name:	Reload
   Desc:	Clear Selection
---------------------------------------------------------*/  
function TOOL:Reload( trace )
	if game.SinglePlayer() and SERVER then self:GetOwner():GetActiveWeapon():CallOnClient("Reload") end
	self:GetOwner():GetActiveWeapon():Holster()
	return false
	
end

function TOOL:Holster()
	if game.SinglePlayer() and SERVER then self:GetOwner():GetActiveWeapon():CallOnClient("Holster") end
	if SERVER then
		for v,k in pairs(self.Selected or {})do
			if k and IsValid(v) then
				v:SetColor(v._OldColor or Color(255,255,255))
			end
		end
	end
	self.Selected = {}
end

function TOOL.BuildCPanel(CPanel)

	CPanel:AddControl( "Slider", { Label = "#autoselect.radius", Command = "poly_radius", Type = "Float", Min = 1, Max = 2000, Help = true } )
	CPanel:AddControl( "CheckBox", { Label = "#enable.drag", Command = "poly_drag", Help = true } )
	CPanel:AddControl( "CheckBox", { Label = "#remove.constraints", Command = "poly_const", Help = true } )

	CPanel:AddControl( "Header", { Description = [[

Combines all selected props into a single prop.

Less laggy and more stable than a weld. Less stupid and more predictable than a parent constraint.

Original tool by Sir Haza. Fixed to not-crash the server by Bobblehead.

SAVE YOUR GAME BEFORE APPLYING THE CONSTRAINT.]] } )
end

-- hook.Add("PreDrawHalos","Polyweld Halos",function()
	-- if LocalPlayer():Alive() and LocalPlayer():GetActiveWeapon():IsValid() and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_tool" then
		-- local tool = LocalPlayer():GetActiveWeapon():GetToolObject()
		-- if type(tool) == "table" then
			-- if tool.Name == "#tool.poly.name" then
				-- tool.Selected = tool.Selected or {}
				-- local tbl = {}
				-- for k,v in pairs(tool.Selected)do
					-- if v then
						-- table.insert(tbl,k)
					-- end
				-- end
				-- halo.Add(tbl, Color( 0, 255, 0 ), 5, 5, 1 )
			-- end
		-- end
	-- end
-- end)
