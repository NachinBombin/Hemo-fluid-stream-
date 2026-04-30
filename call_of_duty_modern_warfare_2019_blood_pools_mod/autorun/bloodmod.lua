--// Copyright © 2020 by GalaxyHighMarshal, All rights reserved.
--// All trademarks are property of their respective owners.
--// No parts of this coding or any of its contents may be reproduced, copied, modified or adapted, without the prior written consent of the author, unless otherwise indicated for stand-alone materials. Doing so would be violating
--// https://store.steampowered.com/subscriber_agreement/ 
--// I Have Spoken!


if SERVER then
	util.AddNetworkString("GXEngine_DebugLine")
	util.AddNetworkString("GXEngine_DebugBone")
	if !ConVarExists( "GXEngine_enabled" ) then CreateConVar("GXEngine_enabled", "1", FCVAR_ARCHIVE, "Enables/Disables the blood particle effects") end
	cvars.AddChangeCallback("GXEngine_enabled", function(cvar, old, new)
		if new == "1" then
			hook.Add("EntityTakeDamage", "GXEngineEntDamaged", GXEngineEntityDamaged)
			return
		end
		hook.Remove("EntityTakeDamage", "GXEngineEntDamaged")
	end)
end
GXEngine_Density = 1
GXEngine_Enabled = true
GXEngine_DebugLines = {}
GXEngine_DebugBone = {}
GXEngine_EnabledMaterials = {MAT_BLOODYFLESH, MAT_FLESH}

function GXEngineEntityDamaged(ent, dmginfo)
	local mat = ent:GetMaterialType()
	if (!ent:GetMaterialType() or (!table.HasValue(GXEngine_EnabledMaterials, mat) and !(mat == 1 and ent:IsNPC()))) and !ent:IsPlayer() then return end
	
	local effectdata = EffectData()
	effectdata:SetOrigin( dmginfo:GetDamagePosition( ) )
	effectdata:SetNormal( dmginfo:GetDamageForce():Angle():Forward() )
	effectdata:SetEntity(ent)
	effectdata:SetMagnitude(dmginfo:GetDamage())
	
 
		 
		 
		 
	

	
	local len = dmginfo:GetDamageForce():Length()/0.5
	for i = 1, math.random(0,1) do
		util.Decal( "blood", dmginfo:GetDamagePosition( )-dmginfo:GetDamageForce():Angle():Forward()*8, dmginfo:GetDamagePosition( )+Vector(math.random(-len,len),math.random(-len,len),math.random(-len,len)))
	end
	
	
	
	if math.random(0,1) == 1 then 
		local tr = {}
		tr.start = dmginfo:GetDamagePosition( )
		tr.endpos = dmginfo:GetDamagePosition( )+dmginfo:GetDamageForce():Angle():Forward()*4
		tr.filter = function(e) return e == ent end
		tr.ignoreworld = false 
		tr = util.TraceLine(tr)
		if !IsValid(tr.Entity) then return end
		effectdata:SetAttachment(tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone))
			
 
 

		
		
	end
end
hook.Add("EntityTakeDamage", "GXEngineEntDamaged", GXEngineEntityDamaged)





-- function GXEngine_DrawLines()
	-- for k, v in pairs(GXEngine_DebugLines) do
		-- render.DrawLine(v[1], v[2], Color(255, 0, 0))
	-- end
-- end
-- hook.Add("PostDrawOpaqueRenderables", "GXEngineDrawLines", GXEngine_DrawLines)

-- function GXEngine_AddLine(v1, v2)
	-- local t = CurTime()+math.random(1,96)
	-- table.insert(GXEngine_DebugLines, t, {v1,v2})
	-- //timer.Simple(2, function() table.remove(GXEngine_DebugLines, t) end)
-- end

-- function GXEngine_AddBoneLine(bone, ent)
	-- local t = CurTime()
	-- table.insert(GXEngine_DebugBone, t, {bone,ent})
	-- //timer.Simple(2, function() table.remove(GXEngine_DebugBone, t) end)
-- end

-- net.Receive( "GXEngine_DebugLine", function()
	-- local t = net.ReadTable()
	-- GXEngine_AddLine(t[1], t[2])
-- end)


--// Copyright © 2020 by GalaxyHighMarshal, All rights reserved.
--// All trademarks are property of their respective owners.
--// No parts of this coding or any of its contents may be reproduced, copied, modified or adapted, without the prior written consent of the author, unless otherwise indicated for stand-alone materials. Doing so would be violating
--// https://store.steampowered.com/subscriber_agreement/ 
--// I Have Spoken!
