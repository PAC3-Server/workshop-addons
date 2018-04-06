TOOL.Category = "Constraints"
TOOL.Name = "Physical Parent"

if CLIENT then
	language.Add("tool.physparent.name", "Physical Parent")
	language.Add("tool.physparent.desc", "Parents objects while retaining collisions")
	language.Add("tool.physparent.0", "Primary: select (hold use for area). Secondary: parent to target. Reload: clear")
	language.Add("Undone_physparent", "Undone Physical Parent")
	CreateClientConVar("physparent_radius", "300", true, false)
	CreateClientConVar("physparent_normal", "false", true, false)
	CreateClientConVar("physparent_enhanced", "false", true, false)
	CreateClientConVar("physparent_shadows", "false", true, false)
	CreateClientConVar("physparent_constraints", "false", true, false)
	CreateClientConVar("physparent_weight", "false", true, false)
else
	CreateConVar("sbox_maxphysparents",50)
	PhysParentTable = {} 
	PhysParentTable.UniqueNum = 0
	PhysParentDupeTable = {}
	function PhysParentTable.dupeload(Player, Entity, Data)
		if Data["convexes"] ~= nil then
			SteamID = Player:SteamID()
			PhysParentTable.BasicCheck(SteamID)
			PhysParentTableCleanup(SteamID)
			local ptr = PhysParentTable[SteamID]["physparents"]
			local pos = #ptr+1
			ptr[pos] = {}
			ptr[pos][1] = Entity
			ptr[pos]["childcount"] = Data["childcount"]
			local limit = GetConVar("sbox_maxphysparents"):GetInt()
			PhysParentTable[SteamID]["dupecount"] = PhysParentTable[SteamID]["dupecount"] + Data["childcount"]
			if PhysParentTable[SteamID]["dupecount"] + PhysParentTable[SteamID]["count"] > limit then
				net.Start("physparent_notify") net.WriteString("Exceeding limit (sbox_maxphysparents)") net.Send(Player)
			else
				local tmp = nil
				if Data["mass"] ~= nil then
					tmp = ents.Create(Entity:GetClass())
					tmp:SetModel(Entity:GetModel())
					tmp:PhysicsInit(SOLID_VPHYSICS)
					if Entity:GetMaterial() == tmp:GetMaterial() then Entity:SetMaterial(Data["material"]) end
					local ec = Entity:GetColor()
					local tc = tmp:GetColor()
					if ec.r == tc.r and ec.g == tc.g and ec.b == tc.b and ec.a == tc.a then Entity:SetColor(Data["color"]) if Data["color"].a ~= 255 then Entity:SetRenderMode(RENDERMODE_TRANSALPHA) end end
				end
				local targetMass = Entity:GetPhysicsObject():GetMass()
				if Data["mass"] ~= nil then
					if targetMass == tmp:GetPhysicsObject():GetMass() then targetMass = Data["mass"] end
					tmp:Remove()
				end
				local targetMaterial = Entity:GetPhysicsObject():GetMaterial()
				Entity:PhysicsInitMultiConvex(Data["convexes"])
				if Data["enhanced"] == true then
					Entity:EnableCustomCollisions(true)
				end
				Entity:GetPhysicsObject():SetMass(targetMass)
				Entity:GetPhysicsObject():SetMaterial(targetMaterial)
				Entity:GetPhysicsObject():EnableDrag(false)
			end
		else 
			if Data["normal"] == nil then
				local SteamID = Player:SteamID()
				if PhysParentDupeTable[SteamID] == nil then
					PhysParentDupeTable[SteamID] = {}
				end
				local i = #PhysParentDupeTable[SteamID]+1
				PhysParentDupeTable[Player:SteamID()] [i] = Entity
			end
		end
		Entity:DrawShadow(not Data["shadows"])
		if Data["weight"] ~= nil then
			Entity:GetPhysicsObject():SetMass(0.1)
		end
	end
	duplicator.RegisterEntityModifier("physparent",PhysParentTable.dupeload)
	
	function PhysParentTable.OwnershipTest(Player, Entity)
		if g_SBoxObjects[Player:UniqueID()] == nil then return false end
		for k, v in pairs(g_SBoxObjects[Player:UniqueID()]) do
			for k2, v2 in pairs(v) do
				if v2 == Entity then return true end
			end
		end
		return false
	end
	function PhysParentTable.BasicCheck(SteamID)
		if PhysParentTable[SteamID] == nil then
			PhysParentTable[SteamID] = {}
			PhysParentTable[SteamID]["radius"] = 300
			PhysParentTable[SteamID]["enhanced"] = false
			PhysParentTable[SteamID]["shadows"] = false
			PhysParentTable[SteamID]["normal"] = false
			PhysParentTable[SteamID]["constraints"] = false
			PhysParentTable[SteamID]["weight"] = false
			PhysParentTable[SteamID]["selected"] = {}
			PhysParentTable[SteamID]["count"] = 0
			PhysParentTable[SteamID]["dupecount"] = 0
			PhysParentTable[SteamID]["physparents"] = {}
		end
	end
	function PhysParentTable.CloneEntity(Target, Player)
		if not IsValid(Target) then return nil end
		local clone = ents.Create(Target:GetClass())
		if not IsValid(clone) then return nil end
		clone:SetModel(Target:GetModel())
		clone:SetPos(Target:GetPos())
		clone:SetAngles(Target:GetAngles())
		clone:SetMaterial(Target:GetMaterial())
		clone:SetColor(Target:GetColor())
		clone:SetRenderMode(Target:GetRenderMode())
		clone:PhysicsInit(SOLID_VPHYSICS)
		clone:GetPhysicsObject():SetMass(Target:GetPhysicsObject():GetMass())
		clone:GetPhysicsObject():SetMaterial(Target:GetPhysicsObject():GetMaterial())
		clone:SetCollisionGroup(Target:GetCollisionGroup())
		clone:GetPhysicsObject():EnableMotion(false)
		
		local constrainedEnts = constraint.GetAllConstrainedEntities(Target)
		for k,v in pairs(constrainedEnts) do
			local physobj = v:GetPhysicsObject()
			if IsValid(physobj) then physobj:EnableMotion(false) end
		end
		
		local outputs = Target.Outputs
		if outputs ~= nil then
			if outputs["entity"] ~= nil and outputs["entity"]["Connected"] ~= nil then
				WireLib.CreateEntityOutput( Player, clone, {true} )
				local connected = table.Copy(outputs["entity"].Connected)
				for k,v in pairs(connected) do
					WireLib.Link_Start( "physparent_rewire", v.Entity, v.Entity:GetPos(), v.Name, "cable/cable2", Color(0,0,0), 0 )
					WireLib.Link_End( "physparent_rewire", clone, clone:GetPos(), "entity", Player )
					if v.Entity:GetClass() == "gmod_wire_expression2" then v.Entity:Reset() end
				end
			end
			if outputs["wirelink"] ~= nil and outputs["wirelink"]["Connected"] ~= nil then
				WireLib.CreateWirelinkOutput( Player, clone, {true} )
				for k,v in pairs(outputs["wirelink"].Connected) do
					WireLib.Link_Start( "physparent_rewire", v.Entity, v.Entity:GetPos(), v.Name, "cable/cable2", Color(0,0,0), 0 )
					WireLib.Link_End( "physparent_rewire", clone, clone:GetPos(), "wirelink", Player )
					if v.Entity:GetClass() == "gmod_wire_expression2" then v.Entity:Reset() end
				end
			end
		end

		constraintTable = constraint.GetTable(Target)
		for k,v in pairs(constraintTable) do
			if v.Type == "WireHydraulic" and v.MyCrtl ~= nil then
				local controller = Entity(v.MyCrtl)
				v.Constraint:DontDeleteOnRemove(controller)
				v.Ent1:DontDeleteOnRemove(controller)
				v.Ent2:DontDeleteOnRemove(controller)
			end
		end

		if CPPI ~= nil then
			clone:CPPISetOwner(Player)
		end
		for k, v in pairs(g_SBoxObjects[Player:UniqueID()]) do
			for k2, v2 in pairs(v) do
				if v2 == Target then g_SBoxObjects[Player:UniqueID()][k][k2] = clone end
				if IsValid(v2) then
					if v2:GetParent() == Target then v2:SetParent(clone) end
					Target:DontDeleteOnRemove(v2)
				end
			end
		end
		undo.ReplaceEntity(Target, clone)
		cleanup.ReplaceEntity(Target, clone)
		Target:Remove()
		return clone
	end
	function PhysParentTable.RecreateConstraint(Constraint, oldIndex, newIndex)
		local Factory = duplicator.ConstraintType[ Constraint.Type ]
		if ( !Factory ) then return end
		local Args = {}
		for k, Key in pairs( Factory.Args ) do
			local Val = Constraint[ Key ]
			for i=1, 6 do
				if ( Constraint.Entity[ i ] ) then
					if ( Key == "Ent"..i ) then
						if Constraint.Entity[ i ].Index == oldIndex then Constraint.Entity[ i ].Index = newIndex end
						Val = Entity( Constraint.Entity[ i ].Index )
						if ( Constraint.Entity[ i ].World ) then
							Val = game.GetWorld()
						end
					end
					if ( Key == "Bone" .. i ) then Val = Constraint.Entity[ i ].Bone or 0 end
					if ( Key == "LPos" .. i ) then Val = Constraint.Entity[ i ].LPos end
					if ( Key == "WPos" .. i ) then Val = Constraint.Entity[ i ].WPos end
					if ( Key == "Length" .. i ) then Val = Constraint.Entity[ i ].Length or 0 end
				end
			end
			if ( Val == nil ) then Val = false end
			table.insert( Args, Val )
		end
		local mycrtl = Args[13]
		if Constraint.Type == "WireHydraulic" then
			Args[13] = nil 
		end
		--
		local e1 = nil
		local e2 = nil
		local e1ang = nil
		local e1pos = nil
		local e2ang = nil
		local e2pos = nil
		if Constraint.Entity[1] ~= nil and Constraint.Entity[2] ~= nil and Constraint.BuildDupeInfo ~= nil then
			e1 = Entity(Constraint.Entity[1].Index)
			e2 = Entity(Constraint.Entity[2].Index)
			e1ang = e1:GetAngles()
			e1pos = e1:GetPos()
			e2ang = e2:GetAngles()
			e2pos = e2:GetPos()
			if not IsValid(e2:GetParent()) then
				e2:SetPos(e1pos - Constraint.BuildDupeInfo.EntityPos)
				e2:SetAngles(Constraint.BuildDupeInfo.Ent2Ang)
			end
			if not IsValid(e1:GetParent()) then e1:SetAngles(Constraint.BuildDupeInfo.Ent1Ang) end
			
		end
		--
		local const, rope = Factory.Func( unpack(Args) )
		--
		if e1 ~= nil then
			if not IsValid(e1:GetParent()) then
				e1:SetPos(e1pos)
				e1:SetAngles(e1ang)
			end
			if not IsValid(e2:GetParent()) then
				e2:SetPos(e2pos)
				e2:SetAngles(e2ang)
			end
		end
		if Constraint.BuildDupeInfo ~= nil then
			const:GetTable().BuildDupeInfo = Constraint.BuildDupeInfo
		end
		--
		if Constraint.Type == "WireHydraulic" and isnumber(mycrtl) then
			local controller = Entity(mycrtl)
			controller:SetConstraint(const)
			if rope then controller:SetRope(rope) end
			const:GetTable().MyCrtl = controller:EntIndex()
			if controller.Inputs.Length.Src ~= nil then
				controller:SetLength(controller.Inputs.Length.Value)
			end
		end
	end
	function PhysParentTable.RecreateConstraints(constraints, oldIndex, newIndex)
		for k,v in pairs(constraints) do
			PhysParentTable.RecreateConstraint(v, oldIndex, newIndex)
		end
	end
	util.AddNetworkString("physparent_radius")
	util.AddNetworkString("physparent_enhanced")
	util.AddNetworkString("physparent_shadows")
	util.AddNetworkString("physparent_normal")
	util.AddNetworkString("physparent_constraints")
	util.AddNetworkString("physparent_weight")
	util.AddNetworkString("physparent_notify")
	util.AddNetworkString("physparent_requestconfig")
	util.AddNetworkString("physparent_config")

	net.Receive("physparent_radius",function(len, ply)
		PhysParentTable.BasicCheck(ply:SteamID())
		PhysParentTable[ply:SteamID()]["radius"] = net.ReadInt(32)
	end)
	net.Receive("physparent_enhanced",function(len, ply)
		PhysParentTable.BasicCheck(ply:SteamID())
		PhysParentTable[ply:SteamID()]["enhanced"] = net.ReadBool()
	end)
	net.Receive("physparent_shadows",function(len, ply)
		PhysParentTable.BasicCheck(ply:SteamID())
		PhysParentTable[ply:SteamID()]["shadows"] = net.ReadBool()
	end)
	net.Receive("physparent_normal",function(len, ply)
		PhysParentTable.BasicCheck(ply:SteamID())
		PhysParentTable[ply:SteamID()]["normal"] = net.ReadBool()
	end)
	net.Receive("physparent_constraints",function(len, ply)
		PhysParentTable.BasicCheck(ply:SteamID())
		PhysParentTable[ply:SteamID()]["constraints"] = net.ReadBool()
	end)
	net.Receive("physparent_weight",function(len, ply)
		PhysParentTable.BasicCheck(ply:SteamID())
		PhysParentTable[ply:SteamID()]["weight"] = net.ReadBool()
	end)
	net.Receive("physparent_config",function(len, ply)
		local SteamID = ply:SteamID()
		PhysParentTable.BasicCheck(SteamID)
		PhysParentTable[SteamID]["radius"] = net.ReadInt(32)
		PhysParentTable[SteamID]["normal"] = net.ReadBool()
		PhysParentTable[SteamID]["enhanced"] = net.ReadBool()
		PhysParentTable[SteamID]["shadows"] = net.ReadBool()
		PhysParentTable[SteamID]["constraints"] = net.ReadBool()
		PhysParentTable[SteamID]["weight"] = net.ReadBool()
	end)
	function PhysParentTable.postdupe(TimedPasteData, TimedPasteDataCurrent)
		if not IsValid(TimedPasteData[TimedPasteDataCurrent].Player) then return end
		local SteamID = TimedPasteData[TimedPasteDataCurrent].Player:SteamID()
		PhysParentTable.BasicCheck(SteamID)
		PhysParentTableCleanup(SteamID)
		if PhysParentDupeTable[SteamID] ~= nil then
			local limit = GetConVar("sbox_maxphysparents"):GetInt()
			if PhysParentTable[SteamID]["dupecount"] + PhysParentTable[SteamID]["count"] > limit then
				for k,v in pairs(PhysParentTable[SteamID]["physparents"]) do
					if #v == 1 then
						v[1]:Remove()
					end
				end
			else
				for i = 1,#PhysParentDupeTable[SteamID] do
					PhysParentDupeTable[SteamID][i]:SetNotSolid(true)
					local found = false
					for k,v in pairs(PhysParentTable[SteamID]["physparents"]) do
						if v[1] == PhysParentDupeTable[SteamID][i]:GetParent() then
							v[#v+1] = PhysParentDupeTable[SteamID][i]
							found = true
							break
						end
					end
					if not found then 
						PhysParentDupeTable[SteamID][i]:Remove()
						net.Start("physparent_notify") net.WriteString("Duplication contains invalid physparents") net.Send(TimedPasteData[TimedPasteDataCurrent].Player)
					end
				end
			end
			if PhysParentDupeTable[SteamID] ~= nil then
				table.Empty(PhysParentDupeTable[SteamID])
			end
			PhysParentTable[SteamID]["dupecount"] = 0
			PhysParentTableCleanup(SteamID)
		end
		for i = 1,#PhysParentTable[SteamID]["physparents"] do
			local Group = PhysParentTable[SteamID]["physparents"][i]
			if Group["childcount"] ~= #Group-1 then
				net.Start("physparent_notify") net.WriteString("Duplication contains invalid physparents") net.Send(TimedPasteData[TimedPasteDataCurrent].Player)
				Group[1]:Remove()
			end
		end
		PhysParentTableCleanup(SteamID)
	end
	hook.Add("AdvDupe_FinishPasting","physparent_hook1",PhysParentTable.postdupe)
	function PhysParentTableCleanup(SteamID)
		local rebuild = {}
		local i = 1
		if PhysParentTable[SteamID] == nil or PhysParentTable[SteamID]["physparents"] == nil then return end
		for k,v in pairs(PhysParentTable[SteamID]["physparents"]) do
			if IsValid(v[1]) then
				rebuild[i] = {}
				table.CopyFromTo(PhysParentTable[SteamID]["physparents"][k],rebuild[i])
				i = i + 1
			end
		end
		table.CopyFromTo(rebuild,PhysParentTable[SteamID]["physparents"])
		local count = 0
		for i = 1,#rebuild do count = count + #rebuild[i] end
		PhysParentTable[SteamID]["count"] = count
		while true do
			local found = false
			for i = 1,#PhysParentTable[SteamID]["selected"] do
				if not IsValid(PhysParentTable[SteamID]["selected"][i][1]) then
					table.remove(PhysParentTable[SteamID]["selected"],i)
					found = true
					break
				end
			end
			if not found then break end
		end
	end
	hook.Add("PlayerInitialSpawn","physparent_hook2",function(ply)
		net.Start("physparent_requestconfig") net.WriteString(ply:SteamID()) net.Send(ply)
	end)
end

if CLIENT then
	PhysParentCanNotify = true
	net.Receive("physparent_notify",function(len, ply)
		local str = net.ReadString()
		if PhysParentCanNotify then
			surface.PlaySound("buttons/button10.wav")
			GAMEMODE:AddNotify(str,1,5)
			PhysParentCanNotify = false
			timer.Create("physparentnotifyreset",1,1,function() PhysParentCanNotify = true end)
		end
	end)
	net.Receive("physparent_requestconfig",function(len, ply)
		net.Start("physparent_config")
		net.WriteInt(GetConVar("physparent_radius"):GetInt(),32)
		net.WriteBool(GetConVar("physparent_normal"):GetBool())
		net.WriteBool(GetConVar("physparent_enhanced"):GetBool())
		net.WriteBool(GetConVar("physparent_shadows"):GetBool())
		net.WriteBool(GetConVar("physparent_constraints"):GetBool())
		net.WriteBool(GetConVar("physparent_weight"):GetBool())
		net.SendToServer()
	end)

	physparentcl_fontsCreated = false
	physparentcl_regular = GetConVar("physparent_normal"):GetBool()

	function TOOL:DrawToolScreen(width, height)
		if not fontsCreated then
			fontsCreated = true
			surface.CreateFont("physparent1",{
				font = "Calibri",
				extended = false,
				size = 64,
				weight = 1000,
				blursize = 0,
				scanlines = 0,
				antialias = true,
				underline = false,
				italic = false,
				strikeout = false,
				symbol = false,
				rotary = false,
				shadow = false,
				additive = false,
				outline = false
			})
		end
		surface.SetDrawColor(Color(20,20,20))
		surface.DrawRect(0,0,width,height)
		local fh = draw.GetFontHeight("physparent1")
		if physparentcl_regular then
			draw.DrawText( "Regular\nParent", "physparent1", width / 2, height / 2 - fh, Color( 0, 160, 255 ), TEXT_ALIGN_CENTER )
		else
			draw.DrawText( "Physical\nParent", "physparent1", width / 2, height / 2 - fh, Color( 0, 160, 255 ), TEXT_ALIGN_CENTER )
		end
		
	end
end
function TOOL:LeftClick(trace) 
	if CLIENT then return true end
	local SteamID = self:GetOwner():SteamID()
	PhysParentTable.BasicCheck(SteamID)
	PhysParentTableCleanup(SteamID)
	local selection = {}
	if self:GetOwner():KeyDown(IN_USE) then
		selection = ents.FindInSphere(trace.HitPos, PhysParentTable[SteamID]["radius"])
		local i = 1
		while true do
			if selection[i] == nil then break end
			if selection[i]:IsPlayer() or PhysParentTable.OwnershipTest(self:GetOwner(),selection[i]) == false or IsValid(selection[i]:GetPhysicsObject()) == false  or IsValid(selection[i]:GetParent()) or selection[i]:GetPhysicsObject():GetMeshConvexes() == null then
				table.remove(selection,i)
			else
				i = i + 1
			end
		end
	else
		if IsValid(trace.Entity) == false or trace.Entity:IsPlayer() or IsValid(trace.Entity:GetPhysicsObject()) == false or PhysParentTable.OwnershipTest(self:GetOwner(),trace.Entity) == false or trace.Entity:GetPhysicsObject():GetMeshConvexes() == null or IsValid(trace.Entity:GetParent()) then
			return false
		end
		selection[1] = trace.Entity
	end

	for i = 1,#selection do
		local found = false
		for j= 1,#PhysParentTable[SteamID]["physparents"] do
			if PhysParentTable[SteamID]["physparents"][j][1] == selection[i] then
				found = true
				break
			end
		end
		if not found then
			local count = #PhysParentTable[SteamID]["selected"]
			for j = 1,count do 
				if PhysParentTable[SteamID]["selected"][j][1] == selection[i] then
					if not self:GetOwner():KeyDown(IN_USE) then
						selection[i]:SetColor(PhysParentTable[SteamID]["selected"][j][2])
						selection[i]:SetMaterial(PhysParentTable[SteamID]["selected"][j][3])
						table.remove(PhysParentTable[SteamID]["selected"],j)
						return true
					end
					found = true 
					break
				end
			end
			if not found then
				PhysParentTable[SteamID]["selected"][count+1] = {selection[i], selection[i]:GetColor(), selection[i]:GetMaterial()}
				selection[i]:SetColor(Color(0,255,0,128))
				selection[i]:SetMaterial("models/debug/debugwhite")
				selection[i]:SetRenderMode(RENDERMODE_TRANSALPHA)
			end
		end
	end
	
	return true
end

function TOOL:RightClick(trace)
	if CLIENT then return true end
	local SteamID = self:GetOwner():SteamID()
	PhysParentTable.BasicCheck(SteamID)
	PhysParentTableCleanup(SteamID)
	if  IsValid(trace.Entity) == false or trace.Entity:IsPlayer()  or PhysParentTable.OwnershipTest(self:GetOwner(),trace.Entity) == false or IsValid(trace.Entity:GetPhysicsObject()) == false then
		return false
	end
	if PhysParentTable[SteamID]["normal"] == false then
		for i = 1,#PhysParentTable[SteamID]["physparents"] do
			if PhysParentTable[SteamID]["physparents"][i][1] ==trace.Entity then return false end
		end
		if trace.Entity:GetPhysicsObject():GetMeshConvexes() == null or trace.Entity:GetClass() == "prop_ragdoll" or trace.Entity:GetClass() == "prop_vehicle_jeep" then return false end
		local limit = GetConVar("sbox_maxphysparents"):GetInt()
		if PhysParentTable[SteamID]["count"] + #PhysParentTable[SteamID]["selected"] > limit then
			net.Start("physparent_notify") net.WriteString("Exceeding limit (sbox_maxphysparents)") net.Send(self:GetOwner())
			return false
		end
	end
	for i = 1,#PhysParentTable[SteamID]["selected"] do
		local ptr = PhysParentTable[SteamID]["selected"][i]
		if IsValid(ptr[1]) then
			ptr[1]:SetColor(ptr[2])
			ptr[1]:SetMaterial(ptr[3])
		end
	end
	if PhysParentTable[SteamID]["normal"] == false then
		local i = 1
		while true do
			if PhysParentTable[SteamID]["selected"][i] == nil then break end
			if string.sub(PhysParentTable[SteamID]["selected"][i][1]:GetClass(),1,7) == "weapon_" or string.sub(PhysParentTable[SteamID]["selected"][i][1]:GetClass(),1,5) == "item_" then
				table.remove(PhysParentTable[SteamID]["selected"],i)
			else
				i = i + 1
			end
		end
	end
	for i = 1,#PhysParentTable[SteamID]["selected"] do
		if PhysParentTable[SteamID]["selected"][i][1] == trace.Entity then
			table.remove(PhysParentTable[SteamID]["selected"],i)
			break
		end
	end
	if #PhysParentTable[SteamID]["selected"] == 0 then return false end
	if PhysParentTable[SteamID]["normal"] == true then
		for i = 1,#PhysParentTable[SteamID]["selected"] do
			local ptr = PhysParentTable[SteamID]["selected"][i]
			if PhysParentTable[SteamID]["constraints"] == true then
				constraint.RemoveAll(ptr[1])
			end
			if PhysParentTable[SteamID]["weight"] == true then
				ptr[1]:GetPhysicsObject():SetMass(0.1)
			end
			ptr[1]:SetParent(trace.Entity)
			ptr[1]:DrawShadow(not PhysParentTable[SteamID]["shadows"]) 
			local dupedata = {normal = true, shadows = PhysParentTable[SteamID]["shadows"], weight = PhysParentTable[SteamID]["weight"]}
			duplicator.StoreEntityModifier(ptr[1],"physparent",dupedata)
		end
		local dupedata = {normal = true, shadows = PhysParentTable[SteamID]["shadows"]}
		duplicator.StoreEntityModifier(trace.Entity,"physparent",dupedata)
		local undodata = {target = trace.Entity, ents = {}}
		table.CopyFromTo(PhysParentTable[SteamID]["selected"],undodata["ents"])
		undo.Create("physparent")
		undo.AddFunction(function(tab, arg2)
			for i = 1,#arg2["ents"] do
				if IsValid(arg2["ents"][i][1]) then
					arg2["ents"][i][1]:SetParent(nil)
					if IsValid( arg2["ents"][i][1]:GetPhysicsObject() ) then
						arg2["ents"][i][1]:GetPhysicsObject():EnableMotion(false)
					end
					duplicator.ClearEntityModifier(arg2["ents"][i][1],"physparent")
				end
			end
			duplicator.ClearEntityModifier(arg2["target"],"physparent")
		end,undodata)
		undo.SetPlayer(self:GetOwner())
		undo.Finish()
		table.Empty(PhysParentTable[SteamID]["selected"])
		return true
	end
	local masterconv = {}
	local targetConvexes = trace.Entity:GetPhysicsObject():GetMeshConvexes()
	local targetConvexesConv = {}
	local targetMass = trace.Entity:GetPhysicsObject():GetMass()
	local targetMaterial = trace.Entity:GetPhysicsObject():GetMaterial()
	for i = 1, #targetConvexes do
		local mcp = #masterconv+1
		masterconv[mcp] = {}
		for j = 1, #targetConvexes[i] do
			masterconv[mcp][#masterconv[mcp]+1] = targetConvexes[i][j]["pos"]
		end
	end
	table.CopyFromTo(masterconv,targetConvexesConv)
	for i = 1,#PhysParentTable[SteamID]["selected"] do
		local ent = PhysParentTable[SteamID]["selected"][i][1]
		local convexes = ent:GetPhysicsObject():GetMeshConvexes()
		local M = Matrix()
		M:Translate(trace.Entity:WorldToLocal(ent:GetPos()))
		M:Rotate(trace.Entity:WorldToLocalAngles(ent:GetAngles()))
		for j = 1, #convexes do
			local mcp = #masterconv+1
			masterconv[mcp] = {}
			for n = 1, #convexes[j] do
				masterconv[mcp][#masterconv[mcp]+1] = M*convexes[j][n]["pos"]
			end
		end
	end
	local oldIndex = trace.Entity:EntIndex()
	local oldConstraints = constraint.GetTable(trace.Entity)
	trace.Entity = PhysParentTable.CloneEntity(trace.Entity, self:GetOwner())
	trace.Entity:PhysicsInitMultiConvex(masterconv)
	if PhysParentTable[SteamID]["enhanced"] == true then
		trace.Entity:EnableCustomCollisions(true)
	end
	trace.Entity:GetPhysicsObject():EnableDrag(false)
	trace.Entity:GetPhysicsObject():SetMass(targetMass)
	trace.Entity:GetPhysicsObject():SetMaterial(targetMaterial)
	trace.Entity:GetPhysicsObject():EnableMotion(false)
	trace.Entity:DrawShadow(not PhysParentTable[SteamID]["shadows"])
	for i = 1,#PhysParentTable[SteamID]["selected"] do
		local ptr = PhysParentTable[SteamID]["selected"][i]
		if PhysParentTable[SteamID]["constraints"] == true then
			constraint.RemoveAll(ptr[1])
		end
		if PhysParentTable[SteamID]["weight"] == true then
			ptr[1]:GetPhysicsObject():SetMass(0.1)
		end
		ptr[1]:Extinguish()
		ptr[1]:SetParent(trace.Entity)
			ptr[1]:SetNotSolid(true) 
		ptr[1]:DrawShadow(not PhysParentTable[SteamID]["shadows"])
		local dupedata = {shadows = PhysParentTable[SteamID]["shadows"], weight = PhysParentTable[SteamID]["weight"]}
		duplicator.StoreEntityModifier(ptr[1],"physparent",dupedata)
	end
	PhysParentTable.RecreateConstraints(oldConstraints,oldIndex,trace.Entity:EntIndex())
	local undodata = {target = trace.Entity, targetconvex = targetConvexesConv, children = {}, player = self:GetOwner()}
	table.CopyFromTo(PhysParentTable[SteamID]["selected"],undodata["children"])
	undo.Create("physparent")
	undo.AddFunction(function(tab, arg2)
		if not IsValid(arg2["target"]) then return end
		local SteamID = arg2["player"]:SteamID()
		PhysParentTable.BasicCheck(SteamID)
		PhysParentTableCleanup(SteamID)
		for i = 1,#PhysParentTable[SteamID]["physparents"] do
			if PhysParentTable[SteamID]["physparents"][i][1] == arg2["target"] then
				table.remove(PhysParentTable[SteamID]["physparents"],i)
			end
		end
		if IsValid(arg2["target"]:GetPhysicsObject()) then arg2["target"]:GetPhysicsObject():EnableMotion(false) end
		for i = 1,#arg2["children"] do
			if IsValid(arg2["children"][i][1]) then
			duplicator.ClearEntityModifier(arg2["children"][i][1],"physparent")
			arg2["children"][i][1]:SetParent(nil)
			arg2["children"][i][1]:SetNotSolid(false)
			if IsValid( arg2["children"][i][1]:GetPhysicsObject() ) then
				arg2["children"][i][1]:GetPhysicsObject():EnableMotion(false)
			end
			end
		end
		local name = "physparent_clonedelay"..PhysParentTable.UniqueNum PhysParentTable.UniqueNum = PhysParentTable.UniqueNum + 1
		timer.Create(name,0.1,1,function()
			local oldIndex = arg2["target"]:EntIndex()
			local oldConstraints = constraint.GetTable(arg2["target"])
			local clone = PhysParentTable.CloneEntity(arg2["target"], arg2["player"]) 
			PhysParentTable.RecreateConstraints(oldConstraints,oldIndex,clone:EntIndex())
		end)
	end,undodata)
	undo.SetPlayer(self:GetOwner())
	undo.Finish()
	local dupedata = {enhanced = PhysParentTable[SteamID]["enhanced"],shadows = PhysParentTable[SteamID]["shadows"], convexes = masterconv, childcount = #PhysParentTable[SteamID]["selected"], mass = trace.Entity:GetPhysicsObject():GetMass(), material = trace.Entity:GetMaterial(), color = trace.Entity:GetColor()}
	duplicator.StoreEntityModifier(trace.Entity,"physparent",dupedata)
	local ptr = PhysParentTable[SteamID]["physparents"]
	local pos = #ptr+1
	ptr[pos] = {}
	ptr[pos][1] = trace.Entity
	ptr[pos]["childcount"] = #PhysParentTable[SteamID]["selected"]
	local ptr2 = PhysParentTable[SteamID]["selected"]
	for i = 1,#ptr2 do
		ptr[pos][i+1] = ptr2[i][1]
	end
	table.Empty(PhysParentTable[SteamID]["selected"])
	PhysParentTableCleanup(SteamID)
	return true
end

function TOOL:Reload(trace) 
	if CLIENT then return true end
	local SteamID = self:GetOwner():SteamID()
	PhysParentTable.BasicCheck(SteamID)
	for i = 1,#PhysParentTable[SteamID]["selected"] do
		local ptr = PhysParentTable[SteamID]["selected"][i]
		if IsValid(ptr[1]) then
			ptr[1]:SetColor(ptr[2])
			ptr[1]:SetMaterial(ptr[3])
		end
	end
	table.Empty(PhysParentTable[SteamID]["selected"])
	return true
end


function TOOL.BuildCPanel(CPanel)
	local Slider = vgui.Create("DNumSlider")
	Slider:SetDark(true)
	Slider:SetText("Area selection radius")
	Slider:SetMin(1)
	Slider:SetMax(1000)
	Slider:SetDecimals(0)
	Slider:SetValue(GetConVar("physparent_radius"):GetInt())
	Slider.OnValueChanged = function() GetConVar("physparent_radius"):SetInt(Slider:GetValue())  net.Start("physparent_radius") net.WriteInt(Slider:GetValue(),32) net.SendToServer()  end
	local Checkbox = vgui.Create("DCheckBoxLabel")
	Checkbox:SetText("Enhanced Collision")
	Checkbox:SetDark(true)
	Checkbox:SetEnabled(not GetConVar("physparent_normal"):GetBool())
	Checkbox:SetValue(GetConVar("physparent_enhanced"):GetBool())
	Checkbox.OnChange = function() net.Start("physparent_enhanced") GetConVar("physparent_enhanced"):SetBool(Checkbox:GetChecked()) net.WriteBool(Checkbox:GetChecked()) net.SendToServer() end
	local Checkbox2 = vgui.Create("DCheckBoxLabel")
	Checkbox2:SetText("Disable Shadows")
	Checkbox2:SetDark(true)
	Checkbox2:SetValue(GetConVar("physparent_shadows"):GetBool())
	Checkbox2.OnChange = function() net.Start("physparent_shadows") GetConVar("physparent_shadows"):SetBool(Checkbox2:GetChecked()) net.WriteBool(Checkbox2:GetChecked()) net.SendToServer() end
	local Checkbox3 = vgui.Create("DCheckBoxLabel")
	Checkbox3:SetText("Regular Parent")
	Checkbox3:SetDark(true)
	Checkbox3:SetValue(GetConVar("physparent_normal"):GetBool())
	Checkbox3.OnChange = function() physparentcl_regular = Checkbox3:GetChecked() GetConVar("physparent_normal"):SetBool(Checkbox3:GetChecked()) if Checkbox3:GetChecked() then Checkbox:SetEnabled(false) else  Checkbox:SetEnabled(true) end net.Start("physparent_normal") net.WriteBool(Checkbox3:GetChecked()) net.SendToServer() end
	local Checkbox4 = vgui.Create("DCheckBoxLabel")
	Checkbox4:SetText("Remove Constraints")
	Checkbox4:SetDark(true)
	Checkbox4:SetValue(GetConVar("physparent_constraints"):GetBool())
	Checkbox4.OnChange = function() GetConVar("physparent_constraints"):SetBool(Checkbox4:GetChecked()) net.Start("physparent_constraints") net.WriteBool(Checkbox4:GetChecked()) net.SendToServer() end
	local Checkbox5 = vgui.Create("DCheckBoxLabel")
	Checkbox5:SetText("Set Weight")
	Checkbox5:SetDark(true)
	Checkbox5:SetValue(GetConVar("physparent_weight"):GetBool())
	Checkbox5.OnChange = function() GetConVar("physparent_weight"):SetBool(Checkbox5:GetChecked()) net.Start("physparent_weight") net.WriteBool(Checkbox5:GetChecked()) net.SendToServer() end
	CPanel:SetName("Physical Parent V1.07.1")
	CPanel:AddItem(Slider)
	CPanel:AddItem(Checkbox3)
	CPanel:ControlHelp("It is recommended to use this for most of your props, since keeping collisions for all of them would be detrimental to performance. You must also use this if you want to keep interaction with entities such as seats and buttons")
	CPanel:AddItem(Checkbox)
	CPanel:ControlHelp("This will improve collisions with players and make it possible to physgun the parented props. If enabled, SmartSnap may not work.")
	CPanel:AddItem(Checkbox2)
	CPanel:ControlHelp("Recommended for improved performance.")
	CPanel:AddItem(Checkbox4)
	CPanel:ControlHelp("Removes constraints from parented props.")
	CPanel:AddItem(Checkbox5)
	CPanel:ControlHelp("The weight of parented props will be set to 0.1")
end