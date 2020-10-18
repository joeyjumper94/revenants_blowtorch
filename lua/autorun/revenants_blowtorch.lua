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
	["prop_physics"] = 100,--standard prop
	["func_movelinear"] = 1000,--elevators
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
	["darkrp_billboard"]=100,--advert billboard
	["prop_ragdoll"]=100,--ragdolls
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
local blowtorch_range_sqr=blowtorch_max_distance*blowtorch_max_distance--square it so we can compare using the faster Vec1:DistToSqr(Vec2)>number
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
	SlotPos=2,--Position in the slot, should be in the range 0-128 Default: 10
	Primary={
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
	UseHands=true,--[[ (Clientside) Makes the player models hands bonemerged onto the view model
WARNING 	The gamemode and view models must support this feature for it to work!
You can find more information here: Using Viewmodel Hands
Default: false]]
	ClassName="revenants_blowtorch",
}
local GetOwnerName=function(Entity)
	if!Entity.CPPIGetOwner then
		return
	end
	local Player=Entity:CPPIGetOwner()
	if Player then
		if Player:IsValid()then
			return Player:Name()
		end
		return"a disconnected player"
	end
end
local GetClass=function(Entity)
	if Entity.CPPIGetOwner then
		local o,u=Entity:CPPIGetOwner()
		if o or u then
			return Entity:GetClass()
		end
	end
end
function SWEP:PrimaryAttack()
	if self:GetNWFloat("NextAttack",0)>CurTime()then return end
	if CLIENT then return end
	self:SetNWFloat("NextAttack",CurTime()+blowtorch_normal_cooldown)
	local ply=self.Owner or NULL
	if!ply:IsPlayer()then return end
	local start=ply:GetShootPos()
	local trace=ply:GetEyeTrace()
	local Entity=trace.Entity
	local HitPos=trace.HitPos
	if Entity:IsValid()then
		local ClassName=GetClass(Entity)
		local MaxHealth=blowtorchables[ClassName]
		if MaxHealth and start:DistToSqr(HitPos)<=blowtorch_range_sqr then
			local CurHealth=Entity:GetNWFloat("b_prop_health",MaxHealth)
			local CEffectData = EffectData()
			CEffectData:SetStart(HitPos)
			CEffectData:SetOrigin(HitPos)
			CEffectData:SetNormal((start-HitPos):GetNormalized())
			CEffectData:SetScale(1)
			if CurHealth-blowtorch_normal_damage>0 then
				Entity:EmitSound("Metal.SawbladeStick")
				util.Effect("MetalSpark",CEffectData,true,true)
				Entity:SetNWFloat("b_prop_health",CurHealth-blowtorch_normal_damage)
			else
				Entity:EmitSound("npc/scanner/cbot_energyexplosion1.wav")
				util.Effect("Explosion",CEffectData,true,true)
				Entity:Remove()
				if blowtorch_log_stuff then
					ServerLog(ply:Name().." ("..ply:SteamID()..") blowtorched a(n) "..ClassName.." owned by "..GetOwnerName(Entity).."\n")
					if DarkRP then
						DarkRP.log(ply:Name().." ("..ply:SteamID()..") blowtorched a(n) "..ClassName.." owned by "..GetOwnerName(Entity),Color(0,255,229))
					end
				end
			end
			hook.Run("Revenants_Blowtorch_hook",ply,trace,Entity,CurHealth-blowtorch_normal_damage<=0,CurHealth==MaxHealth,false)--the player,their eyetrace,did we destroy ,did we start,multi
		end
	end
