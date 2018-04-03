if SERVER then return end

local SMPA = "smartpainter"

local CPanel = controlpanel.Get( SMPA )

local CPanel_Width
if ScrH() < 1050 then
	CPanel_Width = 281 --265
else
	CPanel_Width = 297 --281
end

local function SetColor()
	local Index = GetConVarNumber(SMPA.."_index")
	if Index and SCHEMES[Index] and SCHEMES[Index].Props > 0 then
		local Col = Color(GetConVarNumber(SMPA.."_colr"), GetConVarNumber(SMPA.."_colg"), GetConVarNumber(SMPA.."_colb"), GetConVarNumber(SMPA.."_cola"))
		net.Start("SCHEMES_paint")
			net.WriteFloat(1)
			net.WriteFloat(Index)
		net.SendToServer()
						
		SCHEMES[Index].col = Col
		CPanel.scheme_selector:RefreshOne(Index, _, Col)
	end
end

local function SetMaterial( material )
	RunConsoleCommand( SMPA.."_material", material )
	local Index = GetConVarNumber(SMPA.."_index")
	if Index and SCHEMES[Index] and SCHEMES[Index].Props > 0 then
		net.Start("SCHEMES_paint")
			net.WriteFloat(2)
			net.WriteFloat(Index)
			net.WriteString(material)
		net.SendToServer()
				
		SCHEMES[Index].mat = material
		CPanel.scheme_selector:RefreshOne(Index, material)
	end
end

----------------------
--SCHEME SELECTOR
----------------------

local function HighlightedButtonPaint( self )

    surface.SetDrawColor( 255, 200, 0, 255 )
    
    for i=2, 3 do
        surface.DrawOutlinedRect( i, i, self:GetWide()-i*2, self:GetTall()-i*2 )
    end

end

local function UnselectedButtonPaint( self )

    surface.SetDrawColor( 0, 0, 0, 255 )
    
    for i=2, 3 do
        surface.DrawOutlinedRect( i, i, self:GetWide()-i*2, self:GetTall()-i*2 )
    end

end

local SCHEME_SELECTOR = {}

AccessorFunc( SCHEME_SELECTOR, "ItemWidth",            "ItemWidth",     FORCE_NUMBER )
AccessorFunc( SCHEME_SELECTOR, "ItemHeight",            "ItemHeight",     FORCE_NUMBER )
AccessorFunc( SCHEME_SELECTOR, "Height",                "NumRows",         FORCE_NUMBER )
AccessorFunc( SCHEME_SELECTOR, "m_bSizeToContent",    "AutoHeight",     FORCE_BOOL )

function SCHEME_SELECTOR:Init()
	self.List = vgui.Create( "DPanelList", self )
        self.List:EnableHorizontal( true )
        self.List:EnableVerticalScrollbar()
        self.List:SetSpacing( 0 )
        self.List:SetPadding( 5 )
    
    self.Controls   = {}
    self.Height     = 2
	self.ConVar		= SMPA.."_index"
	
	self:SetItemWidth( 64 )
    self:SetItemHeight( 64 )

end

function SCHEME_SELECTOR:SetAutoHeight( bAutoHeight )

    self.m_bSizeToContent = bAutoHeight
    self.List:SetAutoSize( bAutoHeight )
    
    self:InvalidateLayout()

end

