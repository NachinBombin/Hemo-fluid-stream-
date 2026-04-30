-- bloodmist.lua
if not CLIENT then return end

-- =========================
-- CREATE CLIENT CONVARS (DEFAULT ON, SAVED)
-- =========================
local function createConVar(name, default, help)
    if not ConVarExists(name) then
        -- 3rd parameter = save to config
        CreateClientConVar(name, default, true, false, help or "")
    end
end

-- Main toggle
createConVar("bloodmist_enable", "1", "Enable Blood Mist (Default ON)")

-- Basic customization
createConVar("bloodmist_intensity", "1", "Particle intensity multiplier")
createConVar("bloodmist_size", "1", "Particle size multiplier")
createConVar("bloodmist_lifetime", "1", "Particle lifetime multiplier")
createConVar("bloodmist_max_particles", "15", "Maximum number of particles")
createConVar("bloodmist_gravity", "-10", "Particle gravity Z")
createConVar("bloodmist_color_r", "140", "Red")
createConVar("bloodmist_color_g", "0", "Green")
createConVar("bloodmist_color_b", "0", "Blue")
createConVar("bloodmist_screenfade", "0.05", "Screen fade strength")
createConVar("bloodmist_caliber", "rifle", "Test caliber (pistol, rifle, shotgun, sniper)")

-- =========================
-- PARTICLE SPAWN FUNCTION
-- =========================
local function spawnBloodMist(pos, caliber)
    if not GetConVar("bloodmist_enable"):GetBool() then return end

    local emitter = ParticleEmitter(pos)
    if not emitter then return end

    local count = math.Clamp(GetConVar("bloodmist_max_particles"):GetInt(), 5, 25)
    local intensity = GetConVar("bloodmist_intensity"):GetFloat()
    local sizeMul = GetConVar("bloodmist_size"):GetFloat()
    local lifeMul = GetConVar("bloodmist_lifetime"):GetFloat()
    local grav = GetConVar("bloodmist_gravity"):GetFloat()
    local r = GetConVar("bloodmist_color_r"):GetInt()
    local g = GetConVar("bloodmist_color_g"):GetInt()
    local b = GetConVar("bloodmist_color_b"):GetInt()

    -- Caliber multiplier
    local caliberMul = 1
    if caliber=="pistol" then caliberMul=0.6
    elseif caliber=="rifle" then caliberMul=1
    elseif caliber=="shotgun" then caliberMul=1.5
    elseif caliber=="sniper" then caliberMul=2 end
    count = math.Round(count * caliberMul)

    for i = 1, count do
        local p = emitter:Add("particle/smokesprites_000"..math.random(1,9), pos)
        if p then
            p:SetVelocity(VectorRand() * 30 * intensity)
            p:SetLifeTime(0)
            p:SetDieTime(math.Rand(0.6,1.2) * lifeMul)
            p:SetStartAlpha(80)
            p:SetEndAlpha(0)
            p:SetStartSize(8*sizeMul)
            p:SetEndSize(20*sizeMul)
            p:SetColor(r,g,b)
            p:SetAirResistance(40)
            p:SetGravity(Vector(0,0,grav))
        end
    end

    emitter:Finish()
end

hook.Add("BloodMist_Spawn", "BloodMist_Particles", spawnBloodMist)

-- =========================
-- SCREEN FADE EFFECT
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

-- =========================
-- SPAWN MENU
-- =========================
local darkGray = Color(60,60,60)

