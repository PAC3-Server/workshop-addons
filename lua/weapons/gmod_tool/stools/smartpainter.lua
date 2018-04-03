TOOL.Category		= "Render"
TOOL.Name			= "#tool.smartpainter.name"
TOOL.Command		= nil
TOOL.ConfigName		= ""

local SMPA = "smartpainter"

AddCSLuaFile( SMPA.."/ui.lua" )

if CLIENT then
	language.Add( "Tool."..SMPA..".name", "Smart Painter" )
	language.Add( "Tool."..SMPA..".desc", "Easy color/material switcher for whole contraption" )
	language.Add( "Tool."..SMPA..".0", "Left - select/deselct prop, Left + E - select whole contraption, Left + Shift - select entities in range, Right - Select prop scheme, Shift - preview, R - deselect all" )
end

if SERVER then
	util.AddNetworkString( "SCHEMES_clear" )
	util.AddNetworkString( "SCHEMES_update" )
	util.AddNetworkString( "SCHEMES_paint" )
end

TOOL.ClientConVar =
{
	["onlyprops"] 			= "1",
	["material"]			= "",
	["colr"]				= "255",
	["colg"]				= "255",
	["colb"]				= "255",
	["cola"]				= "255",
	["index"]				= "0",
	["selection_size"]		= "100",
	["ignoredifferences"]   = "0"
}

TOOL.SelectedProps = {}
TOOL.SCHEMES = {}
TOOL.SelectionColor = Color(255,200,0,200)
TOOL.SelectionColor2 = Color(255,50,0,200)


function TOOL:ColorsAreMatching( col, col2)
	local Ignore = self:GetClientNumber("ignoredifferences")
	if Ignore == 0 then
		if col.r == col2.r and col.g == col2.g and col.b == col2.b then
			return true
		end
	else
		if math.abs(col.r - col2.r)<30 and math.abs(col.g - col2.g)<30 and math.abs(col.b - col2.b)<30 then
			return true
		end
	end
	return false
end

local function IsReallyValid(trace)
	if not trace.Entity:IsValid() then return false end
	if trace.Entity:IsPlayer() then return false end
	if SERVER and not trace.Entity:GetPhysicsObject():IsValid() then return false end
	return true
end

