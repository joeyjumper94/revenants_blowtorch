local blowtorch_log_stuff=true--should blowtorching be logged?
local blowtorch_max_distance=100--how far can you be from a prop yet still interact with it?

local blowtorch_normal_cooldown=0.5--how long is the cooldown after each damage?
local blowtorch_normal_damage=5--how much damage should each attack do to props?

local blowtorch_repair_cooldown=0.5--how long is the cooldown after each repair?
local blowtorch_repair_health=2.5--how much health to restore each repair?
local blowtorch_repair_cost=20--how much does each repair cost?(requires darkrp)

local blowtorch_blast_cooldown=5--how long is the cooldown after each blast?
local blowtorch_blast_damage=10--how much damage does a blast from a blowtorch do?
local blowtorch_blast_radius=50--how big is the blast from a blowtorch?

local blowtorchables={--this table lists all the enities that can be blowtorched. add an entity class as the key and give it a number value to set how much health it has
	["elevator"] = 1000,
	["prop_physics"] = 100,
	["func_movelinear"] = 1000,
	["prop_dynamic"]=100,
	["sent_sniperrifle"]=50,
	["sent_airboatgun"]=50,
	["sent_degtyarev"]=50,
	["sent_m249"]=50,
	["sent_ptrs41"]=50,
	["itemstore_box_giant"]=50,
	["itemstore_box_huge"]=50,
	["itemstore_box_large"]=50,
	["itemstore_box"]=50,
	["darkrp_billboard"]=100,
	["prop_ragdoll"]=100,

	-- Stationary guns
	["stationary_gun_airboat"] = 350,
	["stationary_gun_airboat_nocover"] = 350,
	["stationary_gun_mg"] = 350,
	["stationary_gun_ptrs"] = 350,
	["stationary_gun_ptrs_proj"] = 350,
	["stationary_gun_sniper"] = 350,
	["stationary_gun_tau"] = 350,
	["stationary_gun_tau_nocover"] = 350,

	-- Itemstore drop box
	["itemstore_deathloot"] = 50,
}
--end of config, don't touch anything below here
blowtorch_max_distance=blowtorch_max_distance*blowtorch_max_distance--square it so we can compare using the faster Vec1:DistToSqr(Vec2)>number
local SWEP={
	Category="Revenant's raiding tools",--(Clientside) Category the SWEP is in Default: "Other"
	Author="joeyjumper94 AKA Revenant Moon",--(Clientside) The author of the SWEP to be shown in weapon selection Default: ""
	Purpose="to blow down props",--(Clientside) The purpose of the SWEP creator to be shown in weapon selection Default: ""
	Instructions=[[primary attack to damage and destroy props
secondary to repair props
reload to do a blast that can hit multiple props but will incur a longer cooldown]],--(Clientside) How to use your weapon, to be shown in weapon selection Default: ""
	DrawAmmo=false,--(Clientside) Should we draw the default HL2 ammo counter? Default: true
	Spawnable=true,--Whether this SWEP should be displayed in the Q menu Default: false
	AdminOnly=true,--Whether or not only admins can spawn the SWEP from their Q menu Default: false
	PrintName="Revenant's Blowtorch",--Nice name of the SWEP Default: "Scripted Weapon"
	ViewModel="models/weapons/c_irifle.mdl",--Path to the view model for your SWEP (what the wielder will see) Default: "models/weapons/v_pistol.mdl"
	WorldModel="models/weapons/w_irifle.mdl",--The world model for your SWEP (what you will see in other players hands) Default: "models/weapons/w_357.mdl"
	Slot=5,--Slot in the weapon selection menu, starts with 0 Default: 0
	Primary={
		SlotPos=2,--Position in the slot, should be in the range 0-128 Default: 10
		Ammo="none",--Ammo type ("Pistol", "SMG1" etc)
		ClipSize=-1,--The maximum amount of bullets one clip can hold
		DefaultClip=-1,--Default ammo in the clip, making it higher than ClipSize will give player additional ammo on spawn
		Automatic=true,--If true makes the weapon shoot automatically as long as the player has primary attack button held down
	},
	Secondary={
		Ammo="none",--Ammo type ("Pistol", "SMG1" etc)
		ClipSize=-1,--The maximum amount of bullets one clip can hold
		DefaultClip=-1,--Default ammo in the clip, making it higher than ClipSize will give player additional ammo on spawn
		Automatic=true,--Secondary attack settings, has same fields as Primary attack settings
	},
	DisableDuplicator=true,--Disable the ability for players to duplicate this SWEP Default: false
	Contact="http://steamcommunity.com/profiles/76561198051306817/",--(Clientside) The contacts of the SWEP creator to be shown in weapon selection Default: ""
	UseHands=true,
--[[ (Clientside) Makes the player models hands bonemerged onto the view model
WARNING 	The gamemode and view models must support this feature for it to work!
You can find more information here: Using Viewmodel Hands
Default: false]]
	ClassName="revenants_blowtorch",
}
function SWEP:PrimaryAttack()
	if self:GetNWFloat("NextAttack",0)>CurTime() then return end
	self:SetNWFloat("NextAttack",CurTime()+blowtorch_normal_cooldown)
	local weapon=self.Weapon
	local ply=self.Owner
	local trace=ply:GetEyeTrace()
	local HitPos=trace.HitPos
	local Entity=trace.Entity
	if SERVER then
		if Entity and Entity:IsValid() and blowtorchables[Entity:GetClass()] and Entity:CPPIGetOwner() and Entity:CPPIGetOwner():IsValid() and ply:GetShootPos():DistToSqr(HitPos)<=blowtorch_max_distance then
			local MaxHealth=blowtorchables[Entity:GetClass()]
			local CurHealth=Entity:GetNWInt("b_prop_health",MaxHealth)
			local pos=Entity:GetPos()
			local effectdata = EffectData()
			effectdata:SetStart(pos)
			effectdata:SetOrigin(pos)
			effectdata:SetScale(1)
			
			if CurHealth-blowtorch_normal_damage>0 then
				Entity:EmitSound(Sound("Metal.SawbladeStick"))
				util.Effect("MetalSpark",effectdata,true,true)
				Entity:SetNWInt("b_prop_health",CurHealth-blowtorch_normal_damage)
			else
				Entity:EmitSound("npc/scanner/cbot_energyexplosion1.wav")
				util.Effect("Explosion",effectdata,true,true)
				Entity:Remove()
				if ply and ply:IsValid() and (Entity:CPPIGetOwner():IsValid() and Entity:CPPIGetOwner():Name() or "a Disconnected player") and blowtorch_log_stuff then
					ServerLog(ply:Name().." ("..ply:SteamID()..") blowtorched a(n) "..Entity:GetClass().." owned by "..(Entity:CPPIGetOwner():IsValid() and Entity:CPPIGetOwner():Name() or "a Disconnected player"))
					if DarkRP then
						DarkRP.log(ply:Name().." ("..ply:SteamID()..") blowtorched a(n) "..Entity:GetClass().." owned by "..(Entity:CPPIGetOwner():IsValid() and Entity:CPPIGetOwner():Name() or "a Disconnected player"),Color(0,255,229))
					end
				end
			end

			if ply and ply:IsValid() and (Entity:CPPIGetOwner():IsValid() and Entity:CPPIGetOwner():Name() or "a Disconnected player") then
				hook.Run("Revenants_Blowtorch_hook",ply,trace,Entity,CurHealth-blowtorch_normal_damage<=0,CurHealth==MaxHealth,false)--the player,their eyetrace,did we destroy ,did we start,multi
			end
		end
	end