hook.Add("PopulateToolMenu", "BloodMist_Menu", function()
    spawnmenu.AddToolMenuOption(
        "Utilities",
        "BloodMist",
        "BloodMist_Settings",
        "BloodMist",
        "", "",
        function(panel)
            panel:ClearControls()
            
            local function DarkHelp(text)
                local h = panel:Help(text)
                h:SetTextColor(darkGray)
                return h
            end

            DarkHelp("BloodMist - Custom Mist Settings (Default ON)")

            -- Toggle button (dynamic text, persistent)
            local toggle = vgui.Create("DCheckBoxLabel", panel)
            local enabled = GetConVar("bloodmist_enable"):GetBool()
            toggle:SetText("Enable Blood Mist ("..(enabled and "ON" or "OFF")..")")
            toggle:SetConVar("bloodmist_enable")
            toggle:SetValue(enabled and 1 or 0)
            toggle:SetTextColor(darkGray)
            toggle:SizeToContents()
            panel:AddItem(toggle)

            toggle.OnChange = function(self, val)
                self:SetText("Enable Blood Mist (" .. (val and "ON" or "OFF") .. ")")
                self:SizeToContents()
            end

            -- Caliber dropdown
            DarkHelp("Test Caliber")
            local calibers = {"pistol","rifle","shotgun","sniper"}
            local caliberCombo = vgui.Create("DComboBox", panel)
            local currentCaliber = GetConVar("bloodmist_caliber"):GetString() or "rifle"
            caliberCombo:SetValue(currentCaliber)
            for _, c in ipairs(calibers) do
                caliberCombo:AddChoice(c)
            end
            caliberCombo.OnSelect = function(_, _, val)
                RunConsoleCommand("bloodmist_caliber", val)
            end
            panel:AddItem(caliberCombo)

            -- Presets
            DarkHelp("Presets")
            local presets = {
                ["Realistic"] = {bloodmist_enable=1, bloodmist_intensity=1, bloodmist_size=1, bloodmist_lifetime=1, bloodmist_max_particles=15, bloodmist_gravity=-10, bloodmist_color_r=140, bloodmist_color_g=0, bloodmist_color_b=0, bloodmist_screenfade=0.05},
                ["Cinematic"]  = {bloodmist_enable=1, bloodmist_intensity=1.4, bloodmist_size=1.3, bloodmist_lifetime=1.2, bloodmist_max_particles=25, bloodmist_gravity=-5, bloodmist_color_r=255, bloodmist_color_g=80, bloodmist_color_b=80, bloodmist_screenfade=0.1},
                ["Minimal"]    = {bloodmist_enable=1, bloodmist_intensity=0.5, bloodmist_size=0.8, bloodmist_lifetime=0.7, bloodmist_max_particles=8, bloodmist_gravity=-15, bloodmist_color_r=150, bloodmist_color_g=0, bloodmist_color_b=0, bloodmist_screenfade=0.03}
            }

            for name, data in pairs(presets) do
                local btn = vgui.Create("DButton", panel)
                btn:SetText(name)
                btn:SetTall(28)
                btn:SetTextColor(darkGray)
                btn.DoClick = function()
                    for cvar,val in pairs(data) do
                        RunConsoleCommand(cvar,tostring(val))
                    end
                    -- Update dropdown to current caliber
                    caliberCombo:SetValue(GetConVar("bloodmist_caliber"):GetString())
                end
                panel:AddItem(btn)
            end

            -- Sliders helper
            DarkHelp("Manual Sliders")
            local function AddSlider(text, cvar, min, max, dec)
                local s = vgui.Create("DNumSlider", panel)
                s:SetText(text)
                s:SetMin(min)
                s:SetMax(max)
                s:SetDecimals(dec)
                s:SetConVar(cvar)
                s:SetTall(35)
                s.Label:SetTextColor(darkGray)
                panel:AddItem(s)
            end

            AddSlider("Intensity", "bloodmist_intensity", 0, 2, 2)
            AddSlider("Size", "bloodmist_size", 0.5, 2, 2)
            AddSlider("Lifetime", "bloodmist_lifetime", 0.5, 2, 2)
            AddSlider("Max Particles", "bloodmist_max_particles", 5, 40, 0)
            AddSlider("Gravity", "bloodmist_gravity", -50, 50, 0)
            AddSlider("Red", "bloodmist_color_r", 0, 255, 0)
            AddSlider("Green", "bloodmist_color_g", 0, 255, 0)
            AddSlider("Blue", "bloodmist_color_b", 0, 255, 0)
            AddSlider("Screen Fade", "bloodmist_screenfade", 0, 0.2, 3)

            -- Test button
            local btnTest = vgui.Create("DButton", panel)
            btnTest:SetText("Test Blood Mist")
            btnTest:SetTall(32)
            btnTest:SetTextColor(darkGray)
            btnTest.DoClick = function()
                if not GetConVar("bloodmist_enable"):GetBool() then return end
                local ply = LocalPlayer()
                if not IsValid(ply) then return end
                local pos = ply:GetShootPos() + ply:GetAimVector() * 60
                local caliber = GetConVar("bloodmist_caliber"):GetString()
                hook.Run("BloodMist_Spawn", pos, caliber)
                hook.Run("BloodMist_ScreenFade", GetConVar("bloodmist_screenfade"):GetFloat())
            end
            panel:AddItem(btnTest)
        end
    )
end)

