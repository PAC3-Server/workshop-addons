// This addon is authored and maintained by BFG9000.
// If you have any questions or concerns, I would prefer that you PM me at http://www.facepunch.com/member.php?u=404602
// or leave a comment on the workshop page of this add-on.

AddCSLuaFile()
SEAT_WEAPONISER_VERSION2 = true --gonna tie this variable in with the old workshop release so that it disables the old version


hook.Add("CanPlayerEnterVehicle", "BFG_WeaponSeats_PlayerWeaponEnabler", function(ply, vehicle, role)
	if ply:GetNWBool("SeatWeapon_Usage_Allowed", false) then
		ply:SetAllowWeaponsInVehicle(true)
	else
		ply:SetAllowWeaponsInVehicle(false)
	end
	
	if not ply.WeaponSeatsInfo_Shown then
		ply:SendLua([[chat.AddText(Color(0, 255, 50), "This server is using Seat Weaponiser! \n", Color(50, 255, 255), "Double-tap the context key (C by default) or bind a key to weaponseats_toggle to use it!")]])
		ply:SendLua([[chat.AddText(Color(255, 0, 0), "To toggle the in-seat crosshair, use the convar weaponseats_enablecrosshair 1 or 0.")]])
		ply.WeaponSeatsInfo_Shown = true
	end
end)


hook.Add("OnEntityCreated", "BFG_WeaponSeats_VehicleThink", function(entity) 
	if SERVER and entity:IsVehicle() then
		function entity:ResetPunchThink()
			//print("Let me think….")
			local driver = self:GetDriver()
			if IsValid(driver) then
			//	print(driver:GetAimVector():Angle())
			//	print(driver:EyeAngles())
				if driver:GetViewPunchAngles() != Angle(0,0,0) then
					driver:SetViewPunchAngles(driver:GetViewPunchAngles()*0.925)
				end
				--[[
				local eyeangles = driver:EyeAngles()
				if eyeangles.roll != driver:GetAngles().roll then
					local targetroll = driver:GetAngles().roll
					local rolldiff = math.NormalizeAngle(math.AngleDifference(targetroll, eyeangles.roll))
					local calcroll = (rolldiff * .9) + targetroll
					print(eyeangles.roll)
					print(calcroll)
					driver:SetEyeAngles(Angle(eyeangles.pitch, eyeangles.yaw, calcroll))
				end
				--]]
			end
		end
	end
	end)

local ents = ents
local function GetAllVehicles()
	local entities = ents.GetAll()
	local vehicles = {}
	for k,v in pairs(entities) do
		if IsValid(v) and v:IsVehicle() then
			table.ForceInsert( vehicles, v )
		end
	end
	return vehicles
end

hook.Add("Think", "BFG_WeaponSeats_Callback2", function()
	for k,v in pairs(GetAllVehicles()) do
		if IsValid(v) and v.ResetPunchThink then
			v:ResetPunchThink()
		end
	end
end)



// Compensation for differences between eye angles and aimvectors, and other detours
local PLAYER = FindMetaTable("Player")


if not PLAYER._BEyeAngles_WeaponSeatsBackup then
	//PLAYER._BEyeAngles_WeaponSeatsBackup = PLAYER.EyeAngles
	PLAYER._BEyeAngles_WeaponSeatsBackup = FindMetaTable("Entity").EyeAngles
end
function PLAYER:EyeAngles()
		if self:InVehicle() and self:GetNWBool("SeatWeapon_Usage_Allowed", false) then
			return self:GetAimVector():Angle()
		else
			return self:_BEyeAngles_WeaponSeatsBackup()
		end
end

if not PLAYER._BSetEyeAngles_WeaponSeats then
	PLAYER._BSetEyeAngles_WeaponSeats = PLAYER.SetEyeAngles
end
function PLAYER:SetEyeAngles(targetangle)
	if self:InVehicle() and self:GetNWBool("SeatWeapon_Usage_Allowed", false) then
		local calcangle = self:GetVehicle():WorldToLocalAngles(targetangle)
		self:_BSetEyeAngles_WeaponSeats(calcangle)
	else
		self:_BSetEyeAngles_WeaponSeats(targetangle)
	end
end
--[[
hook.Add("PlayerLeaveVehicle", "BFG_WeaponSeats_EyeAngleReset", function( ply, veh )
	local components = ply:GetEyeAngles()
	ply:SetEyeAngles(Angle(components.p, components.y, 0))
end)
]]--
if not PLAYER._BViewPunch_WeaponSeats then
	PLAYER._BViewPunch_WeaponSeats = PLAYER.ViewPunch
