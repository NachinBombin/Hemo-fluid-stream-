-- Code reference: Custom Blood Bleeding 3332958092 Universal SMOD Bleeding Effect 2840303209

include("of_simple_bleeding/extensions.lua")
local active_bloodstreams = {}

local function OFBleeding_CleanUp()
    for i = #active_bloodstreams, 1, -1 do
        if not IsValid(active_bloodstreams[i]) then
            table.remove(active_bloodstreams, i)
        end
    end
end

local function OFBleeding_DO(pos, ang, bone, rag, islarge, type)
    if not rag or not bone then return end

    if GetConVar("of_bleeding_enabled"):GetInt() ~= 1 then return end
    if GetConVar("ai_serverragdolls"):GetInt() ~= 1 then return end
    if not rag.juicy_next_bloodstream then rag.juicy_next_bloodstream = CurTime() end
    if rag.juicy_next_bloodstream > CurTime() then return end
    local cooldown = math.floor(GetConVar("of_bleeding_cooldown"):GetFloat() * 10) / 10
    if type ~= 1 then
        rag.juicy_next_bloodstream = CurTime() + cooldown
    end

    OFBleeding_CleanUp()
    if #active_bloodstreams >= GetConVar("of_bleeding_maxactive"):GetInt() then return end

    local hiddenmodel = ents.Create("prop_dynamic")
    hiddenmodel:SetModel("models/error.mdl")               
    hiddenmodel:Spawn()
    hiddenmodel:SetModelScale(0)
    hiddenmodel:SetNotSolid(true)
    hiddenmodel:DrawShadow(false)
    hiddenmodel:SetNW2Bool("of_bleeding_debug", true)
    hiddenmodel:SetNW2String("of_bleeding_debug_bone_name", rag:GetBoneName(bone) or tostring(bone))
    hiddenmodel:SetNW2Int("of_bleeding_debug_type", type or 0)

    SafeRemoveEntityDelayed(hiddenmodel, 2)

    hiddenmodel:FollowBone(rag, bone)

    hiddenmodel:SetLocalAngles(ang)
    hiddenmodel:SetLocalPos(pos)
    
    -- if GetConVar("of_bleeding_debug"):GetBool() then
    --     for _, ply in ipairs(player.GetAll()) do
    --         if ply:IsAdmin() then
    --             ply:ChatPrint("Angle: " .. tostring(ang))
    --             ply:ChatPrint("Hidden Model Angle: " .. tostring(hiddenmodel:GetAngles()))
    --         end
    --     end
    -- end

    local use_darker = GetConVar("of_bleeding_darker") and GetConVar("of_bleeding_darker"):GetBool()
    local effect_name
    if use_darker then
        effect_name = islarge and "of_simple_bleeding_darker_spray" or "of_simple_bleeding_darker_spray_b"
    else
        effect_name = islarge and "of_simple_bleeding_spray" or "of_simple_bleeding_spray_b"
    end

    -- 让致命伤暂且不播放流血效果，但是记录
    if type ~= 3 then
        ParticleEffectAttach(effect_name or "of_simple_bleeding_spray_b", PATTACH_ABSORIGIN_FOLLOW, hiddenmodel, 0)
    else
        timer.Simple(0.1, function()
            if IsValid(hiddenmodel) then
                -- 防止奇异搞笑小喷血
                ParticleEffectAttach(effect_name or "of_simple_bleeding_spray_b", PATTACH_ABSORIGIN_FOLLOW, hiddenmodel, 0)
            end
        end)
    end
    table.insert(active_bloodstreams, hiddenmodel)

    -- 记录本次流血点到实体表上，时间，局部位置，角度，骨骼索引，伤害
    rag._active_bloodstream_points = rag._active_bloodstream_points or {}
    table.insert(rag._active_bloodstream_points, {
        time = CurTime(),
        lpos = pos,
        lang = ang,
        bone = bone,
        islarge = islarge,
    })

    -- 清除超过两秒的记录
    local keep = {}
    for _, v in ipairs(rag._active_bloodstream_points) do
        if v.time and v.time > (CurTime() - 2) then
            table.insert(keep, v)
        end
    end
    rag._active_bloodstream_points = keep
end

hook.Add("EntityTakeDamage", "OFBleeding_TakeDamage", function(ent, dmginfo)
    if GetConVar("of_bleeding_enabled"):GetInt() ~= 1 then return end
    if GetConVar("ai_serverragdolls"):GetInt() ~= 1 then return end
    if (not ent:IsPlayer() and not ent:IsNPC() and not ent.allow_juicy_bloodstreams) then return end
    if ent:IsPlayer() and GetConVar("of_bleeding_player"):GetInt() ~= 1 then return end
    -- print("[OFBleeding] EntityTakeDamage:", ent, "DamageType:", dmginfo:GetDamageType())
    if not (dmginfo:IsBulletDamage() or dmginfo:IsDamageType(DMG_BUCKSHOT) or dmginfo:IsDamageType(DMG_SNIPER) or dmginfo:IsDamageType(DMG_NEVERGIB)) then return end

    local dmgpos = dmginfo:GetDamagePosition()
    local dmgdir = dmginfo:GetDamageForce()
    if not isvector(dmgpos) then return end
    if not isvector(dmgdir) or dmgdir:LengthSqr() <= 0 then
        dmgdir = ent:GetForward()
    end

    local bone = dmginfo:GetAnimBone(ent)
    if not bone then return end

    local bone_pos, bone_ang = ent:GetBonePosition(bone)
    if not isvector(bone_pos) then return end
    bone_ang = bone_ang or Angle(0, 0, 0)

    local lpos, lang = WorldToLocal(dmgpos, dmgdir:Angle(), bone_pos, bone_ang)
    local lnum = dmginfo:GetDamage()
    local islarge = lnum and lnum >= 40
    if dmginfo:IsDamageType(DMG_BUCKSHOT) or dmginfo:IsDamageType(DMG_SNIPER) or dmginfo:IsDamageType(DMG_NEVERGIB) then
        islarge = true
    end

    local bleed_type = 0
    local ent_class = ent:GetClass()
    if ent:IsRagdoll() then
        bleed_type = 2
    elseif lnum >= ent:Health() then
        bleed_type = 3
    end

    OFBleeding_DO(lpos, lang, bone, ent, islarge, bleed_type)
end)

hook.Add("CreateEntityRagdoll", "OFBleeding_ToRagdoll", function(ent, rag)
    if GetConVar("of_bleeding_enabled"):GetInt() ~= 1 then return end
    if GetConVar("ai_serverragdolls"):GetInt() ~= 1 then return end
    rag.allow_juicy_bloodstreams = true

    -- 迁移所有2秒内的流血点
    if ent._active_bloodstream_points then
        for _, v in ipairs(ent._active_bloodstream_points) do
            -- 验证内容有效再迁移
            if v and v.lpos and v.lang and v.bone then
                OFBleeding_DO(v.lpos, v.lang, v.bone, rag, v.islarge or false, 1)
            end
        end
        rag._active_bloodstream_points = ent._active_bloodstream_points
    end
end)