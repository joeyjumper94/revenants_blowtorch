local FLAGS={FCVAR_ARCHIVE,FCVAR_REPLICATED,FCVAR_SERVER_CAN_EXECUTE}
local blowtorch_log_stuff=CreateConVar("blowtorch_log_stuff","1",FLAGS,"should blowtorching be logged?"):GetBool()
local blowtorch_max_distance=CreateConVar("blowtorch_max_distance","100",FLAGS,"how far can you be from a prop yet still interact with it?"):GetFloat()

local blowtorch_normal_cooldown=CreateConVar("blowtorch_normal_cooldown","0.5",FLAGS,"how long is the cooldown after each damage?"):GetFloat()
local blowtorch_normal_damage=CreateConVar("blowtorch_normal_damage","5",FLAGS,"how much damage should each attack do to props?"):GetFloat()

local blowtorch_repair_cooldown=CreateConVar("blowtorch_repair_cooldown","0.5",FLAGS,"how long is the cooldown after each repair?"):GetFloat()
local blowtorch_repair_health=CreateConVar("blowtorch_repair_health","2.5",FLAGS,"how much health to restore each repair?"):GetFloat()
local blowtorch_repair_cost=CreateConVar("blowtorch_repair_cost","20",FLAGS,"how much does each repair cost?(requires darkrp)"):GetFloat()

local blowtorch_blast_cooldown=CreateConVar("blowtorch_blast_cooldown","5",FLAGS,"how long is the cooldown after each blast?"):GetFloat()
local blowtorch_blast_damage=CreateConVar("blowtorch_blast_damage","10",FLAGS,"how much damage does a blast from a blowtorch do?"):GetFloat()
local blowtorch_blast_radius=CreateConVar("blowtorch_blast_radius","50",FLAGS,"how big is the blast from a blowtorch?"):GetFloat()

local blowtorchables={--this table lists all the enities that can be blowtorched. add an entity class as the key and give it a number value
	["elevator"]=1000,
	["prop_physics"]=100,
	["func_movelinear"]=1000,
	["prop_dynamic"]=750,
	["darkrp_billboard"]=1000,
}
--end of config, don't touch anything below here
if CLIENT then
	SWEP.Category="Revenant's sweps"--(Clientside) Category the SWEP is in Default: "Other"
	SWEP.Author="joeyjumper94 AKA Revenant Moon"--(Clientside) The author of the SWEP to be shown in weapon selection Default: ""
	SWEP.Purpose="to blow down props"--(Clientside) The purpose of the SWEP creator to be shown in weapon selection Default: ""
	SWEP.Instructions='primary attack to damage and destroy props\nsecondary to repair props\nreload to do a blast that can hit multiple props but will incur a longer cooldown'--(Clientside) How to use your weapon, to be shown in weapon selection Default: ""
	SWEP.DrawAmmo=false--(Clientside) Should we draw the default HL2 ammo counter? Default: true
