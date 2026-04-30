if SERVER then
    util.AddNetworkString("Starstrckks_BloodSmoke")

    local function IsDeadOrRagdoll(ent)
        return ent:IsRagdoll()
            or (ent:IsNPC() and not ent:Alive())
            or (ent:IsPlayer() and ent:Health() <= 0)
    end

    -- Rough caliber estimation (Source doesn't expose real caliber)
    local function GetCaliberWeight(dmginfo)
        local dmg = dmginfo:GetDamage()

        if dmg < 20 then
            return 1 -- pistols / SMGs
        elseif dmg < 40 then
            return 2 -- rifles
        else
            return 3 -- sniper / shotgun / high power
        end
    end

    hook.Add("EntityTakeDamage", "Starstrckks_BloodSmoke", function(target, dmginfo)
        if not IsValid(target) then return end
        if not (target:IsPlayer() or target:IsNPC() or target:IsRagdoll()) then return end
        if bit.band(dmginfo:GetDamageType(), DMG_BULLET) == 0 then return end

        local attacker = dmginfo:GetAttacker()
        if not IsValid(attacker) then return end

        local hitPos = dmginfo:GetDamagePosition()
        if hitPos == vector_origin then
            hitPos = target:WorldSpaceCenter()
        end

        local bulletDir = (hitPos - attacker:GetShootPos()):GetNormalized()

        net.Start("Starstrckks_BloodSmoke")
            net.WriteVector(hitPos - bulletDir * 6) -- exit side
            net.WriteVector(bulletDir)
            net.WriteUInt(GetCaliberWeight(dmginfo), 2)
            net.WriteBool(IsDeadOrRagdoll(target))
        net.Broadcast()
    end)
end