end
function SWEP:SecondaryAttack()
	if self:GetNWFloat("NextAttack",0)>CurTime()then return end
	if CLIENT then return end
	self:SetNWFloat("NextAttack",CurTime()+blowtorch_repair_cooldown)
	local ply=self.Owner or NULL
	if!ply:IsPlayer()then return end
	local start=ply:GetShootPos()
	local trace=ply:GetEyeTrace()
	local Entity=trace.Entity
	if Entity:IsValid()then
		local ClassName=GetClass(Entity)
		local MaxHealth=blowtorchables[ClassName]
		if MaxHealth and start:DistToSqr(trace.HitPos)<=blowtorch_range_sqr then
			local CurHealth=Entity:GetNWFloat("b_prop_health",MaxHealth)
			if CurHealth==MaxHealth then
				ply:PrintMessage(HUD_PRINTTALK,"this prop is at full health")
			elseif ply.canAfford and blowtorch_repair_cost>0 and !ply:canAfford(blowtorch_repair_cost)then
				ply:PrintMessage(HUD_PRINTTALK,"you cannot afford this repair")
			else
				if ply.addMoney then
					ply:addMoney(-blowtorch_repair_cost)
				end
				Entity:SetNWFloat("b_prop_health",math.min(CurHealth+blowtorch_repair_health,MaxHealth))
				Entity:EmitSound("ambient/energy/spark"..math.random(1,6)..".wav")
			end
		end
	end
end
function SWEP:Reload()
	if self:GetNWFloat("NextAttack",0)>CurTime()then return end
	if CLIENT then return end
	self:SetNWFloat("NextAttack",CurTime()+blowtorch_blast_cooldown)
	local ply=self.Owner or NULL
	if!ply:IsPlayer()then return end
	local start=ply:GetShootPos()
	local trace=util.TraceLine{
		start=start,
		endpos=start+ply:GetAimVector()*blowtorch_max_distance,
	}
	for k,Entity in ipairs(ents.FindInSphere(trace.HitPos,blowtorch_blast_radius))do
		local ClassName=GetClass(Entity)
		local MaxHealth=blowtorchables[ClassName]
		if MaxHealth then
			local CurHealth=Entity:GetNWFloat("b_prop_health",MaxHealth)
			local pos = Entity:GetPos()
			local CEffectData = EffectData()
			CEffectData:SetStart(pos)
			CEffectData:SetOrigin(pos)
			CEffectData:SetScale(1)
			CEffectData:SetNormal((start-pos):GetNormalized())
			if CurHealth-blowtorch_blast_damage>0 then
				Entity:EmitSound("Metal.SawbladeStick")
				util.Effect("MetalSpark",CEffectData,true,true)
				Entity:SetNWFloat("b_prop_health",CurHealth-blowtorch_blast_damage)
			else
				Entity:EmitSound("npc/scanner/cbot_energyexplosion1.wav")
				util.Effect("Explosion",CEffectData,true,true)
				Entity:Remove()
				if blowtorch_log_stuff then
					ServerLog(ply:Name().." ("..ply:SteamID()..") blowtorched a(n) "..ClassName.." owned by "..GetOwnerName(Entity).."\n")
					if DarkRP then
						DarkRP.log(ply:Name().." ("..ply:SteamID()..") blowtorched a(n) "..ClassName.." owned by "..GetOwnerName(Entity),Color(0,255,229))
					end
				end
			end
			hook.Run("Revenants_Blowtorch_hook",ply,trace,Entity,CurHealth-blowtorch_normal_damage<=0,CurHealth==MaxHealth,true)--the player,their eyetrace,did we destroy ,did we start,multi
		end
	end
end
hook.Add("PreDrawHalos",SWEP.ClassName,function()
	local ply=LocalPlayer()
	if ply:GetActiveWeapon().ClassName==SWEP.ClassName then
		local start=ply:GetShootPos()
		local trace=ply:GetEyeTrace()
		local Entity=trace.Entity
		if Entity:IsValid()then
			local MaxHealth=blowtorchables[GetClass(Entity)]
			if MaxHealth and start:DistToSqr(trace.HitPos)<=blowtorch_range_sqr then
				local CurHealth=Entity:GetNWFloat("b_prop_health",MaxHealth)
				local pos=Entity:GetPos():ToScreen()
				local fraction=CurHealth/MaxHealth*255
				local color=Color(255-fraction,fraction,0)
				halo.Add({Entity},color,8,8,1,true,true)
				cam.Start2D()
				draw.DrawText("Health: "..CurHealth.."/"..MaxHealth,"Trebuchet24",pos.x,pos.y,color,TEXT_ALIGN_CENTER)
				cam.End2D()
			end
		end
	end
end)
weapons.Register(SWEP,SWEP.ClassName)
