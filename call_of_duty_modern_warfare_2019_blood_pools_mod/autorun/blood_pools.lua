-- blood poolz
-- now 100% more gamemode compatible

--game.AddParticles("particles/particles_manifest.pcf")

-- change the textures to your liking
BLOOD_POOL_TEXTURES = {
	-- humans, players
	[BLOOD_COLOR_RED] = {
		"particle/AC/Experimental/vfx_bloodpool_alphatest_v2red",
	},
	-- aliens
	[BLOOD_COLOR_YELLOW] = {
 
	},
	-- zombies, headcrabs
	[BLOOD_COLOR_GREEN] = {
 
	}
}

local BLOOD_POOL_EFFECTS = {
	[BLOOD_COLOR_RED] = {
		"blood_pool_MysterAC_v2",
		"blood_pool_GHM_1",
		"blood_pool_GHM_2",
		"blood_pool_GHM_2e",
		"blood_pool_GHM_2e1",
		"blood_pool_GHM_2e2",
		"blood_pool_GHM_2ea",
		"blood_pool_GHM_2eo"
	}
}

function CreateBloodPoolForRagdoll(rag, boneid, lpos, color, flags)
	if not IsValid(rag) then return end
	
	local boneid = boneid or 0
	local flags = flags or 0
	local color = color or BLOOD_COLOR_RED

	local effects = BLOOD_POOL_EFFECTS[color]

	if !effects then return end

	local timer_name = "blood_pool_check_sleep"..rag:EntIndex()

	local phys_boneid = rag:TranslateBoneToPhysBone(boneid)

	local phys = rag:GetPhysicsObjectNum(phys_boneid)

	timer.Create(timer_name, 0.5, 0, function()
		if !IsValid(rag) or !IsValid(phys) then
			timer.Remove(timer_name)
			return
		end

		if phys:GetVelocity():LengthSqr() > 10 then return end

		timer.Remove(timer_name)

		local effect = effects[math.random(1, #effects)]

		--print(effect)

		ParticleEffect(effect, phys:LocalToWorld(lpos), angle_zero)
	end)
end

if CLIENT then
	CL_BLOOD_POOL_ITERATION = 20
	
	CreateClientConVar("bloodpool_min_size", 35, true, false, "Minimum size for blood pools.", 0)
	CreateClientConVar("bloodpool_max_size", 60, true, false, "Maximum size for blood pools.", 0)
	CreateClientConVar("bloodpool_lifetime", 180, true, false, "Time before blood pools are cleaned up. Does not apply to TTT.", 10)
	CreateClientConVar("bloodpool_cheap", 0, true, false, "Ignore blood pool size limitations. WARNING: Will result in floating blood!")
	
	concommand.Add("bloodpool_clear", function(ply, cmd, args)
		-- this is what i call a "hack"
		CL_BLOOD_POOL_ITERATION = CL_BLOOD_POOL_ITERATION + 1
	end)
end

if engine.ActiveGamemode() == "terrortown" then
	if SERVER then
		hook.Add("TTTOnCorpseCreated", "TTT_BloodPool", function(rag)	
			-- delaying the effect by a few frames seems to increase reliability immensely
			timer.Simple(0.05, function()
				if not IsValid(rag) then return end
				local boneid = 0
				
				if rag.was_headshot then
					boneid = rag:LookupBone("ValveBiped.Bip01_Head1")
				else
					boneid = rag:LookupBone("ValveBiped.Bip01_Spine")
				end
				
				CreateBloodPoolForRagdoll(rag, boneid, BLOOD_COLOR_RED, 1)
			end)
		end)
	end
else
	if SERVER then
		hook.Add("CreateEntityRagdoll", "BloodPool_Server", function(ent, rag)
			--print("Created Server ragdoll:"); print(rag)
						
			if ent.bloodpool_lastdmgbone then				
				CreateBloodPoolForRagdoll(rag, ent.bloodpool_lastdmgbone, ent.bloodpool_lastdmglpos, ent:GetBloodColor())				
			end
		end)
		
		hook.Add("EntityTakeDamage", "BloodPool_TakeDamage", function(ent, dmginfo)
			if (!ent:IsPlayer() and !ent:IsNPC()) then return end

			local phys_bone = dmginfo:GetHitPhysBone(ent)

			if phys_bone then
				local bone = ent:TranslatePhysBoneToBone(phys_bone)

				ent.bloodpool_lastdmgbone = bone

				ent.bloodpool_lastdmglpos = WorldToLocal(dmginfo:GetDamagePosition(), angle_zero, ent:GetBonePosition(bone))
			end
		end)
	else
		-- for some VERY FUCKING stupid reason, clientside ragdolls created by npc's are not valid, and thus won't work here. player ragdolls however do.
		-- i'm not interested enough in sandbox support for this addon to figure a fix for this. if you know, please tell me.
		hook.Add("CreateClientsideRagdoll", "BloodPool_CS", function(ent, rag)
			--print("Created Clientside ragdoll:"); print(rag)
			if ent.bloodpool_lasthitgroup then
				local boneid, pos = GetClosestBone(rag, ent.bloodpool_lastdmgpos)
				if boneid then
					CreateBloodPoolForRagdoll(rag, boneid, pos, ent:GetBloodColor())
				end
			end
		end)
	end
end

-- this is all