end
function SWEP:SecondaryAttack()
	if self:GetNWFloat("NextAttack",0)>CurTime() then return end
	self:SetNWFloat("NextAttack",CurTime()+blowtorch_repair_cooldown)
	local weapon=self.Weapon
	local ply=self.Owner
	local trace=ply:GetEyeTrace()
	local HitPos=trace.HitPos
	local Entity=trace.Entity
	if SERVER then
		if Entity and Entity:IsValid() and blowtorchables[Entity:GetClass()] and Entity:CPPIGetOwner() and Entity:CPPIGetOwner():IsValid() and ply:GetShootPos():DistToSqr(HitPos)<=blowtorch_max_distance then
			local MaxHealth=blowtorchables[Entity:GetClass()]
			local CurHealth=Entity:GetNWInt("b_prop_health",MaxHealth)

			if CurHealth!=MaxHealth and DarkRP and blowtorch_repair_cost>0 and ply:canAfford(blowtorch_repair_cost) then
				ply:addMoney(blowtorch_repair_cost)
			elseif CurHealth!=MaxHealth and DarkRP and blowtorch_repair_cost>0 then
				ply:PrintMessage(HUD_PRINTTALK,"you cannot afford this repair")
				return
			end

			if CurHealth==MaxHealth then
				ply:PrintMessage(HUD_PRINTTALK,"this prop is at full health")
			elseif CurHealth+blowtorch_repair_health>=MaxHealth then
				Entity:SetNWInt("b_prop_health",MaxHealth)
				Entity:EmitSound("ambient/energy/spark"..math.random(1,6)..".wav")
			else
				Entity:SetNWInt("b_prop_health",CurHealth+blowtorch_repair_health)
				Entity:EmitSound("ambient/energy/spark"..math.random(1,6)..".wav")
			end
		end
	end
