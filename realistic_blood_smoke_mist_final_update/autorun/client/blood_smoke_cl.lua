if CLIENT then
    -- =========================
    -- Function: Spawn Blood Mist at a position
    -- =========================
    local function SpawnBloodAt(pos, dir, caliber, isLethal)
        if not pos or type(pos) ~= "Vector" then return end
        if GetConVar("bloodmist_enable"):GetBool() == false then return end

        local emitter = ParticleEmitter(pos)
        if not emitter then return end

        -- ConVars for customization
        local intensity = GetConVar("bloodmist_intensity"):GetFloat()
        local sizeMul = GetConVar("bloodmist_size"):GetFloat()
        local lifeMul = GetConVar("bloodmist_lifetime"):GetFloat()
        local maxParticles = math.Clamp(GetConVar("bloodmist_max_particles"):GetInt(),5,40)
        local grav = GetConVar("bloodmist_gravity"):GetFloat()
        local r = GetConVar("bloodmist_color_r"):GetInt()
        local g = GetConVar("bloodmist_color_g"):GetInt()
        local b = GetConVar("bloodmist_color_b"):GetInt()

        -- Adjust particles by caliber
        local caliberMul = 1
        if caliber=="pistol" then caliberMul=0.6
        elseif caliber=="rifle" then caliberMul=1
        elseif caliber=="shotgun" then caliberMul=1.5
        elseif caliber=="sniper" then caliberMul=2 end

        local count = math.Round(maxParticles * caliberMul)

        for i=1,count do
            local p = emitter:Add("particle/smokesprites_000"..math.random(1,9), pos)
            if not p then continue end

            -- Safe lighting calculation
            local light = render.GetLightColor(pos)
            local brightness = 0.35 -- default if dark
            if light and (light.x + light.y + light.z) > 0 then
                brightness = math.Clamp((light.x + light.y + light.z)/3, 0.15, 1)
            end

            -- Multiply user color by brightness
            local bloodR = math.Clamp(r * brightness, 0, 255)
            local bloodG = math.Clamp(g * brightness, 0, 255)
            local bloodB = math.Clamp(b * brightness, 0, 255)

            -- Particle velocity
            local velocity = dir * math.Rand(40,70) + VectorRand() * 15
            velocity = velocity * intensity

            p:SetVelocity(velocity)
            p:SetLifeTime(0)
            p:SetDieTime(math.Rand(0.6,1.2) * lifeMul)
            p:SetStartAlpha(isLethal and 80 or 55)
            p:SetEndAlpha(0)
            p:SetStartSize(8 * sizeMul)
            p:SetEndSize(20 * sizeMul)
            p:SetColor(bloodR, bloodG, bloodB)
            p:SetAirResistance(40)
            p:SetGravity(Vector(0,0,grav))
            p:SetRoll(math.Rand(0,360))
            p:SetRollDelta(math.Rand(-0.5,0.5))
        end

        emitter:Finish()

        -- Screen fade
        local screenFade = GetConVar("bloodmist_screenfade"):GetFloat()
        if screenFade > 0 then
            hook.Run("BloodMist_ScreenFade", screenFade)
        end
    end

    -- =========================
    -- Receive net message from server
    -- =========================
    net.Receive("Starstrckks_BloodSmoke", function()
        local pos = net.ReadVector()
        local dir = net.ReadVector()
        local caliber = net.ReadString()
        local isLethal = net.ReadBool()
        local ent = net.ReadEntity()

        -- Spawn at ragdoll bones if entity is valid and ragdoll
        if IsValid(ent) and ent:GetClass():find("ragdoll") then
            for i=0, ent:GetBoneCount()-1 do
                local bonePos = ent:GetBonePosition(i)
                if bonePos and type(bonePos) == "Vector" then
                    SpawnBloodAt(bonePos, dir, caliber, isLethal)
                end
            end
        else
            SpawnBloodAt(pos, dir, caliber, isLethal)
        end
    end)

    -- =========================
    -- Screen fade effect
    -- =========================
    local mistFade = 0
    hook.Add("BloodMist_ScreenFade", "BloodMist_ScreenEffect", function(strength)
        mistFade = math.Clamp(mistFade + strength, 0, 0.15)
    end)

    hook.Add("HUDPaint", "BloodMist_ScreenFadePaint", function()
        if mistFade <= 0 then return end
        surface.SetDrawColor(120,0,0, mistFade*255)
        surface.DrawRect(0,0,ScrW(),ScrH())
        mistFade = Lerp(FrameTime()*2, mistFade, 0)
    end)
end
