TOOL.Category = "Construction"
TOOL.Name = "#tool.smart_freezer.name"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
	language.Add( 'tool.smart_freezer.name', 'Smart Freezer' )
	language.Add( 'tool.smart_freezer.desc', 'Freezes or unfreezes whole contraptions.' )
	language.Add( 'tool.smart_freezer.0', 'Left-Click: Freeze  Right-Click: Unfreeze' )
end

local function SmartFreeze( tbl, motion )
	for k, v in pairs( tbl ) do
		if v:IsValid() then
			-- Freeze/Unfreeze
			local phys = v:GetPhysicsObject()
			if phys:IsValid() then
				phys:EnableMotion( motion )
				
				-- Wake the physics object if unfreezing
				if motion then 
					phys:Wake()
				end
				
				-- Make cool sparkly effects
				local ed = EffectData()
				ed:SetEntity( v )
				util.Effect( "entity_remove", ed, true, true )
			end
		end
	end
end

function TOOL:LeftClick( tr )
	if CLIENT then return end
	
	if tr.HitNonWorld and tr.Entity:IsValid() then --humm we got somthin
		local attached = constraint.GetAllConstrainedEntities( tr.Entity )
		SmartFreeze( attached, false )
		return true
	end
	return false
end

function TOOL:RightClick( tr )
	if CLIENT then return end
	
	if tr.HitNonWorld and tr.Entity:IsValid() then --humm we got somthin
		local attached = constraint.GetAllConstrainedEntities( tr.Entity )
		SmartFreeze( attached, true )
		return true
	end
	return false
end