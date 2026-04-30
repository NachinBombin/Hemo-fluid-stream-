if CLIENT then
    -- =========================
    -- Create ConVars (ON by default!)
    -- =========================
    local convars = {
        {"bloodmist_enable", "1"},
        {"bloodmist_intensity", "1"},
        {"bloodmist_size", "1"},
        {"bloodmist_lifetime", "1"},
        {"bloodmist_max_particles", "15"},
        {"bloodmist_gravity", "-10"},
        {"bloodmist_color_r", "140"},
        {"bloodmist_color_g", "0"},
        {"bloodmist_color_b", "0"},
        {"bloodmist_screenfade", "0.05"}
    }

    for _, v in ipairs(convars) do
        if not ConVarExists(v[1]) then
            CreateClientConVar(v[1], v[2], true, false)
        end
    end

    -- =========================
    -- Presets
    -- =========================
    local presets = {
        ["Realistic"] = {
            bloodmist_enable=1, bloodmist_intensity=1, bloodmist_size=1,
            bloodmist_lifetime=1, bloodmist_max_particles=15,
            bloodmist_gravity=-10, bloodmist_color_r=140,
            bloodmist_color_g=0, bloodmist_color_b=0,
            bloodmist_screenfade=0.05
        },
        ["Cinematic"] = {
            bloodmist_enable=1, bloodmist_intensity=1.4, bloodmist_size=1.3,
            bloodmist_lifetime=1.2, bloodmist_max_particles=25,
            bloodmist_gravity=-5, bloodmist_color_r=255,
            bloodmist_color_g=80, bloodmist_color_b=80,
            bloodmist_screenfade=0.1
        },
        ["Minimal"] = {
            bloodmist_enable=1, bloodmist_intensity=0.5, bloodmist_size=0.8,
            bloodmist_lifetime=0.7, bloodmist_max_particles=8,
            bloodmist_gravity=-15, bloodmist_color_r=150,
            bloodmist_color_g=0, bloodmist_color_b=0,
            bloodmist_screenfade=0.03
        }
    }

    -- =========================
    -- Spawnmenu in Utilities
    -- =========================
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
                    h:SetTextColor(Color(60,60,60))
                    return h
                end

                DarkHelp("BloodMist - Custom Mist Settings (Default ON)")

                -- Toggle button
                local toggle = vgui.Create("DCheckBoxLabel", panel)
                toggle:SetText("Enable Blood Mist")
                toggle:SetConVar("bloodmist_enable")
                toggle:SetTextColor(Color(60,60,60))
                toggle:SizeToContents()
                panel:AddItem(toggle)

                -- Presets
                DarkHelp("Presets")
                for name, data in pairs(presets) do
                    local btn = vgui.Create("DButton", panel)
                    btn:SetText(name)
                    btn:SetTall(28)
                    btn:SetTextColor(Color(60,60,60))
                    btn.DoClick = function()
                        for cvar,val in pairs(data) do
                            RunConsoleCommand(cvar, tostring(val))
                        end
                    end
                    panel:AddItem(btn)
                end

                -- Sliders helper
                local function AddSlider(text, cvar, min, max, dec)
                    local s = vgui.Create("DNumSlider", panel)
                    s:SetText(text)
                    s:SetMin(min)
                    s:SetMax(max)
                    s:SetDecimals(dec)
                    s:SetConVar(cvar)
                    s:SetTall(35)
                    s.Label:SetTextColor(Color(60,60,60))
                    panel:AddItem(s)
                end

                DarkHelp("Manual Sliders")
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
                btnTest:SetTextColor(Color(60,60,60))
                btnTest.DoClick = function()
                    if GetConVar("bloodmist_enable"):GetBool()==false then return end
                    local ply = LocalPlayer()
                    if not IsValid(ply) then return end
                    local pos = ply:GetShootPos() + ply:GetAimVector() * 60
                    hook.Run("BloodMist_Spawn", pos, "rifle")
                    hook.Run("BloodMist_ScreenFade", GetConVar("bloodmist_screenfade"):GetFloat())
                end
                panel:AddItem(btnTest)
            end
        )
    end)
end