end
SWEP.Spawnable=true--Whether this SWEP should be displayed in the Q menu Default: false
SWEP.AdminOnly=true--Whether or not only admins can spawn the SWEP from their Q menu Default: false
SWEP.PrintName="Blowtorch"--Nice name of the SWEP Default: "Scripted Weapon"
SWEP.ViewModel="models/weapons/v_IRifle.mdl"--Path to the view model for your SWEP (what the wielder will see) Default: "models/weapons/v_pistol.mdl"
SWEP.WorldModel="models/weapons/w_IRifle.mdl"--The world model for your SWEP (what you will see in other players hands) Default: "models/weapons/w_357.mdl"
SWEP.Slot=5--Slot in the weapon selection menu, starts with 0 Default: 0
SWEP.SlotPos=2--Position in the slot, should be in the range 0-128 Default: 10
SWEP.Primary.Ammo="none"--Ammo type ("Pistol", "SMG1" etc)
SWEP.Primary.ClipSize=-1--The maximum amount of bullets one clip can hold
SWEP.Primary.DefaultClip=-1--Default ammo in the clip, making it higher than ClipSize will give player additional ammo on spawn
SWEP.Primary.Automatic=true--If true makes the weapon shoot automatically as long as the player has primary attack button held down
SWEP.Secondary.Ammo="none"--Ammo type ("Pistol", "SMG1" etc)
SWEP.Secondary.ClipSize=-1--The maximum amount of bullets one clip can hold
SWEP.Secondary.DefaultClip=-1--Default ammo in the clip, making it higher than ClipSize will give player additional ammo on spawn
SWEP.Secondary.Automatic=true--Secondary attack settings, has same fields as Primary attack settings
SWEP.DisableDuplicator=true--Disable the ability for players to duplicate this SWEP Default: false
function SWEP:PrimaryAttack()
	local weapon=self.Weapon
	local ply=self.Owner
	local trace=ply:GetEyeTrace()
	local hitpos=trace.HitPos
	local Entity=trace.Entity
	weapon:SetNextPrimaryFire(CurTime()+blowtorch_normal_cooldown)
	weapon:SetNextSecondaryFire(CurTime()+blowtorch_normal_cooldown)
	timer.Create(ply:SteamID64().."blowtorch_blast_cooldown",blowtorch_normal_cooldown,1,function() end)
	if SERVER then
		if Entity and Entity:IsValid() and blowtorchables[Entity:GetClass()] and Entity:CPPIGetOwner() and ply:GetShootPos():Distance(Entity:GetPos())<=blowtorch_max_distance then
			local MaxHealth=blowtorchables[Entity:GetClass()]
			local CurHealth=Entity:GetNWInt("revenant's_blowtorch_prop_health",MaxHealth)
			local pos = Entity:GetPos()
			local effectdata = EffectData()
			effectdata:SetStart(pos)
			effectdata:SetOrigin(pos)
			effectdata:SetScale(1)
			
			if CurHealth-blowtorch_normal_damage>0 then
				Entity:EmitSound(Sound("Metal.SawbladeStick"))
				util.Effect("MetalSpark",effectdata,true,true)
				Entity:SetNWInt("revenant's_blowtorch_prop_health",CurHealth-blowtorch_normal_damage)
			else
				Entity:EmitSound("npc/scanner/cbot_energyexplosion1.wav")
				util.Effect("Explosion",effectdata,true,true)
				Entity:Remove()
				if ply and IsValid(ply) and Entity:CPPIGetOwner():Nick() and blowtorch_log_stuff then
					ServerLog(tostring(ply:Nick()).." ("..tostring(ply:SteamID())..") blowtorched a(n) "..tostring(Entity:GetClass()).." owned by "..tostring(Entity:CPPIGetOwner():Nick()))
					if DarkRP then
						DarkRP.log(tostring(ply:Nick()).." ("..tostring(ply:SteamID())..") blowtorched a(n) "..tostring(Entity:GetClass()).." owned by "..tostring(Entity:CPPIGetOwner():Nick()),Color(0,255,229))
					end
				end
			end

			if ply and IsValid(ply) and Entity:CPPIGetOwner():Nick() then
				hook.Run("Revenants_Blowtorch_hook",ply,trace,Entity,CurHealth-blowtorch_normal_damage<=0,CurHealth==MaxHealth,false)--the player,their eyetrace,did we destroy ,did we start,multi
			end
		end
	end