end
function SWEP:Reload()
	if self:GetNWFloat("NextAttack",0)>CurTime() then return end
	self:SetNWFloat("NextAttack",CurTime()+blowtorch_blast_cooldown)
	local weapon=self.Weapon
	local ply=self.Owner
	local trace=ply:GetEyeTrace()
	local HitPos=trace.HitPos
	local Entity=trace.Entity
	if CLIENT then return end
	if ply:GetShootPos():DistToSqr(hitpos)>blowtorch_max_distance then return end
	for k,Entity in ipairs(ents.FindInSphere(HitPos,blowtorch_blast_radius)) do
		if Entity and Entity:IsValid() and blowtorchables[Entity:GetClass()] and Entity:CPPIGetOwner() then
			local MaxHealth=blowtorchables[Entity:GetClass()]
			local CurHealth=Entity:GetNWInt("b_prop_health",MaxHealth)
			local pos = Entity:GetPos()
			local effectdata = EffectData()
			effectdata:SetStart(pos)
			effectdata:SetOrigin(pos)
			effectdata:SetScale(1)

			if CurHealth-blowtorch_blast_damage>0 then
				Entity:EmitSound(Sound("Metal.SawbladeStick"))
				util.Effect("MetalSpark",effectdata,true,true)
				Entity:SetNWInt("b_prop_health",CurHealth-blowtorch_blast_damage)
			else
				Entity:EmitSound("npc/scanner/cbot_energyexplosion1.wav")
				util.Effect("Explosion",effectdata,true,true)
				Entity:Remove()
				if ply and ply:IsValid() and (Entity:CPPIGetOwner():IsValid() and Entity:CPPIGetOwner():Name() or "a Disconnected player") and blowtorch_log_stuff then
					ServerLog(ply:Name().." ("..ply:SteamID()..") blowtorched a(n) "..Entity:GetClass().." owned by "..(Entity:CPPIGetOwner():IsValid() and Entity:CPPIGetOwner():Name() or "a Disconnected player"))
					if DarkRP then
						DarkRP.log(ply:Name().." ("..ply:SteamID()..") blowtorched a(n) "..Entity:GetClass().." owned by "..(Entity:CPPIGetOwner():IsValid() and Entity:CPPIGetOwner():Name() or "a Disconnected player"),Color(0,255,229))
					end
				end
			end

			if ply and ply:IsValid() and (Entity:CPPIGetOwner():IsValid() and Entity:CPPIGetOwner():Name() or "a Disconnected player") then
				hook.Run("Revenants_Blowtorch_hook",ply,trace,Entity,CurHealth-blowtorch_normal_damage<=0,CurHealth==MaxHealth,true)--the player,their eyetrace,did we destroy ,did we start,multi
			end
		end
	end
