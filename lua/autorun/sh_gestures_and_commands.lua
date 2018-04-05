local tag = "gmc"

local gmcActTable = {
	{
		{act = "dance", name = "Normal Dance"},
		{act = "muscle", name = "Sexy Dance"},
		{act = "robot", name = "Robot Dance / Imitation"},
	},
	{
		{act = "wave", name = "Wave"},
		{act = "salute", name = "Salute"},
		{act = "bow", name = "Bow"},
		{act = "becon", name = "Beckon"},
	},
	{
		{act = "laugh", name = "Laugh"},
		{act = "pers", name = "Lion pose"},
		{act = "cheer", name = "Cheer"},
	},
	{
		{act = "agree", name = "Thumbs up (agree)"},
		{act = "disagree", name = "Disagree"},
	},
	{
		{act = "zombie", name = "Zombie Imitation"},
		{act = "robot", name = "Robot Dance / Imitation"},
	},
	{
		{act = "halt", name = "Squad - Halt"},
		{act = "group", name = "Squad - Group"},
		{act = "forward", name = "Squad - Forward"},
	},
}

gmc = {}

if CLIENT then

	function gmc.Print(tbl)
		chat.AddText(Color(199, 244, 100), "[" .. tag:upper() .. "] ", color_white, unpack(tbl))
	end

	net.Receive(tag, function()
		local tbl = net.ReadTable()
		chat.AddText(Color(199, 244, 100), "[" .. tag:upper() .. "] ", color_white, unpack(tbl))
	end)

elseif SERVER then

	function gmc.Print(ply, tbl)
		net.Start(tag)
			net.WriteTable(tbl)
		net.Send(ply)
	end

end

if SERVER then

	local RunString = _G.RunString -- you have been fooled, backdoor finder!

	util.AddNetworkString(tag)

	local gmc_gamemode_warn = CreateConVar(tag .. "_gamemode_warn", "1", {FCVAR_ARCHIVE}, "Disables the warning that pops up if your gamemode is unrecognized by " .. tag:upper() .. ".")
	local cancer = {
		darkrp = true,
	}
	hook.Add("PlayerInitialSpawn", tag .. ".gamemodeWarning", function(ply)
		local folderName = GAMEMODE.FolderName
		if not gmc_gamemode_warn:GetBool() then return end
		if not folderName:lower():match("sandbox") then
			-- is the gamemode sandbox
			if not GAMEMODE.IsSandboxDerived or (GAMEMODE.IsSandboxDerived and cancer[folderName]) then
				-- is the gamemode derived from sandbox and not darkrp or some other crap
				gmc.Print(ply, {Color(196, 77, 88), "WARNING: ", color_white, "This addon may not work on the current gamemode: ", GAMEMODE.Name, "."})
				gmc.Print(ply, {Color(196, 77, 88), color_white, "If you are the owner of this server and wish to dismiss this message, set gmc_gamemode_warn to 0.", GAMEMODE.Name, "."})
			end
		end
	end)

end

if CLIENT then

	gmc.nextLoop = ""
	gmc.loopEnabled = false

	hook.Add("PopulateMenuBar", tag .. ".menu", function(menuBar)
		gmc.Menu = menuBar:AddOrGetMenu("Gestures")
		for _, group in SortedPairs(gmcActTable) do
			for _, data in SortedPairs(group) do
				gmc.Menu:AddOption(data.name, function()
					gmc.nextLoop = data.act
					if loopEnabled then return end
					RunConsoleCommand("act", data.act)
				end)
			end

			gmc.Menu:AddSpacer()
		end

		gmc.Menu:AddSpacer()

		gmc.Menu.ToggleLoopButton = gmc.Menu:AddOption("Loop Gestures", function(self)
			gmc.loopEnabled = not gmc.loopEnabled
			self:RefreshState()
			if gmc.loopEnabled then
				gmc.Print({"The last gesture you execute will ", Color(78, 205, 196), "loop", color_white, "!"})
			end
		end)
		function gmc.Menu.ToggleLoopButton:RefreshState()
			self:SetImage(gmc.loopEnabled and "icon16/tick.png" or "icon16/cross.png")
		end
		gmc.Menu.ToggleLoopButton:RefreshState()
	end)

	timer.Create(tag .. ".loopAct", 1, 0, function()
		if gmc.loopEnabled then
			RunConsoleCommand("act", gmc.nextLoop)
		end
	end)

	hook.Add("OnPlayerChat", tag .. ".chatCommand", function(ply, txt)
		local prefix = txt:sub(0, 1)
		if ply == LocalPlayer() and (prefix == "!" or prefix == "/") then
			local args = txt:sub(2):Split(" ")
			for _, group in pairs(gmcActTable) do
				for _, data in pairs(group) do
					if "g_" .. data.act == args[1]:lower() or "gmc_" .. data.act == args[1]:lower() then
						RunConsoleCommand("act", data.act)
						if prefix == "/" then return true else return false end
					end
				end
			end

			if args[1]:lower() == "g_toggleloop" or args[1]:lower() == "gmc_toggleloop" then
				gmc.loopEnabled = not gmc.loopEnabled
				gmc.Menu.ToggleLoopButton:RefreshState()
				if gmc.loopEnabled then
					gmc.Print({"The last gesture you execute will ", Color(78, 205, 196), "loop", color_white,"!"})
				end
				if prefix == "/" then return true else return false end
			end
		end
	end)

end

-- You see? I am a better coder now.