end
function SWEP:SecondaryAttack()
	local weapon=self.Weapon
	local ply=self.Owner
	local trace=ply:GetEyeTrace()
	local hitpos=trace.HitPos
	local Entity=trace.Entity
	weapon:SetNextPrimaryFire(CurTime()+blowtorch_repair_cooldown)
	weapon:SetNextSecondaryFire(CurTime()+blowtorch_repair_cooldown)
	timer.Create(ply:SteamID64().."blowtorch_blast_cooldown",blowtorch_repair_cooldown,1,function() end)
	if SERVER then
		if Entity and Entity:IsValid() and blowtorchables[Entity:GetClass()] and Entity:CPPIGetOwner() and ply:GetShootPos():Distance(Entity:GetPos())<=blowtorch_max_distance then
			local MaxHealth=blowtorchables[Entity:GetClass()]
			local CurHealth=Entity:GetNWInt("revenant's_blowtorch_prop_health",MaxHealth)

			if CurHealth!=MaxHealth and DarkRP and blowtorch_repair_cost>0 and ply:canAfford(blowtorch_repair_cost) then
				ply:addMoney(blowtorch_repair_cost)
			elseif CurHealth!=MaxHealth and DarkRP and blowtorch_repair_cost>0 then
				ply:PrintMessage(HUD_PRINTTALK,"you cannot afford this repair")
				return
			end

			if CurHealth==MaxHealth then
				ply:PrintMessage(HUD_PRINTTALK,"this prop is at full health")
			elseif CurHealth+blowtorch_repair_health>=MaxHealth then
				Entity:SetNWInt("revenant's_blowtorch_prop_health",MaxHealth)
				Entity:EmitSound("ambient/energy/spark"..math.random(1,6)..".wav")
			else
				Entity:SetNWInt("revenant's_blowtorch_prop_health",CurHealth+blowtorch_repair_health)
				Entity:EmitSound("ambient/energy/spark"..math.random(1,6)..".wav")
			end
		end
	end
end
function SWEP:Reload()
	local weapon=self.Weapon
	local ply=self.Owner
	local trace=ply:GetEyeTrace()
	local hitpos=trace.HitPos
	if timer.Exists(ply:SteamID64().."blowtorch_blast_cooldown") then return end
	weapon:SetNextPrimaryFire(CurTime()+blowtorch_blast_cooldown)
	weapon:SetNextSecondaryFire(CurTime()+blowtorch_blast_cooldown)
	timer.Create(ply:SteamID64().."blowtorch_blast_cooldown",blowtorch_blast_cooldown,1,function() end)
	if CLIENT then return end
	if ply:GetShootPos():Distance(hitpos)>blowtorch_max_distance then return end
	for k,Entity in ipairs(ents.FindInSphere(hitpos,blowtorch_blast_radius)) do
		if Entity and Entity:IsValid() and blowtorchables[Entity:GetClass()] and Entity:CPPIGetOwner() then
			local MaxHealth=blowtorchables[Entity:GetClass()]
			local CurHealth=Entity:GetNWInt("revenant's_blowtorch_prop_health",MaxHealth)
			local pos = Entity:GetPos()
			local effectdata = EffectData()
			effectdata:SetStart(pos)
			effectdata:SetOrigin(pos)
			effectdata:SetScale(1)

			if CurHealth-blowtorch_blast_damage>0 then
				Entity:EmitSound(Sound("Metal.SawbladeStick"))
				util.Effect("MetalSpark",effectdata,true,true)
				Entity:SetNWInt("revenant's_blowtorch_prop_health",CurHealth-blowtorch_blast_damage)
			else
				Entity:EmitSound("npc/scanner/cbot_energyexplosion1.wav")
				util.Effect("Explosion",effectdata,true,true)
				Entity:Remove()
				if ply and IsValid(ply) and Entity:CPPIGetOwner():Nick() and blowtorch_log_stuff then
					ServerLog(tostring(ply:Nick()).." ("..tostring(ply:SteamID())..") blowtorched a(n) "..tostring(Entity:GetClass()).." owned by "..tostring(Entity:CPPIGetOwner():Nick()))
					if DarkRP then
						DarkRP.log(tostring(ply:Nick()).." ("..tostring(ply:SteamID())..") blowtorched a(n) "..tostring(Entity:GetClass()).." owned by "..tostring(Entity:CPPIGetOwner():Nick()),Color(0,255,229))
					end
				end
			end

			if ply and IsValid(ply) and Entity:CPPIGetOwner():Nick() then
				hook.Run("Revenants_Blowtorch_hook",ply,trace,Entity,CurHealth-blowtorch_normal_damage<=0,CurHealth==MaxHealth,true)--the player,their eyetrace,did we destroy ,did we start,multi
			end
		end
	end
end