function SCHEME_SELECTOR:AddMaterial( props, material, color, index )
    -- Creeate a spawnicon and set the model
    local Scheme = vgui.Create( "DImageButton", self )
	if material == "none" or not material then 
		Scheme:SetOnViewMaterial( "models/debug/debugwhite", "models/wireframe" )
	else
		Scheme:SetOnViewMaterial( material, "models/wireframe" )
	end
    Scheme.AutoSize = false
	Scheme:SetColor( Color(color.r, color.g, color.b, 255) )
    Scheme.Value = index
    Scheme:SetSize( self.ItemWidth, self.ItemHeight )
    Scheme:SetToolTip( "material: "..material.."\nred:"..color.r..", green:"..color.g..", blue: "..color.b..", alpha: "..color.a.."\nprops: "..props )
    
	local SelectedScheme = GetConVarNumber(self.ConVar)
	if index != SelectedScheme then Scheme.PaintOver = UnselectedButtonPaint;
	else Scheme.PaintOver = HighlightedButtonPaint; end
    -- Run a console command when the Icon is clicked
    Scheme.DoClick = function ( button ) 
                        RunConsoleCommand( SMPA.."_material", material )
						RunConsoleCommand( SMPA.."_colr", color.r )
						RunConsoleCommand( SMPA.."_colg", color.g )
						RunConsoleCommand( SMPA.."_colb", color.b )
						RunConsoleCommand( SMPA.."_cola", color.a )
						RunConsoleCommand( self.ConVar, index )
					end
	Scheme.DoRightClick = function ( self )
							self:OpenMenu()
						end
	Scheme.OpenMenu = function ( self )
						print("Menu")
						local menu = DermaMenu()
						menu:AddOption( "Copy Material", function()
							SetMaterial( material )
						end )
						menu:AddOption( "Copy Color", function() 
							RunConsoleCommand( SMPA.."_colr", color.r )
							RunConsoleCommand( SMPA.."_colg", color.g )
							RunConsoleCommand( SMPA.."_colb", color.b )
							RunConsoleCommand( SMPA.."_cola", color.a )
							SetColor()
						end )
						menu:AddOption( "Copy Both", function()
							RunConsoleCommand( SMPA.."_colr", color.r )
							RunConsoleCommand( SMPA.."_colg", color.g )
							RunConsoleCommand( SMPA.."_colb", color.b )
							RunConsoleCommand( SMPA.."_cola", color.a )
							SetMaterial( material )
							SetColor()
						end )
						menu:Open()
					end

    -- Add the Icon us
    self.List:AddItem( Scheme )
    table.insert( self.Controls, Scheme )
    
    self:InvalidateLayout()
end

function SCHEME_SELECTOR:SetItemSize( pnl )

    local w = self.ItemWidth
    if ( w < 1 ) then w = ( self:GetWide() - self.List:GetPadding()*2 ) * w end
    
    local h = self.ItemHeight
    if ( h < 1 ) then h = ( self:GetWide() - self.List:GetPadding()*2 ) * h end
    
    pnl:SetSize( w, h )

end

function SCHEME_SELECTOR:ClearAll()
	self.List:Clear()
end

function SCHEME_SELECTOR:ShowAll()
	self:ClearAll()
	self:SetAutoHeight( false )
	self:SetItemWidth( 64 ) 
	self:SetItemHeight( 64 )
	for k,v in pairs (SCHEMES) do
		self:AddMaterial( v.Props, v.mat, v.col, k )
	end
end

function SCHEME_SELECTOR:RefreshOne( index, material, color )
	for k, Scheme in pairs( self.Controls ) do
		if Scheme.Value == index then
			--Scheme:Refresh()
			if material then 
				Scheme:SetOnViewMaterial( material, "models/wireframe" )
			end
			if color then
				Scheme:SetColor( Color(color.r, color.g, color.b, 255) )
			end
		end
	end
end

function SCHEME_SELECTOR:PerformLayout()	
	self.List:SetPos( 0, 0 )
    
    if ( self.m_bSizeToContent ) then
    
        self.List:SetWide( self:GetWide() )
        self.List:InvalidateLayout( true )
        self:SetTall( self.List:GetTall() )
        
    return end
    
    local h = 64
    if ( h < 1 ) then h = ( self:GetWide() - self.List:GetPadding()*2 ) * h end
    
    local Height = (h * self.Height) + (self.List:GetPadding() * 2) + 1
    
    self.List:SetSize( self:GetWide(), Height )
    self:SetTall( Height + 5 )
end

function SCHEME_SELECTOR:ControlValues( kv )

    self.BaseClass.ControlValues( self, kv )
    
    self.Height = kv.height or 2
    
    -- Load the list of models from our keyvalues file
    if (kv.options) then
    
        for k, v in pairs( kv.options ) do
            self:AddMaterial( k, v )
        end
        
    end
    
    self.ItemWidth = kv.itemwidth or 32
    self.ItemHeight = kv.itemheight or 32
    
    for k, v in pairs( self.Controls ) do
        v:SetSize( self.ItemWidth, self.ItemHeight )
    end
    
    self:InvalidateLayout()

end

function SCHEME_SELECTOR:FindAndSelectMaterial( Value )

    self.CurrentValue = Value

    for k, Scheme in pairs( self.Controls ) do
    
        if ( Scheme.Value == Value ) then
        
            -- Remove the old overlay
            if ( self.SelectedMaterial ) then
                self.SelectedMaterial.PaintOver = UnselectedButtonPaint;
            end
            
            -- Add the overlay to this button
            Scheme.PaintOver = HighlightedButtonPaint;
            self.SelectedMaterial = Scheme

        end
    
    end

