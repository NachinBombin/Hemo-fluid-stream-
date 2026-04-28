-- Client-side spawn menu options panel
if CLIENT then
    -- Table to store preset names
    local savedPresets = {}
    
    -- Table to store limb multipliers
    local limbMultipliers = {
        head = 1,
        neck = 1,
        torso = 1,
        arms = 1,
        legs = 1
    }
    
    -- Load saved presets from file
    local function LoadPresets()
        if file.Exists("nextgenblood4_presets.txt", "DATA") then
            local data = file.Read("nextgenblood4_presets.txt", "DATA")
            savedPresets = util.JSONToTable(data) or {}
        end
    end
    
    -- Save presets to file
    local function SavePresets()
        file.Write("nextgenblood4_presets.txt", util.TableToJSON(savedPresets))
    end
    
    -- Load limb multipliers from file
    local function LoadLimbMultipliers()
        if file.Exists("nextgenblood4_limb_multipliers.txt", "DATA") then
            local data = file.Read("nextgenblood4_limb_multipliers.txt", "DATA")
            local loaded = util.JSONToTable(data)
            if loaded then
                limbMultipliers = loaded
            end
        end
    end
    
    -- Save limb multipliers to file
    local function SaveLimbMultipliers()
        file.Write("nextgenblood4_limb_multipliers.txt", util.TableToJSON(limbMultipliers))
    end
    
    -- Load current settings from file or ConVars
    local function LoadCurrentSettings()
        if file.Exists("nextgenblood4_current_settings.txt", "DATA") then
            local data = file.Read("nextgenblood4_current_settings.txt", "DATA")
            local loaded = util.JSONToTable(data)
            if loaded then
                ApplySettings(loaded)
            end
        end
    end
    
    -- Save current settings to file
    local function SaveCurrentSettings()
        local settings = GetCurrentSettings()
        file.Write("nextgenblood4_current_settings.txt", util.TableToJSON(settings))
    end
    
    -- Get current settings as a table
    function GetCurrentSettings()
        return {
            size = GetConVar("nextgenblood4_stream_size"):GetFloat(),
            density = GetConVar("nextgenblood4_stream_density"):GetFloat(),
            force = GetConVar("nextgenblood4_stream_force"):GetFloat(),
            blood_volume = GetConVar("nextgenblood4_blood_sound_volume"):GetFloat(),
            squirt_volume = GetConVar("nextgenblood4_squirt_sound_volume"):GetFloat(),
            reps = GetConVar("nextgenblood4_blood_stream_reps_multiplier"):GetFloat(),
            spread = GetConVar("nextgenblood4_stream_spread"):GetFloat()
        }
    end
    
    -- Apply settings from a table
    function ApplySettings(settings)
        RunConsoleCommand("nextgenblood4_stream_size", tostring(settings.size))
        RunConsoleCommand("nextgenblood4_stream_density", tostring(settings.density))
        RunConsoleCommand("nextgenblood4_stream_force", tostring(settings.force))
        RunConsoleCommand("nextgenblood4_blood_sound_volume", tostring(settings.blood_volume))
        RunConsoleCommand("nextgenblood4_squirt_sound_volume", tostring(settings.squirt_volume))
        RunConsoleCommand("nextgenblood4_blood_stream_reps_multiplier", tostring(settings.reps))
        RunConsoleCommand("nextgenblood4_stream_spread", tostring(settings.spread))
        SaveCurrentSettings()
    end
    
    -- Get limb multiplier for a specific bone
    function GetLimbMultiplierForBone(boneName)
        if not boneName then return 1 end
        
        boneName = string.lower(boneName)
        
        -- Head
        if string.find(boneName, "head") then
            return limbMultipliers.head
        end
        
        -- Neck
        if string.find(boneName, "neck") then
            return limbMultipliers.neck
        end
        
        -- Arms (paired - left and right)
        if string.find(boneName, "clavicle") or string.find(boneName, "upperarm") or 
           string.find(boneName, "forearm") or string.find(boneName, "wrist") or string.find(boneName, "hand") then
            return limbMultipliers.arms
        end
        
        -- Legs (paired - left and right)
        if string.find(boneName, "thigh") or string.find(boneName, "calf") or 
           string.find(boneName, "foot") or string.find(boneName, "toe") then
            return limbMultipliers.legs
        end
        
        -- Torso (spine, pelvis, everything else)
        return limbMultipliers.torso
    end
    
    -- Create the main settings panel
    local function CreateBloodStreamPanel(panel)
        panel:ClearControls()
        
        -- Load presets and settings
        LoadPresets()
        LoadCurrentSettings()
        
        -- Title
        panel:Help("Next Gen Blood Stream Settings")
        panel:Help("Configure blood stream appearance and behavior")
        panel:Help(" ")
        
        -- Blood Stream Size
        local sizeSlider = panel:NumSlider("Blood Stream Size", "nextgenblood4_stream_size", 0.1, 10, 2)
        sizeSlider:SetTooltip("Size multiplier for blood particles (0.1 = tiny, 10 = huge)")
        sizeSlider.OnValueChanged = function() SaveCurrentSettings() end
        
        -- Blood Stream Density
        local densitySlider = panel:NumSlider("Blood Spurt Frequency", "nextgenblood4_stream_density", 0.1, 5, 2)
        densitySlider:SetTooltip("How often blood spurts out (0.1 = very frequent spurts, 5 = slow/rare spurts)")
        densitySlider.OnValueChanged = function() SaveCurrentSettings() end
        
        -- Blood Stream Force
        local forceSlider = panel:NumSlider("Blood Force", "nextgenblood4_stream_force", 0.1, 5, 2)
        forceSlider:SetTooltip("How far blood shoots out (0.1 = weak, 5 = powerful)")
        forceSlider.OnValueChanged = function() SaveCurrentSettings() end
        
        -- Blood Stream Duration (Reps)
        local repsSlider = panel:NumSlider("Duration Multiplier", "nextgenblood4_blood_stream_reps_multiplier", 0.1, 10, 2)
        repsSlider:SetTooltip("How long blood streams last (1 = normal, 10 = very long)")
        repsSlider.OnValueChanged = function() SaveCurrentSettings() end
        
        -- Blood Stream Spread (FOV)
        local spreadSlider = panel:NumSlider("Spread Angle (FOV)", "nextgenblood4_stream_spread", 0, 100, 1)
        spreadSlider:SetTooltip("Spray cone angle in degrees (0 = straight, 100 = wide)")
        spreadSlider.OnValueChanged = function() SaveCurrentSettings() end
        
        panel:Help(" ")
        panel:Help("Sound Settings")
        
        -- Blood Sound Volume
        local bloodVolSlider = panel:NumSlider("Blood Splatter Volume", "nextgenblood4_blood_sound_volume", 0, 1, 2)
        bloodVolSlider:SetTooltip("Volume for blood impact sounds")
        bloodVolSlider.OnValueChanged = function() SaveCurrentSettings() end
        
        -- Squirt Sound Volume
        local squirtVolSlider = panel:NumSlider("Squirt Sound Volume", "nextgenblood4_squirt_sound_volume", 0, 1, 2)
        squirtVolSlider:SetTooltip("Volume for blood squirting sounds")
        squirtVolSlider.OnValueChanged = function() SaveCurrentSettings() end
        
        panel:Help(" ")
        panel:Help("Presets")
        
        -- Preset list
        local presetList = vgui.Create("DListView")
        presetList:SetMultiSelect(false)
        presetList:AddColumn("Saved Presets")
        presetList:SetTall(100)
        
        for name, _ in pairs(savedPresets) do
            presetList:AddLine(name)
        end
        
        panel:AddItem(presetList)
        
        -- Load preset button
        local loadBtn = panel:Button("Load Selected Preset")
        loadBtn.DoClick = function()
            local selected = presetList:GetSelectedLine()
            if selected then
                local name = presetList:GetLine(selected):GetValue(1)
                local settings = savedPresets[name]
                if settings then
                    ApplySettings(settings)
                    notification.AddLegacy("Loaded preset: " .. name, NOTIFY_GENERIC, 3)
                    surface.PlaySound("buttons/button15.wav")
                end
            else
                notification.AddLegacy("No preset selected!", NOTIFY_ERROR, 3)
                surface.PlaySound("buttons/button10.wav")
            end
        end
        
        -- Save preset section
        panel:Help(" ")
        local presetName = panel:TextEntry("Preset Name")
        presetName:SetPlaceholderText("Enter preset name...")
        
        local saveBtn = panel:Button("Save Current Settings as Preset")
        saveBtn.DoClick = function()
            local name = presetName:GetValue()
            if name and name ~= "" then
                savedPresets[name] = GetCurrentSettings()
                SavePresets()
                
                -- Refresh list
                presetList:Clear()
                for pname, _ in pairs(savedPresets) do
                    presetList:AddLine(pname)
                end
                
                notification.AddLegacy("Saved preset: " .. name, NOTIFY_GENERIC, 3)
                surface.PlaySound("buttons/button14.wav")
                presetName:SetValue("")
            else
                notification.AddLegacy("Please enter a preset name!", NOTIFY_ERROR, 3)
                surface.PlaySound("buttons/button10.wav")
            end
        end
        
        -- Delete preset button
        local deleteBtn = panel:Button("Delete Selected Preset")
        deleteBtn.DoClick = function()
            local selected = presetList:GetSelectedLine()
            if selected then
                local name = presetList:GetLine(selected):GetValue(1)
                savedPresets[name] = nil
                SavePresets()
                presetList:RemoveLine(selected)
                notification.AddLegacy("Deleted preset: " .. name, NOTIFY_GENERIC, 3)
                surface.PlaySound("buttons/button14.wav")
            else
                notification.AddLegacy("No preset selected!", NOTIFY_ERROR, 3)
                surface.PlaySound("buttons/button10.wav")
            end
        end
        
        panel:Help(" ")
        panel:Help("Quick Presets")
        
        -- Quick preset buttons
        local realisticBtn = panel:Button("Realistic Blood")
        realisticBtn.DoClick = function()
            ApplySettings({
                size = 0.8,
                density = 0.7,
                force = 0.6,
                blood_volume = 0.8,
                squirt_volume = 0.6,
                reps = 1,
                spread = 8
            })
            notification.AddLegacy("Applied Realistic preset", NOTIFY_GENERIC, 3)
        end
        
        local cinematicBtn = panel:Button("Cinematic Action")
        cinematicBtn.DoClick = function()
            ApplySettings({
                size = 2,
                density = 2,
                force = 2.2,
                blood_volume = 1,
                squirt_volume = 0.8,
                reps = 1.8,
                spread = 15
            })
            notification.AddLegacy("Applied Cinematic preset", NOTIFY_GENERIC, 3)
        end
        
        local extremeBtn = panel:Button("Extreme Gore")
        extremeBtn.DoClick = function()
            ApplySettings({
                size = 3,
                density = 4,
                force = 2.5,
                blood_volume = 1,
                squirt_volume = 1,
                reps = 2.5,
                spread = 20
            })
            notification.AddLegacy("Applied Extreme Gore preset", NOTIFY_GENERIC, 3)
        end
        
        local minimalBtn = panel:Button("Minimal/Subtle")
        minimalBtn.DoClick = function()
            ApplySettings({
                size = 0.5,
                density = 0.3,
                force = 0.4,
                blood_volume = 0.5,
                squirt_volume = 0.3,
                reps = 0.5,
                spread = 5
            })
            notification.AddLegacy("Applied Minimal preset", NOTIFY_GENERIC, 3)
        end
        
        panel:Help(" ")
        local resetBtn = panel:Button("Reset to Defaults")
        resetBtn.DoClick = function()
            ApplySettings({
                size = 1,
                density = 1,
                force = 1,
                blood_volume = 1,
                squirt_volume = 1,
                reps = 1,
                spread = 5
            })
            notification.AddLegacy("Reset to default settings", NOTIFY_GENERIC, 3)
        end
    end
    
    -- Create the limb multipliers panel
    local function CreateLimbMultipliersPanel(panel)
        panel:ClearControls()
        
        -- Load limb multipliers
        LoadLimbMultipliers()
        
        -- Title
        panel:Help("Limb-Specific Blood Multipliers")
        panel:Help("Multiply FORCE and FREQUENCY for specific body parts")
        panel:Help("Higher values = blood shoots farther and spurts more often")
        panel:Help(" ")
        
        -- Head multiplier
        local headSlider = panel:NumSlider("Head Multiplier", "", 0.1, 5, 2)
        headSlider:SetValue(limbMultipliers.head)
        headSlider:SetTooltip("Multiplier for head wounds (2 = 2x force and 2x frequency)")
        headSlider.OnValueChanged = function(_, val)
            limbMultipliers.head = val
            SaveLimbMultipliers()
        end
        
        -- Neck multiplier
        local neckSlider = panel:NumSlider("Neck Multiplier", "", 0.1, 5, 2)
        neckSlider:SetValue(limbMultipliers.neck)
        neckSlider:SetTooltip("Multiplier for neck wounds")
        neckSlider.OnValueChanged = function(_, val)
            limbMultipliers.neck = val
            SaveLimbMultipliers()
        end
        
        -- Torso multiplier
        local torsoSlider = panel:NumSlider("Torso Multiplier", "", 0.1, 5, 2)
        torsoSlider:SetValue(limbMultipliers.torso)
        torsoSlider:SetTooltip("Multiplier for chest, spine, and pelvis wounds")
        torsoSlider.OnValueChanged = function(_, val)
            limbMultipliers.torso = val
            SaveLimbMultipliers()
        end
        
        -- Arms multiplier (paired)
        local armsSlider = panel:NumSlider("Arms Multiplier", "", 0.1, 5, 2)
        armsSlider:SetValue(limbMultipliers.arms)
        armsSlider:SetTooltip("Multiplier for both arm wounds (shoulders, upper arms, forearms, hands)")
        armsSlider.OnValueChanged = function(_, val)
            limbMultipliers.arms = val
            SaveLimbMultipliers()
        end
        
        -- Legs multiplier (paired)
        local legsSlider = panel:NumSlider("Legs Multiplier", "", 0.1, 5, 2)
        legsSlider:SetValue(limbMultipliers.legs)
        legsSlider:SetTooltip("Multiplier for both leg wounds (thighs, calves, feet)")
        legsSlider.OnValueChanged = function(_, val)
            limbMultipliers.legs = val
            SaveLimbMultipliers()
        end
        
        panel:Help(" ")
        panel:Help("Quick Presets")
        
        -- Realistic preset
        local realisticBtn = panel:Button("Realistic (Head > Neck > Torso)")
        realisticBtn.DoClick = function()
            limbMultipliers.head = 2.5
            limbMultipliers.neck = 2.0
            limbMultipliers.torso = 1.5
            limbMultipliers.arms = 1.0
            limbMultipliers.legs = 1.0
            
            headSlider:SetValue(limbMultipliers.head)
            neckSlider:SetValue(limbMultipliers.neck)
            torsoSlider:SetValue(limbMultipliers.torso)
            armsSlider:SetValue(limbMultipliers.arms)
            legsSlider:SetValue(limbMultipliers.legs)
            
            SaveLimbMultipliers()
            notification.AddLegacy("Applied Realistic limb multipliers", NOTIFY_GENERIC, 3)
            surface.PlaySound("buttons/button14.wav")
        end
        
        -- Action movie preset
        local actionBtn = panel:Button("Action Movie (Everything Bleeds)")
        actionBtn.DoClick = function()
            limbMultipliers.head = 3.0
            limbMultipliers.neck = 2.5
            limbMultipliers.torso = 2.0
            limbMultipliers.arms = 1.5
            limbMultipliers.legs = 1.5
            
            headSlider:SetValue(limbMultipliers.head)
            neckSlider:SetValue(limbMultipliers.neck)
            torsoSlider:SetValue(limbMultipliers.torso)
            armsSlider:SetValue(limbMultipliers.arms)
            legsSlider:SetValue(limbMultipliers.legs)
            
            SaveLimbMultipliers()
            notification.AddLegacy("Applied Action Movie limb multipliers", NOTIFY_GENERIC, 3)
            surface.PlaySound("buttons/button14.wav")
        end
        
        -- Reset button
        panel:Help(" ")
        local resetBtn = panel:Button("Reset All to 1x")
        resetBtn.DoClick = function()
            limbMultipliers.head = 1
            limbMultipliers.neck = 1
            limbMultipliers.torso = 1
            limbMultipliers.arms = 1
            limbMultipliers.legs = 1
            
            headSlider:SetValue(1)
            neckSlider:SetValue(1)
            torsoSlider:SetValue(1)
            armsSlider:SetValue(1)
            legsSlider:SetValue(1)
            
            SaveLimbMultipliers()
            notification.AddLegacy("Reset all limb multipliers to 1x", NOTIFY_GENERIC, 3)
            surface.PlaySound("buttons/button14.wav")
        end
        
        panel:Help(" ")
        panel:Help("Note: These multipliers only affect FORCE and FREQUENCY.")
        panel:Help("Size, duration, spread, and sounds stay the same.")
    end
    
    -- Add to spawn menu
    hook.Add("PopulateToolMenu", "BloodStream_AddToMenu", function()
        spawnmenu.AddToolMenuOption("Options", "Next Gen Blood", "BloodStreamSettings", "Blood Stream Settings", "", "", CreateBloodStreamPanel)
        spawnmenu.AddToolMenuOption("Options", "Next Gen Blood", "LimbMultipliers", "Limb Multipliers", "", "", CreateLimbMultipliersPanel)
    end)
    
    -- Load settings on first spawn
    hook.Add("Initialize", "BloodStream_LoadSettings", function()
        LoadCurrentSettings()
        LoadLimbMultipliers()
    end)
end