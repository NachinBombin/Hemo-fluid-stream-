-- Core ConVars (Server-side, replicated to clients)
CreateConVar("nextgenblood4_blood_stream_reps_multiplier", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Multiplier for blood stream particle count (duration)")
CreateConVar("nextgenblood4_blood_sound_volume", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Blood sound volume")
CreateConVar("nextgenblood4_squirt_sound_volume", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Squirt sound volume")

-- NEW ConVars for customization (Server-side, replicated to clients)
CreateConVar("nextgenblood4_stream_size", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Size multiplier for blood streams (0.5 = half, 2 = double)")
CreateConVar("nextgenblood4_stream_force", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Force multiplier for blood streams (supports decimals like 0.5, 1.5, 2.3)")
CreateConVar("nextgenblood4_stream_spread", "5", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Spread/FOV angle for blood streams in degrees (0 = straight line, 15 = wide spray)")
CreateConVar("nextgenblood4_stream_density", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY}, "Frequency of blood spurts (0.1 = very frequent, 5 = slow/rare)")

-- These are kinda ugly, you probably want to change them:
local particles = {
    "decals/trail",
}

-- Use these, but shaderless i guess, or maybe use more of a "stain" rather than a "splat":
local decals = {
    "decals/Blood1",
    "decals/Blood3",
    "decals/Blood4",
    "decals/Blood5",
    "decals/Blood6",
    "decals/Blood2",
    "decals/Blood3",
}

-- Particle:
local particle_length_random = {min=100,max=100}
local particle_start_lengt_mult = 0.1
local particle_scale = 0.4

local particle_gravity = 1050
local particle_force = 200
local particle_pulsate_max_force = 100
local particle_pulsate_speed_mult = 8

local particle_reps_stream = 300
local particle_reps_burst = 150

local particle_fps = 60
local particle_lifetime = 8

local stream_particle_lifetime = 8
local burst_particle_lifetime = 8

-- Decal:
local decal_scale = 0.2

-- Sound:
local drip_sounds = {
    "bloodsplashing/drip_1.wav",
    "bloodsplashing/drip_2.wav",
    "bloodsplashing/drip_3.wav",
    "bloodsplashing/drip_4.wav",
    "bloodsplashing/drip_5.wav",    
    "bloodsplashing/drips_1.wav",
    "bloodsplashing/drips_2.wav",
    "bloodsplashing/drips_3.wav",
    "bloodsplashing/drips_4.wav",
    "bloodsplashing/drips_5.wav",
    "bloodsplashing/drips_6.wav",
    "bloodsplashing/spatter_grass_1.wav",
    "bloodsplashing/spatter_grass_2.wav",
    "bloodsplashing/spatter_grass_3.wav",
    "bloodsplashing/spatter_hard_1.wav",
    "bloodsplashing/spatter_hard_2.wav",
    "bloodsplashing/spatter_hard_3.wav",
    "bloodsplashing/drip_lowpass_1.wav",
    "bloodsplashing/drip_lowpass_2.wav",
    "bloodsplashing/drip_lowpass_3.wav",
    "bloodsplashing/drip_lowpass_4.wav",
    "bloodsplashing/drip_lowpass_5.wav",
}

local sound_level = 70

local squrt_sounds = {
    "squirting/artery_squirt_1.wav",
    "squirting/artery_squirt_2.wav",
    "squirting/artery_squirt_3.wav",
    "squirting/artery_squirt_3.wav",
    "squirting/artery_squirt_2.wav",
    "squirting/artery_squirt_1.wav",
    "squirting/artery_squirt_2.wav",
    "squirting/artery_squirt_2.wav",
    "squirting/artery_squirt_3.wav",
    "squirting/artery_squirt_1.wav",
    "squirting/artery_squirt_3.wav",
    "squirting/artery_squirt_2.wav",
}
local sound_level2 = 35

-- Impact:
local impact_chance = 1 -- 1 in x

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Function to get limb multiplier (CLIENT-SIDE)
local function GetLimbMultiplier(boneName)
    if CLIENT and GetLimbMultiplierForBone then
        return GetLimbMultiplierForBone(boneName)
    end
    return 1
end

local function make_materials(tbl)
    local materials = {}

    for _,v in ipairs(tbl) do
        local imat = Material(v)
        table.insert(materials, imat)
    end
    
    return materials
end

local decal_mats = make_materials(decals)
local particle_mats = make_materials(particles)

local min_strenght = 0.25

function EFFECT:Init(data)
    local ent = data:GetEntity()
    
    if not IsValid(ent) then return end

    local flags = data:GetFlags()
    
    -- Apply reps multiplier to particle count
    local reps_multiplier = GetConVar("nextgenblood4_blood_stream_reps_multiplier"):GetFloat()
    self.reps = math.floor(((flags == 1 and particle_reps_burst) or (flags == 0 and particle_reps_stream) or 0) * reps_multiplier)

    -- Get customizable values as LOCAL variables so they're captured in timer closure
    local size_mult = GetConVar("nextgenblood4_stream_size"):GetFloat()
    local force_mult = GetConVar("nextgenblood4_stream_force"):GetFloat()
    local spread_angle = GetConVar("nextgenblood4_stream_spread"):GetFloat()
    local density = GetConVar("nextgenblood4_stream_density"):GetFloat()
    
    -- NEW: Get bone name for limb multiplier
    local boneName = ""
    if IsValid(ent) and ent.bloodstream_lastdmgbone then
        boneName = ent:GetBoneName(ent.bloodstream_lastdmgbone)
    end
    local limb_mult = GetLimbMultiplier(boneName)
    
    -- Apply limb multiplier ONLY to force and density (frequency)
    force_mult = force_mult * limb_mult
    density = density / limb_mult -- Divide density so higher multiplier = more frequent spurts
    
    -- Density now controls how often spurts happen (lower = more frequent)
    -- Convert density to delay: density 1 = normal, density 0.1 = very frequent, density 5 = very slow
    local spurt_delay = math.Rand(0.5, 5) / (particle_fps * density)

    self.StartTime = CurTime()
    self.CurrentPos = ent:GetPos()
    self.CurrentStrenght = 1
    self:UpdateExtraForce()

    -- Create unique timer name to prevent conflicts in multiplayer
    self.timername = "NextGen4BloodStreamTimer_" .. ent:EntIndex() .. "_" .. CurTime()
    local emitter = ParticleEmitter(self.CurrentPos, false)
    
    if not emitter then return end

    -- Play squirt sound
    sound.Play(table.Random(squrt_sounds), ent:GetPos(), sound_level2, math.Rand(95, 105), GetConVar("nextgenblood4_squirt_sound_volume"):GetFloat())

    -- Store self reference for timer callback
    local effect_self = self
    local reps = self.reps
    
    timer.Create(self.timername, spurt_delay, reps, function()
        if not IsValid(ent) or not emitter then
            if emitter then emitter:Finish() end
            timer.Remove(effect_self.timername)
            return
        end
        -- Play squirt sound again
        sound.Play(table.Random(squrt_sounds), ent:GetPos(), sound_level2, math.Rand(95, 105), GetConVar("nextgenblood4_squirt_sound_volume"):GetFloat())

        ent.CurrentPos = ent:GetPos()

        local length = math.Rand(particle_length_random.min, particle_length_random.max)

        local particle = emitter:Add(table.Random(particle_mats), ent.CurrentPos)
            
            -- Use default particle lifetime
            particle:SetDieTime(particle_lifetime * effect_self.CurrentStrenght)
            
            -- Apply size multiplier to particle size (NO limb multiplier)
            particle:SetStartSize(math.Rand(1.9, 3.8) * particle_scale * size_mult)
            particle:SetEndSize(0)
            particle:SetStartLength(length * particle_scale * particle_start_lengt_mult * size_mult)
            particle:SetEndLength(length * particle_scale * size_mult)
            
            particle:SetGravity(Vector(0, 0, -particle_gravity))
            
            -- Calculate base velocity with force multiplier (includes limb_mult)
            local base_velocity = ent:GetForward() * -(particle_force + effect_self.ExtraForce) * effect_self.CurrentStrenght * force_mult
            
            -- Add spread/FOV to velocity
            if spread_angle > 0 then
                local spread_rad = math.rad(spread_angle)
                local random_pitch = math.Rand(-spread_rad, spread_rad)
                local random_yaw = math.Rand(-spread_rad, spread_rad)
                
                -- Create spread direction
                local forward = ent:GetForward()
                local right = ent:GetRight()
                local up = ent:GetUp()
                
                -- Apply random angles for spread
                local spread_dir = forward + (right * math.sin(random_yaw)) + (up * math.sin(random_pitch))
                spread_dir:Normalize()
                
                -- Apply spread direction to velocity
                local velocity_magnitude = base_velocity:Length()
                base_velocity = spread_dir * -velocity_magnitude
            end
            
            particle:SetVelocity(base_velocity)
            
            particle:SetCollide(true)
            particle:SetCollideCallback(function(_, pos, normal)
                if math.random(1, impact_chance) == 1 and (effect_self.CurrentStrenght or min_strenght) > 0.2 then
                    -- Play blood drip sound
                    sound.Play(table.Random(drip_sounds), pos, sound_level, math.Rand(95, 105), GetConVar("nextgenblood4_blood_sound_volume"):GetFloat())
                    
                    -- Apply size multiplier to decal size (NO limb multiplier)
                    local decal_size = decal_scale * size_mult
                    util.DecalEx(table.Random(decal_mats), Entity(0), pos, normal, Color(255, 255, 255), decal_size, decal_size)
                end
            end)

        if timer.RepsLeft(effect_self.timername) == 0 then emitter:Finish() end
    end)
end

function EFFECT:UpdateExtraForce()
    self.ExtraForce = particle_pulsate_max_force * (1 + math.sin(CurTime() * particle_pulsate_speed_mult))
end

function EFFECT:Think()
    if timer.Exists(self.timername) then
        local lifetime = CurTime() - self.StartTime
        local dietime = self.reps * (1 / particle_fps)
        self.CurrentStrenght = math.Clamp(1 - (lifetime / dietime) * (1 - min_strenght), 0, 1)

        self:UpdateExtraForce()
        return true
    else
        return false
    end
end

function EFFECT:Render() end

-- Cleanup timers on effect removal for multiplayer stability
hook.Add("EntityRemoved", "NextGen4BloodStream_Cleanup", function(ent)
    if ent.nextgen4_bloodstream_timer then
        timer.Remove(ent.nextgen4_bloodstream_timer)
    end
end)