end
function PLAYER:ViewPunch(ang)
	if self:InVehicle() then
		self:SetViewPunchAngles(ang)
	else
		return self:_BViewPunch_WeaponSeats(ang)
	end
end



//



if SERVER then
util.AddNetworkString("WeaponSeats_ToggleCommand")

net.Receive("WeaponSeats_ToggleCommand", function(len, ply)
	ply:SetNWBool("SeatWeapon_Usage_Allowed", not ply:GetNWBool("SeatWeapon_Usage_Allowed", false))
	if ply:GetNWBool("SeatWeapon_Usage_Allowed", false) then
		--ply:ChatPrint("Seat weapons turned on.")
		ply:SendLua([[chat.AddText(Color(52, 152, 219), "Seat weapons turned on.")]])
		ply:SendLua([[surface.PlaySound("buttons/button14.wav")]])
	else
		ply:SendLua([[chat.AddText(Color(230, 126, 34),"Seat weapons turned off.")]])
		ply:SendLua([[surface.PlaySound("buttons/button2.wav")]])
	end
	if ply:InVehicle() then
		local vehicle = ply:GetVehicle()
		ply:ExitVehicle()
		ply:EnterVehicle(vehicle) 
	end
end)

hook.Add("EntityTakeDamage", "BFG_WeaponSeats_DamageFilter", function( target, dmginfo )
	if target:IsPlayer() and target:InVehicle() and target:GetNWBool("SeatWeapon_Usage_Allowed", false) then
		if (dmginfo:GetAttacker() == target) and (not dmginfo:IsExplosionDamage()) then
			dmginfo:ScaleDamage(0)
		end
	end
end)



end -- if SERVER then




if CLIENT then

CreateClientConVar("weaponseats_enablecrosshair", "1", true)

hook.Add("HUDPaint", "BFG_WeaponSeats_HUDElement", function()
	local ply = LocalPlayer()
	if ply:InVehicle() and ply:GetNWBool("SeatWeapon_Usage_Allowed", false) and GetConVar("weaponseats_enablecrosshair"):GetBool() then
		local aimtrace = ply:GetEyeTrace()
		local center = aimtrace.HitPos:ToScreen()
		local radius = math.max( ScrH()/150, ScrW()/150 )

		surface.DrawCircle( center.x, center.y, radius, Color(255,255,255,220))
		surface.DrawCircle( center.x, center.y, radius + 1, Color(20,20,20,220))
	end
end)


hook.Add("CalcView", "BFG_WeaponSeats_CalcVehViewCompensation", function(ply, pos, ang)
	if IsValid(ply:GetVehicle()) and ply:GetNWBool("SeatWeapon_Usage_Allowed", false) then
		local oldang = ang
		ang:Set(ply:EyeAngles() + ply:GetViewPunchAngles())
		local localvec, localang = WorldToLocal( Vector(0,0,0), ang, Vector(0,0,0), ply:GetVehicle():GetAngles())		

		ang:RotateAroundAxis( ang:Forward() * -1, localang.r)
	end
end)

hook.Add("CalcViewModelView", "BFG_WeaponSeats_CalcViewModelViewCompensation", function(wep, vm, oldpos, newpos, oldang, newang)
	if IsValid(vm:GetOwner()) then
		local ply = vm:GetOwner()
		if ply:InVehicle() and ply:GetNWBool("SeatWeapon_Usage_Allowed", false) then
			newang:Set(ply:EyeAngles() + ply:GetViewPunchAngles())
			local localvec, localang = WorldToLocal( Vector(0,0,0), newang, Vector(0,0,0), ply:GetVehicle():GetAngles())		
			newang:RotateAroundAxis( newang:Forward() * -1, localang.r )
		end
	end
end)

hook.Add("ContextMenuOpen", "BFG_WeaponSeats_Toggle", function()
	local ply = LocalPlayer()
		if not ply.SeatWeaponizer_LastEnteredContextMenu then ply.SeatWeaponizer_LastEnteredContextMenu = 0 end
		if CurTime() - ply.SeatWeaponizer_LastEnteredContextMenu < .5 then
			--ply:ChatPrint("toggle called!")
			--ply:SetNWBool("SeatWeapon_Usage_Allowed", not ply:GetNWBool("SeatWeapon_Usage_Allowed", false))
			ply:ConCommand("weaponseats_toggle")
		end
		ply.SeatWeaponizer_LastEnteredContextMenu = CurTime()
	end)
	
	

concommand.Add("weaponseats_toggle", function(ply, cmd, args, argstring)
			net.Start("WeaponSeats_ToggleCommand")
			net.SendToServer()
end, nil, "Toggle using weapons in seats.")

end --if CLIENT then