end

function SCHEME_SELECTOR:TestForChanges()

    local cvar = self.ConVar
    if (!cvar) then return end
    
    local Value = GetConVarNumber( cvar )
    
    if ( Value == self.CurrentValue ) then return end
    
    self:FindAndSelectMaterial( Value )

end


vgui.Register("SMPA_scheme_selector", SCHEME_SELECTOR, "ContextBase")

----------------------
--MATERIAL SELECTION
----------------------

local MAT_SELECT = {}

AccessorFunc( MAT_SELECT, "ItemWidth",            "ItemWidth",     FORCE_NUMBER )
AccessorFunc( MAT_SELECT, "ItemHeight",            "ItemHeight",     FORCE_NUMBER )
AccessorFunc( MAT_SELECT, "Height",                "NumRows",         FORCE_NUMBER )
AccessorFunc( MAT_SELECT, "m_bSizeToContent",    "AutoHeight",     FORCE_BOOL )

function MAT_SELECT:Init()

    -- A panellist is a panel that you shove other panels
    -- into and it makes a nice organised frame.
    self.List = vgui.Create( "DPanelList", self )
        self.List:EnableHorizontal( true )
        self.List:EnableVerticalScrollbar()
        self.List:SetSpacing( 0 )
        self.List:SetPadding( 5 )
    
    self.Controls     = {}
    self.Height        = 2
	self.ConVar = SMPA.."_material"
	
	self:SetItemWidth( 64 )
    self:SetItemHeight( 64 )

end

function MAT_SELECT:SetAutoHeight( bAutoHeight )

    self.m_bSizeToContent = bAutoHeight
    self.List:SetAutoSize( bAutoHeight )
    
    self:InvalidateLayout()

end

function MAT_SELECT:AddMaterial( label, value )

    -- Creeate a spawnicon and set the model
    local Mat = vgui.Create( "DImageButton", self )
    Mat:SetOnViewMaterial( value, "models/wireframe" )
    Mat.AutoSize = false
    Mat.Value = value
    Mat:SetSize( self.ItemWidth, self.ItemHeight )
    Mat:SetToolTip( value )
    
    -- Run a console command when the Icon is clicked
    Mat.DoClick =   function ( button ) 
                        SetMaterial( value )
                    end

    -- Add the Icon us
    self.List:AddItem( Mat )
    table.insert( self.Controls, Mat )
    
    self:InvalidateLayout()

end

function MAT_SELECT:SetItemSize( pnl )

    local w = self.ItemWidth
    if ( w < 1 ) then w = ( self:GetWide() - self.List:GetPadding()*2 ) * w end
    
    local h = self.ItemHeight
    if ( h < 1 ) then h = ( self:GetWide() - self.List:GetPadding()*2 ) * h end
    
    pnl:SetSize( w, h )

end

function MAT_SELECT:ControlValues( kv )

    self.BaseClass.ControlValues( self, kv )
    
    self.Height = kv.height or 2
    
    -- Load the list of models from our keyvalues file
    if (kv.options) then
    
        for k, v in pairs( kv.options ) do
            self:AddMaterial( k, v )
        end
        
    end
    
    self.ItemWidth = kv.itemwidth or 32
    self.ItemHeight = kv.itemheight or 32
    
    for k, v in pairs( self.Controls ) do
        v:SetSize( self.ItemWidth, self.ItemHeight )
    end
    
    self:InvalidateLayout()

end

function MAT_SELECT:PerformLayout()

    self.List:SetPos( 0, 0 )
    
    for k, v in pairs( self.List:GetItems() ) do
        self:SetItemSize( v )
    end
    
    if ( self.m_bSizeToContent ) then
    
        self.List:SetWide( self:GetWide() )
        self.List:InvalidateLayout( true )
        self:SetTall( self.List:GetTall() )
        
    return end
    
    local h = self.ItemHeight
    if ( h < 1 ) then h = ( self:GetWide() - self.List:GetPadding()*2 ) * h end
    
    local Height = (h * self.Height) + (self.List:GetPadding() * 2) + 1
    
    self.List:SetSize( self:GetWide(), Height )
    self:SetTall( Height + 5 )

end