end
function SWEP:DrawHUD()
	local ply=LocalPlayer()
	local trace=ply:GetEyeTrace()
	local Entity=trace.Entity
	if Entity and Entity:IsValid() and blowtorchables[Entity:GetClass()] and Entity:CPPIGetOwner() and ply:GetShootPos():DistToSqr(trace.HitPos)<=blowtorch_max_distance then
		local MaxHealth=blowtorchables[Entity:GetClass()]
		local CurHealth=Entity:GetNWInt("b_prop_health",MaxHealth)
		local pos=Entity:GetPos():ToScreen()
		draw.DrawText("Health: "..CurHealth.."/"..MaxHealth,"Trebuchet24",pos.x,pos.y,Color(255-(CurHealth*2.5),CurHealth*2.5,0,255 ),TEXT_ALIGN_CENTER)
	end
end
weapons.Register(SWEP,SWEP.ClassName)
	--[[
if CLIENT then
--	BobScale=1--(Clientside) The scale of the viewmodel bob (viewmodel movement from left to right when walking around) Default: 1
--	SwayScale=1--(Clientside) The scale of the viewmodel sway (viewmodel position lerp when looking around). Default: 1
--	BounceWeaponIcon=true--(Clientside) Should the weapon icon bounce in weapon selection? Default: true
--	DrawWeaponInfoBox=true--(Clientside) Should draw the weapon selection info box, containing Instructions, etc. Default: true
--	DrawCrosshair=true--(Clientside) Should we draw the default crosshair? Default: true
--	RenderGroup=RENDERGROUP_OPAQUE--(Clientside) The SWEP render group, see RENDERGROUP_ Enums Default: RENDERGROUP_OPAQUE
--	SpeechBubbleLid=surface.GetTextureID( "gui/speech_lid" )--(Clientside) Internal variable for drawing the info box in weapon selection Default: surface.GetTextureID( "gui/speech_lid" )
--	WepSelectIcon--(Clientside) Path to an texture. Override this in your SWEP to set the icon in the weapon selection. This must be the texture ID, see surface.GetTextureID Default: surface.GetTextureID( "weapons/swep" )
--	CSMuzzleFlashes=false--(Clientside) Should we use Counter-Strike muzzle flashes upon firing? This is required for DoD:S or CS:S view models to fix their muzzle flashes. Default: false
--	CSMuzzleX=false--(Clientside) Use the X shape muzzle flash instead of the default Counter-Strike muzzle flash. Requires CSMuzzleFlashes to be set to true Default: false
--	AccurateCrosshair=false--(Clientside) Makes the default SWEP crosshair be positioned in 3D space where your aim actually is (like on Jeep), instead of simply sitting in the middle of the screen at all times Default: false
else
--	AutoSwitchFrom=true--(Serverside) Whether this weapon can be autoswitched away from when the player runs out of ammo in this weapon or picks up another weapon or ammo Default: true
--	AutoSwitchTo=true--(Serverside) Whether this weapon can be autoswitched to when the player runs out of ammo in their current weapon or they pick this weapon up Default: true
--	Weight=5--(Serverside) Decides whether we should switch from/to this Default: 5
end
--ClassName--Entity class name of the SWEP (file or folder name of your SWEP). This is set automatically
--Base="weapon_base"--The base weapon to derive from. This must be a Lua weapon Default: "weapon_base"
--m_WeaponDeploySpeed=1--Multiplier of deploy speed Default: 1
--Owner--The entity that owns/wields this SWEP, if any
--Folder--The folder from where the weapon was loaded. This should always be "weapons/weapon_myweapon", regardless whether your SWEP is stored as a file, or multiple files in a folder. It is set automatically on load
--]]