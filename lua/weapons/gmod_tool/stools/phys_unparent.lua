TOOL.Category = "Constraints"
TOOL.Name = "Physical Unparent"

if CLIENT then
	language.Add("tool.phys_unparent.name", "Physical Unparent")
	language.Add("tool.phys_unparent.desc", "Unparents objects")
	language.Add("tool.phys_unparent.0", "Primary: select (hold use for area). Secondary: unparent. Reload: clear")
else
	PhysUnparentTable = {}
	function PhysUnparentTable.OwnershipTest(Player, Entity)
		if g_SBoxObjects[Player:UniqueID()] == nil then return false end
		for k, v in pairs(g_SBoxObjects[Player:UniqueID()]) do
			for k2, v2 in pairs(v) do
				if v2 == Entity then return true end
			end
		end
		return false
	end
	function PhysUnparentTable.BasicCheck(SteamID)
		if PhysUnparentTable[SteamID] == nil then
			PhysUnparentTable[SteamID] = {}
			PhysUnparentTable[SteamID]["radius"] = 300
			PhysUnparentTable[SteamID]["selected"] = {}
		end
	end
	util.AddNetworkString("phys_unparent_radius")
	util.AddNetworkString("phys_unparent_clientselect")
	util.AddNetworkString("phys_unparent_serverselect")
	net.Receive("phys_unparent_radius",function(len, ply)
		PhysUnparentTable.BasicCheck(ply:SteamID())
		PhysUnparentTable[ply:SteamID()]["radius"] = net.ReadInt(32)
	end)
	net.Receive("phys_unparent_serverselect",function(len, ply)
		local SteamID = ply:SteamID()
		local selection = net.ReadTable()
		local usekey = net.ReadBool()
		local i = 1
		while true do
			if selection[i] == nil then break end
			local flag = false
			local root = false
			if PhysParentTable ~= nil and PhysParentTable[SteamID] ~= nil then
				for x = 1,#PhysParentTable[SteamID]["physparents"] do
					if root or flag then break end
					for y = 1,#PhysParentTable[SteamID]["physparents"][x] do
						if PhysParentTable[SteamID]["physparents"][x][y] == selection[i] then
							if y == 1 then
								root = true
								break
							else
								flag = true
								break
							end
						end
					end
				end
			end
			--
			if IsValid(selection[i]) then
				if root == false and not IsValid(selection[i]:GetParent()) then flag = true end
			end
			if not IsValid(selection[i]) or selection[i]:IsPlayer() or PhysUnparentTable.OwnershipTest(ply, selection[i]) == false or flag then
				table.remove(selection,i)
			else
				i = i + 1
			end
		end
		if PhysParentTable ~= nil and PhysParentTable[SteamID] ~= nil then
			for i = 1,#selection do
				for x = 1,#PhysParentTable[SteamID]["physparents"] do
					if PhysParentTable[SteamID]["physparents"][x][1] == selection[i] then
						for y = 2,#PhysParentTable[SteamID]["physparents"][x] do
							selection[#selection+1] = PhysParentTable[SteamID]["physparents"][x][y]
						end
					end
				end
			end
		end
		local i = 1
		while true do
			local found = false
			if selection[i] == nil then break end
			for x = 1,#PhysUnparentTable[SteamID]["selected"] do
				if PhysUnparentTable[SteamID]["selected"][x][1] == selection[i] then
					found = true
					local ent = selection[i]
					table.remove(selection,i) 
					if not usekey then
						usekey = true
						ent:SetColor(PhysUnparentTable[SteamID]["selected"][x][2])
						ent:SetMaterial(PhysUnparentTable[SteamID]["selected"][x][3])
						table.remove(PhysUnparentTable[SteamID]["selected"],x)
						if PhysParentTable ~= nil and PhysParentTable[SteamID] ~= nil then
							for y = 1,#PhysParentTable[SteamID]["physparents"] do
								if PhysParentTable[SteamID]["physparents"][y][1] == ent then
									i = 1
									for z = 2,#PhysParentTable[SteamID]["physparents"][y] do
										for d = 1,#PhysUnparentTable[SteamID]["selected"] do
											if PhysUnparentTable[SteamID]["selected"][d][1] == PhysParentTable[SteamID]["physparents"][y][z] then
												PhysUnparentTable[SteamID]["selected"][d][1]:SetColor(PhysUnparentTable[SteamID]["selected"][d][2])
												PhysUnparentTable[SteamID]["selected"][d][1]:SetMaterial(PhysUnparentTable[SteamID]["selected"][d][3])
												table.remove(PhysUnparentTable[SteamID]["selected"],d)
												break
											end
										end
										for d = 1,#selection do
											if selection[d] == PhysParentTable[SteamID]["physparents"][y][z] then
												table.remove(selection,d)
												break
											end
										end
									end
								end
							end
						end
						
					end
					break
				end
			end
			if not found then i = i + 1 end
		end
		for i = 1,#selection do
			if IsValid(selection[i]) then
			PhysUnparentTable[SteamID]["selected"][#PhysUnparentTable[SteamID]["selected"]+1] = {selection[i], selection[i]:GetColor(), selection[i]:GetMaterial()}
			selection[i]:SetColor(Color(255,0,0,128))
			selection[i]:SetMaterial("models/debug/debugwhite")
			selection[i]:SetRenderMode(RENDERMODE_TRANSALPHA)
			end
		end
		
	end)
	function PhysUnparentTable.SelectionCleanup(SteamID)
		while true do
			local found = false
			for i = 1,#PhysUnparentTable[SteamID]["selected"] do
				if not IsValid(PhysUnparentTable[SteamID]["selected"][i][1]) then
					table.remove(PhysUnparentTable[SteamID]["selected"],i)
					found = true
					break
				end
			end
			if not found then break end
		end
	end
end

if CLIENT then
	net.Receive("phys_unparent_clientselect",function(len, ply)
		local selection = {}
		local svent = net.ReadEntity()
		local radius = net.ReadInt(32)
		local tr = util.TraceLine( util.GetPlayerTrace( LocalPlayer() ) )
		if LocalPlayer():KeyDown(IN_USE) then
			selection = ents.FindInSphere(tr.HitPos, radius)
		else
			if IsValid(tr.Entity) then
				selection[1] = tr.Entity
			else
				if IsValid(svent) then
					selection[1] = svent
				else
					return
				end
			end
		end
		if #selection > 0 then
			net.Start("phys_unparent_serverselect")
			net.WriteTable(selection)
			net.WriteBool(LocalPlayer():KeyDown(IN_USE))
			net.SendToServer()
		end
	end)
end

function TOOL:LeftClick(trace)
	if CLIENT then return true end
	local SteamID = self:GetOwner():SteamID()
	PhysUnparentTable.BasicCheck(SteamID)
	PhysUnparentTable.SelectionCleanup(SteamID)
	net.Start("phys_unparent_clientselect") net.WriteEntity(trace.Entity) net.WriteInt(PhysUnparentTable[SteamID]["radius"],32) net.Send(self:GetOwner())
	return true
end




function TOOL:RightClick(trace) 
	if CLIENT then return true end
	local SteamID = self:GetOwner():SteamID()
	PhysUnparentTable.BasicCheck(SteamID)
	PhysUnparentTable.SelectionCleanup(SteamID)
	for i = 1,#PhysUnparentTable[SteamID]["selected"] do
		local ptr = PhysUnparentTable[SteamID]["selected"][i]
		if IsValid(ptr[1]) then
			ptr[1]:SetColor(ptr[2])
			ptr[1]:SetMaterial(ptr[3])
		end
	end
	for i = 1,#PhysUnparentTable[SteamID]["selected"] do
		local ent = PhysUnparentTable[SteamID]["selected"][i][1]
		ent:SetParent(nil)
		local baseent = false
		if PhysParentTable ~= nil and PhysParentTable[SteamID] ~= nil then
			for x = 1,#PhysParentTable[SteamID]["physparents"] do
				if PhysParentTable[SteamID]["physparents"][x][1] == ent then
					baseent = true
					local name = "physparent_clonedelay"..PhysParentTable.UniqueNum PhysParentTable.UniqueNum = PhysParentTable.UniqueNum + 1
					timer.Create(name,0.1,1,function()
						local oldIndex = ent:EntIndex()
						local oldConstraints = constraint.GetTable(ent)
						local clone = PhysParentTable.CloneEntity(ent, self:GetOwner())
						PhysParentTable.RecreateConstraints(oldConstraints,oldIndex,clone:EntIndex())
					end)
					table.remove(PhysParentTable[SteamID]["physparents"],x)
					break
				end
			end
		end
		if IsValid(ent) then
			if not baseent then
				ent:SetNotSolid(false)
				ent:PhysicsInit(SOLID_VPHYSICS) 
			end
			ent:GetPhysicsObject():EnableMotion(false)
			duplicator.ClearEntityModifier(ent,"physparent")
		end
	end

	table.Empty(PhysUnparentTable[SteamID]["selected"])

	return true
end

function TOOL:Reload(trace) 
	if CLIENT then return true end
	local SteamID = self:GetOwner():SteamID()
	PhysUnparentTable.BasicCheck(SteamID)
	for i = 1,#PhysUnparentTable[SteamID]["selected"] do
		local ptr = PhysUnparentTable[SteamID]["selected"][i]
		if IsValid(ptr[1]) then
			ptr[1]:SetColor(ptr[2])
			ptr[1]:SetMaterial(ptr[3])
		end
	end
	table.Empty(PhysUnparentTable[SteamID]["selected"])
	return true
end


function TOOL.BuildCPanel(CPanel)
	local Slider = vgui.Create("DNumSlider")
	Slider:SetDark(true)
	Slider:SetText("Area selection radius")
	Slider:SetMin(1)
	Slider:SetMax(1000)
	Slider:SetDecimals(0)
	Slider:SetValue(300)
	Slider.OnValueChanged = function()  net.Start("phys_unparent_radius") net.WriteInt(Slider:GetValue(),32) net.SendToServer()  end
	CPanel:SetName("Physical Unparent V1.02")
	CPanel:AddItem(Slider)
end