if SERVER then
    include("bloodmod_extensions.lua")
    --include("uragdollblood.lua") - doesn't exist?
 
    --PrecacheParticleSystem("AntlionGibTrails_air")

    -- ConVar for bloodstream cooldown between streams (Server-side, replicated)
    CreateConVar("nextgenblood4_stream_cooldown_min", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Minimum time between blood streams")
    CreateConVar("nextgenblood4_stream_cooldown_max", "2", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Maximum time between blood streams")
    CreateConVar("nextgenblood4_debug_bones", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable debug output for bone detection (1 = on, 0 = off)")

    local function do_blood_stream(pos, ang, bone, flags, rag)
        --theres proably a better way to do this D:
        
        if not IsValid(rag) then return end
            
        if !rag.nextgen4_next_bloodstream then rag.nextgen4_next_bloodstream = CurTime() end
        if rag.nextgen4_next_bloodstream > CurTime() then return end
        
        -- Use ConVars for cooldown timing
        local cooldown_min = GetConVar("nextgenblood4_stream_cooldown_min"):GetFloat()
        local cooldown_max = GetConVar("nextgenblood4_stream_cooldown_max"):GetFloat()
        rag.nextgen4_next_bloodstream = CurTime() + math.Rand(cooldown_min, cooldown_max)
 
        local meme = ents.Create("prop_dynamic")
        if not IsValid(meme) then return end
        
        meme:SetModel("models/error.mdl")               
        meme:Spawn()
        meme:SetModelScale(0)
        meme:SetNotSolid(true)
        meme:DrawShadow(false)
 
        SafeRemoveEntityDelayed(meme, 15)
 
        meme:FollowBone(rag, bone)
 
        meme:SetLocalAngles(ang)
        meme:SetLocalPos(pos - ang:Forward()*-8)
        
        -- NEW: Store the bone index on the entity so effect can access it
        meme.bloodstream_lastdmgbone = bone
        
        -- Store reference for cleanup
        if not rag.nextgen4_bloodstream_entities then 
            rag.nextgen4_bloodstream_entities = {} 
        end
        table.insert(rag.nextgen4_bloodstream_entities, meme)
 
        --ParticleEffectAttach("AntlionGibTrails_air", PATTACH_ABSORIGIN_FOLLOW, meme, 0)
        local effectdata = EffectData()
        effectdata:SetEntity(meme)
        effectdata:SetFlags(flags)
        util.Effect("bloodstreameffectzippy", effectdata)
 
         --ParticleEffect("AntlionGibTrails", dmgpos, dmgdir:Angle())
    end
 
      hook.Add("EntityTakeDamage", "BloodStream_TakeDamage", function(ent, dmginfo)
        if (!ent:IsPlayer() and !ent:IsNPC() and !ent.allow_nextgen4_bloodstreams) then return end
 
        local dmgpos = dmginfo:GetDamagePosition()
        local dmgdir = dmginfo:GetDamageForce()
        
        local phys_bone = dmginfo:GetHitPhysBone(ent)
        
        if phys_bone && dmginfo:IsBulletDamage() then
            local bone = ent:TranslatePhysBoneToBone(phys_bone)
            
            -- Debug output
            if GetConVar("nextgenblood4_debug_bones"):GetBool() then
                local bone_name = ent:GetBoneName(bone)
                print("[BloodStream Debug] Hit bone: " .. bone_name .. " (bone " .. bone .. ", phys_bone " .. phys_bone .. ")")
            end
 
            local lpos, lang = WorldToLocal(dmgpos, dmgdir:Angle(), ent:GetBonePosition(bone))
 
            ent.bloodstream_lastdmgbone = bone
            ent.bloodstream_lastdmglpos = lpos
            ent.bloodstream_lastdmglang = lang
 
            do_blood_stream(lpos, lang, bone, 1, ent)
        end
    end)
 
    hook.Add("CreateEntityRagdoll", "BloodStream_ApplyEffect", function(ent, rag)
        rag.allow_nextgen4_bloodstreams = true
        
        -- Simple approach like original: just create bloodstream on ragdoll if entity had last damage
        if ent.bloodstream_lastdmglpos then
            local bone = ent.bloodstream_lastdmgbone
            local lpos = ent.bloodstream_lastdmglpos
            local lang = ent.bloodstream_lastdmglang
            
            -- Debug output for ragdoll
            if GetConVar("nextgenblood4_debug_bones"):GetBool() then
                local bone_name = rag:GetBoneName(bone)
                print("[BloodStream Debug] Creating ragdoll bloodstream: " .. bone_name .. " (bone " .. bone .. ")")
            end
     
            do_blood_stream(lpos, lang, bone, 0, rag)
        end
    end)
    
    -- Additional hook for player death to ensure ragdoll gets bloodstream
    hook.Add("PlayerDeath", "BloodStream_PlayerDeath", function(victim, inflictor, attacker)
        -- Clean up bloodstreams on the player model (they'll be recreated on ragdoll)
        if victim.nextgen4_bloodstream_entities then
            for _, meme in ipairs(victim.nextgen4_bloodstream_entities) do
                if IsValid(meme) then
                    SafeRemoveEntity(meme)
                end
            end
            victim.nextgen4_bloodstream_entities = nil
        end
        
        -- Wait a tiny bit for ragdoll to be created
        timer.Simple(0.1, function()
            if not IsValid(victim) then return end
            
            local ragdoll = victim:GetRagdollEntity()
            if IsValid(ragdoll) and victim.bloodstream_lastdmglpos then
                ragdoll.allow_nextgen4_bloodstreams = true
                
                local bone = victim.bloodstream_lastdmgbone
                local lpos = victim.bloodstream_lastdmglpos
                local lang = victim.bloodstream_lastdmglang
                
                if GetConVar("nextgenblood4_debug_bones"):GetBool() then
                    print("[BloodStream Debug] Player death - creating bloodstream on ragdoll bone " .. bone)
                end
                
                do_blood_stream(lpos, lang, bone, 0, ragdoll)
            end
        end)
    end)
    
    -- Cleanup bloodstream entities when parent entity is removed (multiplayer stability)
    hook.Add("EntityRemoved", "BloodStream_EntityCleanup", function(ent)
        if ent.nextgen4_bloodstream_entities then
            for _, meme in ipairs(ent.nextgen4_bloodstream_entities) do
                if IsValid(meme) then
                    SafeRemoveEntity(meme)
                end
            end
            ent.nextgen4_bloodstream_entities = nil
        end
    end)
end