function MAT_SELECT:FindAndSelectMaterial( Value )

    self.CurrentValue = Value

    for k, Mat in pairs( self.Controls ) do
    
        if ( Mat.Value == Value ) then
        
            -- Remove the old overlay
            if ( self.SelectedMaterial ) then
                self.SelectedMaterial.PaintOver = nil;
            end
            
            -- Add the overlay to this button
            Mat.PaintOver = HighlightedButtonPaint;
            self.SelectedMaterial = Mat

        end
    
    end

end

function MAT_SELECT:TestForChanges()

    local cvar = self.ConVar
    if (!cvar) then return end
    
    local Value = GetConVarString( cvar )
    
    if ( Value == self.CurrentValue ) then return end
    
    self:FindAndSelectMaterial( Value )

end

vgui.Register("SMPA_mat_select", MAT_SELECT, "ContextBase")

----------------------
--CPANEL
----------------------

CPanel:Clear()

-- TOGGLE ONLY PROPS
CPanel:AddControl( "Toggle", {
					Label = "Select only props",
					ToolTip = "Tool selects only props",
					Value = 1,
					Command = SMPA.."_onlyprops"
				})
				
-- TOGGLE DIFFERENCES
CPanel:AddControl( "Toggle", {
					Label = "Ignore slight differences in colors",
					ToolTip = "Slightly different colors are counted as the same",
					Value = 0,
					Command = SMPA.."_ignoredifferences"
				})
				
-- AREA SIZE
local slider_area_size = vgui.Create( "DNumSlider", self )
	slider_area_size:SetPos(0, 59)
	--slider_area_size.Label:SetSize( 80 )
	slider_area_size:SetText( "Area selection size:" )
	slider_area_size.Label:SetDark( true )
	slider_area_size:SetMinMax( 50, 500 )
	slider_area_size:SetDecimals( 1 )
	--slider_area_size.Slider:SetNotches( self.slider_area_size.Slider:GetWide() / 4 )
	slider_area_size:SetToolTip( "Change the size of the area selection" )
	slider_area_size:SetConVar( SMPA.."_selection_size" )
	CPanel:AddItem( slider_area_size )
				
-- DETECTED SCHEMES LABEL
local scheme_selector_label = vgui.Create( "DLabel" )
	scheme_selector_label:SetText( "Detected schemes: "..#SCHEMES )
	scheme_selector_label:SetTextColor( Color(0, 0, 0, 255) )
	CPanel:AddItem( scheme_selector_label )
	CPanel.scheme_selector_label = scheme_selector_label

-- DETECTED SCHEMES
local scheme_selector = vgui.Create( "SMPA_scheme_selector" )
	CPanel:AddPanel( scheme_selector )
	CPanel.scheme_selector = scheme_selector
				
hook.Add("SpawnMenuOpen","SMPA_SpawnMenuOpen",function()
	CPanel.scheme_selector_label:SetText( "Detected schemes: "..#SCHEMES )
	if SCHEMES and SCHEMES != {} then
		CPanel.scheme_selector:ShowAll()
	end
end)

-- MATERIAL: LABEL
local mat_selector_label = vgui.Create( "DLabel" )
	mat_selector_label:SetText( "Material:")
	mat_selector_label:SetTextColor( Color(0, 0, 0, 255) )
	CPanel:AddItem( mat_selector_label )

-- MATERIAL
local mat_selector = vgui.Create( "SMPA_mat_select" )
	mat_selector:SetConVar( strConVar )    
	mat_selector:SetAutoHeight( false )
	mat_selector:SetItemWidth( 64 ) 
	mat_selector:SetItemHeight( 64 )
        
    if ( list.Get( "OverrideMaterials" ) != nil ) then
        for k, v in pairs( list.Get( "OverrideMaterials" ) ) do
            mat_selector:AddMaterial( v, v )
        end
    end
    
CPanel:AddPanel( mat_selector )
CPanel.mat_selector = mat_selector

-- COLOR: LABEL
local col_selector_label = vgui.Create( "DLabel" )
	col_selector_label:SetText( "Color:")
	col_selector_label:SetTextColor( Color(0, 0, 0, 255) )
	CPanel:AddItem( col_selector_label )


-- COLOR MIXER
local colorpicker = vgui.Create( "DColorMixer" )
			colorpicker:SetConVarR( SMPA.."_colr" )
			colorpicker:SetConVarG( SMPA.."_colg" )
			colorpicker:SetConVarB( SMPA.."_colb" )
			colorpicker:SetConVarA( SMPA.."_cola" )
			function colorpicker:ValueChanged()
				SetColor()
			end
		CPanel:AddItem( colorpicker )