function TOOL:AddScheme( mat, col, index )
	if not mat or mat == "" then mat = "none" end
	if not col then col = Color(255,255,255,255) end

	if not index then
		local Table = {}
		Table.mat = mat
		Table.col = col
		Table.Props = 1
		table.insert(self.SCHEMES, Table)
		net.Start("SCHEMES_update")
			net.WriteFloat(#self.SCHEMES)
			net.WriteTable(Table)
		net.Send(self:GetOwner())
		return #self.SCHEMES
	else
		self.SCHEMES[index].Props = self.SCHEMES[index].Props + 1
		umsg.Start("SCHEMES_propsupdate",self:GetOwner())
			umsg.Float(index)
			umsg.Float(self.SCHEMES[index].Props)
		umsg.End()
	end
end

function TOOL:RemoveScheme( index )
	if not self.SCHEMES[index] then return end
	local Count = self.SCHEMES[index].Props
	if not Count or Count <= 1 then
		if #self.SCHEMES<= 1 then
				self:DeselectAll()
			return
		end
		table.remove(self.SCHEMES, index)
		umsg.Start("SCHEMES_removetable",self:GetOwner())
			umsg.Float(index)
		umsg.End()
	elseif Count then
		self.SCHEMES[index].Props = Count - 1
		umsg.Start("SCHEMES_propsupdate",self:GetOwner())
			umsg.Float(index)
			umsg.Float(self.SCHEMES[index].Props)
		umsg.End()
	end
end

function TOOL:CheckScheme( mat, col )
	if not mat or mat == "" then mat = "none" end
	if not col then col = Color(255,255,255,255) end 
	
	local index = #self.SCHEMES
	if index < 1 then
		return false
	end
	
	for k,v in pairs( self.SCHEMES ) do
		if v or v != {} then			
			if mat == v.mat and self:ColorsAreMatching(col, v.col) then
				index = k
				return true, index
			end
		end
	end
	
	return false
end

function TOOL:SelectEnt( ent )
	local Exists, Index = self:CheckScheme( ent:GetMaterial(), ent:GetColor() )
	
	if Exists then
		self:AddScheme( nil, nil, Index )
	elseif not Exists then
		Index = self:AddScheme( ent:GetMaterial(), ent:GetColor() )
	end

	local Prop = {}
	Prop.col = ent:GetColor()
	Prop.mat = ent:GetMaterial()
	Prop.renmode = ent:GetRenderMode()
	Prop.ent = ent
	Prop.index = Index
	table.insert( self.SelectedProps, Prop )
	local Selected = self:GetClientNumber("index")
	if Selected and Selected == Index then
		ent:SetColor(self.SelectionColor2)
	else
		ent:SetColor(self.SelectionColor)
	end	
	ent:SetRenderMode(RENDERMODE_TRANSALPHA)
end

local function SetMaterial( Player, Entity, Data )
	if SERVER then
		Entity:SetMaterial( Data.MaterialOverride )
		duplicator.StoreEntityModifier( Entity, "material", Data )
	end
	return true
end

local function SetColour( Player, Entity, Data )

    if ( Data.Color && Data.Color.a < 255 && Data.RenderMode == 0 ) then
        Data.RenderMode = 1
    end

    if ( Data.Color ) then Entity:SetColor( Color( Data.Color.r, Data.Color.g, Data.Color.b, Data.Color.a ) ) end
    if ( Data.RenderMode ) then Entity:SetRenderMode( Data.RenderMode ) end
    if ( Data.RenderFX ) then Entity:SetKeyValue( "renderfx", Data.RenderFX ) end

    if ( SERVER ) then
        duplicator.StoreEntityModifier( Entity, "colour", Data )
    end
	
	return true
end

function TOOL:DeselectEnt( ent )
	for k, v in pairs( self.SelectedProps ) do
		if v.ent == ent then
			local Index = v.index
			
			v.ent:SetColor( v.col )
			v.ent:SetRenderMode(v.renmode)
			SetMaterial(self:GetOwner(), v.ent, {MaterialOverride = v.mat} )
			SetColour( self:GetOwner(), v.ent, {Color = v.col, RenderMode = v.renmode, RenderFX = 0} )
			self:RemoveScheme( Index )
			
			table.remove( self.SelectedProps, k )
		end
	end
end

function TOOL:DeselectAll()
	if #self.SelectedProps>0 or #self.SCHEMES>0 then
		for k, v in pairs( self.SelectedProps ) do
			if IsValid(v.ent) and v.ent != NULL then
				v.ent:SetColor( v.col )
				v.ent:SetRenderMode(v.renmode)
				SetMaterial(self:GetOwner(), v.ent, {MaterialOverride = v.mat} )
				SetColour( self:GetOwner(), v.ent, {Color = v.col, RenderMode = v.renmode, RenderFX = 0} )
			end
		end
		self.SelectedProps = {}
		self.SCHEMES = {}

		net.Start("SCHEMES_clear")  ---- Somehow umsg doesn't work in this particular place
			net.WriteTable( self.SCHEMES )
		net.Send(self:GetOwner())
	end
end

function TOOL:IsSelected( ent )
	if table.Count( self.SelectedProps ) > 0 then
		for k, v in pairs( self.SelectedProps ) do
			if v.ent == ent then
				return true
			end
		end
	end
	return false
end

local function FindInSphere(Pos, max, ply)

		local Entities = ents.GetAll()
		local EntTable = {}
		for _,ent in pairs(Entities) do
			local pos = ent:GetPos()
			if IsValid(ent) and ent != NULL and not ent:IsPlayer() and pos:Distance(Pos) <= max then
				if CPPI then
					if ent:CPPICanTool( ply, SMPA ) then
							EntTable[ent:EntIndex()] = ent
					end
				elseif ent:GetOwner() == ply or  ent:GetOwner() == ply:GetName() then
					EntTable[ent:EntIndex()] = ent
				end
			end
		end

		return EntTable
end

function TOOL:LeftClick( trace )
	if CLIENT and IsReallyValid(trace) then return true end
	if not IsReallyValid(trace) then return false end
	
	local trent = trace.Entity
	local ply = self:GetOwner()
	
	if ply:KeyDown(IN_USE) then
		local Entities = constraint.GetAllConstrainedEntities(trent)
		for ent , v in pairs( Entities ) do -- Select all and auto detect color schemes
			if IsValid(ent) and ent != NULL and not self:IsSelected( ent ) then
					if self:GetClientNumber("onlyprops") == 1 and ent:GetClass() == "prop_physics" then
						self:SelectEnt( ent )
					elseif self:GetClientNumber("onlyprops") == 0 then
						self:SelectEnt( ent )
					end
			end
		end
		return true
	elseif ply:KeyDown(IN_SPEED) then	
		local AreaSize = self:GetClientNumber("selection_size")
		if not AreaSize or AreaSize<50 then AreaSize = 50 end
		local Entities = FindInSphere(trace.HitPos, 500, ply)
		for _ , ent in pairs( Entities ) do -- Select all and auto detect color schemes
			if not self:IsSelected( ent ) then
					if self:GetClientNumber("onlyprops") == 1 and ent:GetClass() == "prop_physics" then
						self:SelectEnt( ent )
					elseif self:GetClientNumber("onlyprops") == 0 then
						self:SelectEnt( ent )
					end
			end
		end
		return true
	elseif self:IsSelected( trent ) then
		self:DeselectEnt( trent )
		return true
	else
		self:SelectEnt( trent )
		return true
	end
	
	return true;
end

function TOOL:RightClick( trace )
	local ent = trace.Entity
	if IsValid(ent) and ent != NULL then
		for k, v in pairs( self.SelectedProps ) do
			if v.ent == ent then
				umsg.Start("SCHEMES_updateindex", self:GetOwner())
					umsg.Float(v.index)
				umsg.End()
				return true
			end
		end
	end
end

function TOOL:Reload()
	self:DeselectAll()
end

function TOOL:Think()
	if not self.SelectedProps or not self.SCHEMES or self.SelectedProps == {} or self.SCHEMES == {} then return end
	local Index = self:GetClientNumber("index")
	if Index != self.LastIndex then
		self.LastIndex = Index
		for k, v in pairs( self.SelectedProps ) do
			if IsValid(v.ent) and v.ent != NULL then
				if not Index or Index != v.index then 
					v.ent:SetColor( self.SelectionColor )
				else
					v.ent:SetColor( self.SelectionColor2 )
				end
			end
		end
	end
	
	if self:GetOwner():KeyDown(IN_SPEED) then
		self.Shift = true
		local NewColor = Color(self:GetClientNumber("colr"), self:GetClientNumber("colg"), self:GetClientNumber("colb"), self:GetClientNumber("cola"))
		if NewColor != self.LastColor then
			self.LastColor = NewColor
			if table.Count( self.SelectedProps ) > 0 then
				for k, v in pairs( self.SelectedProps ) do
					if IsValid(v.ent) and v.ent != NULL then
						v.ent:SetColor( v.col )
					end
				end
			end
		end
	elseif not self:GetOwner():KeyDown(IN_SPEED) and self.Shift then
		self.Shift = false
		if table.Count( self.SelectedProps ) > 0 then
			for k, v in pairs( self.SelectedProps ) do
				if IsValid(v.ent) and v.ent != NULL then
					if not Index or Index != v.index then 
						v.ent:SetColor( self.SelectionColor )
					else
						v.ent:SetColor( self.SelectionColor2 )
					end
				end
			end
		end
	end
end

if CLIENT then
	SCHEMES = {}
	list.Add( "OverrideMaterials", "none" )

	local function RemoveTable( index )
		table.remove(SCHEMES, index)
	end
	
	net.Receive( "SCHEMES_update", function( len )
		local index = net.ReadFloat()
		SCHEMES[index] = net.ReadTable()
	end )
	
	net.Receive( "SCHEMES_clear", function( len )
		SCHEMES = net.ReadTable()
	end )
	
	usermessage.Hook( "SCHEMES_updateindex", function( data)
		RunConsoleCommand(SMPA.."_index", data:ReadFloat())
	end)
	
	usermessage.Hook( "SCHEMES_propsupdate", function( data )
		local index = data:ReadFloat()
		local props = data:ReadFloat()
		if not SCHEMES[index] then return end
		--if not SCHEMES[index].Props then RemoveTable( index ) return end
		SCHEMES[index].Props = props or 0
	end)
	

	usermessage.Hook( "SCHEMES_removetable", function( data )
		local index = data:ReadFloat()
		RemoveTable( index )
	end)

	
	function TOOL.BuildCPanel( pnl )
		include( "weapons/gmod_tool/stools/"..SMPA.."/ui.lua" )
	end
	
	local BuildCPanel = TOOL.BuildCPanel
	local function reloadui_func()
		local CPanel = controlpanel.Get( SMPA )
		CPanel:Clear()
		
		BuildCPanel( CPanel )
	end
	
	--concommand.Add(SMPA.."_refresh", function()
		--reloadui_func()
	--end)
	
	surface.CreateFont ("SMPAFontMat", {font="Arial", size=30, weight=1000})
	surface.CreateFont ("SMPAFontCol", {font="Arial", size=31, weight=1000})
	surface.CreateFont ("SMPATitleFont", {font="Arial", size=40, weight=1000})
	
	// Taken from Garry's tool code
	local function DrawScrollingText( text, y, texwide )
		local w, h = surface.GetTextSize( text  )
		w = w + 64
		
		local x = math.fmod( CurTime() * 150, w ) * -1
		
		while ( x < texwide ) do
			surface.SetTextColor( 0, 0, 0, 255 )
			surface.SetTextPos( x + 5, y + 5 )
			surface.DrawText( text )
			
			surface.SetTextColor( 255, 255, 255, 255 )
			surface.SetTextPos( x, y )
			surface.DrawText( text )
			
			x = x + w
		end
	end
		
	function TOOL:DrawToolScreen()
		if(not SMPA)then return true end
		
		local Col = Color(self:GetClientNumber("colr"), self:GetClientNumber("colg"), self:GetClientNumber("colb"), 255 )
		local ColString = "r: "..Col.r.." g:"..Col.g.." b:"..Col.b.." a:"..self:GetClientNumber("cola")
		local MatString = self:GetClientInfo("material")
		local Mat = surface.GetTextureID( MatString )
		
		cam.Start2D()
			surface.SetTexture(Mat)
			surface.SetDrawColor(Col)
			surface.DrawRect(0, 0, 256, 256)
			if (Col.r>200 and Col.b>200 and Col.g>200) or Col.g>200 then
				surface.SetTextColor( 0, 0, 0, 255 )
			else
				surface.SetTextColor( 255, 255, 55, 255 )
			end
			draw.SimpleText("Smart Painter", "SMPATitleFont", 128, 50, Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
			draw.SimpleText(ColString, "SMPAFontCol", 10, 160, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT)
			surface.SetFont( "SMPAFontMat" )
			DrawScrollingText( MatString, 128, 256 )
		cam.End2D()
	end
end

if SERVER then
	net.Receive( "SCHEMES_paint", function( len, Ply)
		
		if not Ply or not IsValid(Ply) then return end
		local SelectedProps = Ply:GetWeapon( "gmod_tool" ):GetToolObject( SMPA ).SelectedProps
		local What = net.ReadFloat()
		local TarIndex = net.ReadFloat()
		local TarMaterial = net.ReadString() or Ply:GetInfo(SMPA.."_material")
		local TarColor = Color(Ply:GetInfo(SMPA.."_colr") or 255,Ply:GetInfo(SMPA.."_colg") or 255,Ply:GetInfo(SMPA.."_colb") or 255,Ply:GetInfo(SMPA.."_cola") or 255) 

		for k,v in pairs (SelectedProps) do
			if IsValid(v.ent) and v.ent != NULL then
				local Index = v.index
				if Index == TarIndex then
					if What == 2 then
						v.ent:SetMaterial(TarMaterial)
						v.mat = TarMaterial
					else
						v.col = (TarColor)
					end
				end
			end
		end
	end )
end