if CLIENT then
	function SWEP:DrawHUD()
		local ply=LocalPlayer()
		local Entity=ply:GetEyeTrace().Entity
		if Entity and Entity:IsValid() and blowtorchables[Entity:GetClass()] and Entity:CPPIGetOwner() and ply:GetShootPos():Distance(Entity:GetPos())<=blowtorch_max_distance then
			local MaxHealth=blowtorchables[Entity:GetClass()]
			local CurHealth=Entity:GetNWInt("revenant's_blowtorch_prop_health",MaxHealth)
			local pos=Entity:GetPos():ToScreen()
			draw.DrawText("Health: "..CurHealth.."/"..MaxHealth,"Trebuchet24",pos.x,pos.y,Color(255-(CurHealth*2.5),CurHealth*2.5,0,255 ),TEXT_ALIGN_CENTER)
		end
	end
end

if CLIENT then
--	SWEP.Contact="http://steamcommunity.com/profiles/76561198051306817/"--(Clientside) The contacts of the SWEP creator to be shown in weapon selection Default: ""
--	SWEP.BobScale=1--(Clientside) The scale of the viewmodel bob (viewmodel movement from left to right when walking around) Default: 1
--	SWEP.SwayScale=1--(Clientside) The scale of the viewmodel sway (viewmodel position lerp when looking around). Default: 1
--	SWEP.BounceWeaponIcon=true--(Clientside) Should the weapon icon bounce in weapon selection? Default: true
--	SWEP.DrawWeaponInfoBox=true--(Clientside) Should draw the weapon selection info box, containing SWEP.Instructions, etc. Default: true
--	SWEP.DrawCrosshair=true--(Clientside) Should we draw the default crosshair? Default: true
--	SWEP.RenderGroup=RENDERGROUP_OPAQUE--(Clientside) The SWEP render group, see RENDERGROUP_ Enums Default: RENDERGROUP_OPAQUE
--	SWEP.SpeechBubbleLid=surface.GetTextureID( "gui/speech_lid" )--(Clientside) Internal variable for drawing the info box in weapon selection Default: surface.GetTextureID( "gui/speech_lid" )
--	SWEP.WepSelectIcon--(Clientside) Path to an texture. Override this in your SWEP to set the icon in the weapon selection. This must be the texture ID, see surface.GetTextureID Default: surface.GetTextureID( "weapons/swep" )
--	SWEP.CSMuzzleFlashes=false--(Clientside) Should we use Counter-Strike muzzle flashes upon firing? This is required for DoD:S or CS:S view models to fix their muzzle flashes. Default: false
--	SWEP.CSMuzzleX=false--(Clientside) Use the X shape muzzle flash instead of the default Counter-Strike muzzle flash. Requires CSMuzzleFlashes to be set to true Default: false
--	SWEP.UseHands=false
--[[ (Clientside) Makes the player models hands bonemerged onto the view model
WARNING 	The gamemode and view models must support this feature for it to work!
You can find more information here: Using Viewmodel Hands
Default: false]]
--	SWEP.AccurateCrosshair=false--(Clientside) Makes the default SWEP crosshair be positioned in 3D space where your aim actually is (like on Jeep), instead of simply sitting in the middle of the screen at all times Default: false
else
--	SWEP.AutoSwitchFrom=true--(Serverside) Whether this weapon can be autoswitched away from when the player runs out of ammo in this weapon or picks up another weapon or ammo Default: true
--	SWEP.AutoSwitchTo=true--(Serverside) Whether this weapon can be autoswitched to when the player runs out of ammo in their current weapon or they pick this weapon up Default: true
--	SWEP.Weight=5--(Serverside) Decides whether we should switch from/to this Default: 5
end
--SWEP.ClassName--Entity class name of the SWEP (file or folder name of your SWEP). This is set automatically
--SWEP.Base="weapon_base"--The base weapon to derive from. This must be a Lua weapon Default: "weapon_base"
--SWEP.m_WeaponDeploySpeed=1--Multiplier of deploy speed Default: 1
--SWEP.Owner--The entity that owns/wields this SWEP, if any
--SWEP.Folder--The folder from where the weapon was loaded. This should always be "weapons/weapon_myweapon", regardless whether your SWEP is stored as a file, or multiple files in a folder. It is set automatically on load
