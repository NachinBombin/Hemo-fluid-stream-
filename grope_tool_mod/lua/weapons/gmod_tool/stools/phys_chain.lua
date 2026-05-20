TOOL.Category = "Construction"
TOOL.Name = "#tool.phys_chain.name" -- Теперь название в списке инструментов тоже переводится

if CLIENT then
    -- Выносим описание строк в отдельную функцию для удобства
    local function DoTranslation(isRussian)
        if isRussian then
            language.Add("tool.phys_chain.name", "Физическая Верёвка")
            language.Add("tool.phys_chain.desc", "Инструмент для создания физической верёвки UwU")
            language.Add("tool.phys_chain.0", "ЛКМ: Первая точка")
            language.Add("tool.phys_chain.1", "ЛКМ: Вторая точка")
            language.Add("tool.phys_chain.type", "Тип верёвки")
            language.Add("tool.phys_chain.rope", "Верёвка")
            language.Add("tool.phys_chain.cable", "Канат [UNSTABLE]")
            language.Add("tool.phys_chain.fire", "Огненная верёвка")
            language.Add("tool.phys_chain.electric", "Электрическая верёвка")
            language.Add("tool.phys_chain.cans", "Банки")
            language.Add("tool.phys_chain.props", "Свойства")
            language.Add("tool.phys_chain.sink", "Тонет")
            language.Add("tool.phys_chain.neutral", "Нейтрально")
            language.Add("tool.phys_chain.float", "Всплывает")
            language.Add("tool.phys_chain.nograv", "Невесомость")
            language.Add("tool.phys_chain.seglen", "Длина сегмента")
        else
            language.Add("tool.phys_chain.name", "Physical Rope")
            language.Add("tool.phys_chain.desc", "Tool for creating physical ropes with special effects UwU")
            language.Add("tool.phys_chain.0", "LMB: First point")
            language.Add("tool.phys_chain.1", "LMB: Second point")
            language.Add("tool.phys_chain.type", "Rope Type")
            language.Add("tool.phys_chain.rope", "Rope")
            language.Add("tool.phys_chain.cable", "Cable [UNSTABLE]")
            language.Add("tool.phys_chain.fire", "Fire Rope")
            language.Add("tool.phys_chain.electric", "Electric Rope")
            language.Add("tool.phys_chain.cans", "Cans")
            language.Add("tool.phys_chain.props", "Properties")
            language.Add("tool.phys_chain.sink", "Sinks")
            language.Add("tool.phys_chain.neutral", "Neutral")
            language.Add("tool.phys_chain.float", "Floats")
            language.Add("tool.phys_chain.nograv", "No Gravity")
            language.Add("tool.phys_chain.seglen", "Segment Length")
        end
    end

    -- Первоначальная инициализация
    DoTranslation(GetConVar("gmod_language"):GetString() == "ru")

    -- Слушатель изменений с задержкой
    cvars.AddChangeCallback("gmod_language", function(convar, old, new)
        -- Даем движку 0.1 секунды, чтобы он обновил свои локали, 
        -- прежде чем мы перезапишем свои
        timer.Simple(0.1, function()
            DoTranslation(new == "ru")
        end)
    end, "PhysChainLangFix")
end

-- Хук для материальности спец-верёвок (огненная и электрическая)
if SERVER then
    hook.Add("ShouldCollide", "PhysChainSpecialCollision", function(ent1, ent2)
        local specialPart = (ent1.IsFireChain or ent1.IsElectricChain) and ent1 or 
                           ((ent2.IsFireChain or ent2.IsElectricChain) and ent2 or nil)
        local ply = ent1:IsPlayer() and ent1 or (ent2:IsPlayer() and ent2 or nil)

        if IsValid(specialPart) and IsValid(ply) then
            return true 
        end
    end)
end

TOOL.ClientConVar["target_segment_length"] = "2" 
TOOL.ClientConVar["mass"] = "2"
TOOL.ClientConVar["buoyancy"] = "0.5"
TOOL.ClientConVar["nogravity"] = "0"
TOOL.ClientConVar["model_type"] = "models/rope/rope_c.mdl"

function TOOL:LeftClick( trace )
    if ( !IsValid( trace.Entity ) and !trace.Entity:IsWorld() ) then return false end
    if ( trace.Entity:IsPlayer() ) then return false end

    local stage = self:GetStage()

    if ( stage == 0 ) then
        local phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
        self:SetObject( 1, trace.Entity, trace.HitPos, phys, trace.PhysicsBone, trace.HitNormal )
        self:SetStage( 1 )
        return true
    end

    if ( stage == 1 ) then
        local ent1 = self:GetEnt( 1 )
        
        -- Проверка валидности первой точки
        if ( !IsValid(ent1) and !ent1:IsWorld() ) then 
            self:SetStage( 0 )
            return false 
        end

        local ent2 = trace.Entity
        local bone1 = self:GetBone( 1 )
        local bone2 = trace.PhysicsBone
        local pos1 = self:GetPos( 1 )
        local pos2 = trace.HitPos

        if ( SERVER ) then
            local target_len = math.Clamp(self:GetClientNumber("target_segment_length"), 0.1, 100)
            local custom_mass = math.Clamp(self:GetClientNumber("mass"), 0.1, 50)
            local custom_buoyancy = math.Clamp(self:GetClientNumber("buoyancy"), 0, 2)
            local no_gravity = self:GetClientNumber("nogravity") == 1
            local selected_model = self:GetClientInfo("model_type")
            
            local full_vec = pos2 - pos1
            local distance = full_vec:Length()
            local direction = full_vec:GetNormalized()
            
            local segments_count = math.Max(1, math.Round(distance / target_len))
            if segments_count > 100 then segments_count = 100 end 
            
            local actual_step = distance / segments_count

            undo.Create("Physical Chain")
            local prevEnt = ent1
            local prevBone = bone1

            for i = 1, segments_count do
                local propPos = pos1 + direction * (i * actual_step - actual_step * 0.5)
                
                local prop = ents.Create("prop_physics")
                prop:SetModel(selected_model) 
                prop:SetPos(propPos)
                
                -- ИСПРАВЛЕНИЕ ТЕКСТУР: Плоский белый материал для идеального окрашивания
                if selected_model:find("models/rope") then
                    prop:SetMaterial("models/debug/debugwhite")
                end
                
                -- ЦВЕТА: Установка чистых цветов на основе модели
                if selected_model == "models/rope/rope_c.mdl" or selected_model == "models/rope/rope_d.mdl" then
                    prop:SetColor(Color(255, 255, 255))
                elseif selected_model == "models/rope/rope_i.mdl" then
                    prop:SetColor(Color(222, 139, 55))
                elseif selected_model == "models/rope/rope_o.mdl" then
                    prop:SetColor(Color(63, 77, 85))
                else
                    prop:SetColor(Color(255, 255, 255))
                end
                
                local ang = direction:Angle()
                ang:RotateAroundAxis(ang:Right(), 90)
                prop:SetAngles(ang)
                prop:Spawn()

                local phys = prop:GetPhysicsObject()
                if IsValid(phys) then 
                    phys:SetMass(custom_mass)
                    phys:SetBuoyancyRatio(custom_buoyancy)
                    phys:EnableGravity(!no_gravity)
                    phys:SetDamping(2, 5) 
                    phys:Wake()
                end

                -- Логика Огненной веревки
                if selected_model == "models/rope/rope_i.mdl" then
                    prop.IsFireChain = true
                    prop:SetCollisionGroup(COLLISION_GROUP_PLAYER)
                    prop:SetCustomCollisionCheck(true)
                    prop.NextBurn = 0
                    prop:AddCallback("PhysicsCollide", function(s, colData)
                        local hitEnt = colData.HitEntity
                        if IsValid(hitEnt) and hitEnt:IsPlayer() then
                            if CurTime() > s.NextBurn then
                                hitEnt:Ignite(4)
                                s.NextBurn = CurTime() + 0.5
                            end
                        end
                    end)

                -- Логика Электрической веревки
                elseif selected_model == "models/rope/rope_o.mdl" then
                    prop.IsElectricChain = true
                    prop:SetCollisionGroup(COLLISION_GROUP_PLAYER)
                    prop:SetCustomCollisionCheck(true)
                    prop.NextShock = 0
                    prop:AddCallback("PhysicsCollide", function(s, colData)
                        local hitEnt = colData.HitEntity
                        if IsValid(hitEnt) and hitEnt:IsPlayer() then
                            if CurTime() > s.NextShock then
                                local newHealth = hitEnt:Health() - 5
                                if newHealth <= 0 then hitEnt:Kill() else hitEnt:SetHealth(newHealth) end
                                local effect = EffectData()
                                effect:SetOrigin(colData.HitPos)
                                util.Effect("StunstickImpact", effect)
                                s.NextShock = CurTime() + 0.5
                            end
                        end
                    end)
                else
                    prop:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
                end

                undo.AddEntity(prop)

                local attachStart = pos1 + direction * ((i - 1) * actual_step)
                local attachEnd = pos1 + direction * (i * actual_step)
                local LPos1 = prevEnt:WorldToLocal(attachStart)
                local LPos2 = prop:WorldToLocal(attachStart)

                if IsValid(prevEnt) then constraint.NoCollide(prevEnt, prop, prevBone, 0) end

                constraint.AdvBallsocket(prevEnt, prop, prevBone, 0, LPos1, LPos2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                constraint.Rope(prevEnt, prop, prevBone, 0, LPos1, LPos2, 0, 0, 0, 0, "cable/cable2", false)

                if i == segments_count then
                    local finalLPos1 = prop:WorldToLocal(attachEnd)
                    local finalLPos2 = ent2:WorldToLocal(attachEnd)
                    if ent2:IsWorld() then finalLPos2 = attachEnd end
                    
                    if IsValid(ent2) and not ent2:IsWorld() then constraint.NoCollide(prop, ent2, 0, bone2) end
                    
                    constraint.AdvBallsocket(prop, ent2, 0, bone2, finalLPos1, finalLPos2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                    constraint.Rope(prop, ent2, 0, bone2, finalLPos1, finalLPos2, 0, 0, 0, 0, "cable/cable2", false)
                end

                prevEnt = prop
                prevBone = 0
            end

            undo.SetPlayer(self:GetOwner())
            undo.Finish()
        end

        self:ClearObjects()
        self:SetStage(0)
        return true
    end
end

function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("Header", { Description = "#tool.phys_chain.desc" })
    
    local model_options = {
        ["#tool.phys_chain.rope"] = { phys_chain_model_type = "models/rope/rope_c.mdl" },
        ["#tool.phys_chain.cable"] = { phys_chain_model_type = "models/rope/rope_d.mdl" },
        ["#tool.phys_chain.fire"] = { phys_chain_model_type = "models/rope/rope_i.mdl" },
        ["#tool.phys_chain.electric"] = { phys_chain_model_type = "models/rope/rope_o.mdl" },
        ["#tool.phys_chain.cans"] = { phys_chain_model_type = "models/props_junk/popcan01a.mdl" }
    }
    CPanel:AddControl("ListBox", { Label = "#tool.phys_chain.type", Options = model_options })

    local options = {
        ["#tool.phys_chain.sink"] = { phys_chain_buoyancy = "0.1", phys_chain_nogravity = "0" },
        ["#tool.phys_chain.neutral"] = { phys_chain_buoyancy = "0.7", phys_chain_nogravity = "0" },
        ["#tool.phys_chain.float"] = { phys_chain_buoyancy = "2.5", phys_chain_nogravity = "0" },
        ["#tool.phys_chain.nograv"] = { phys_chain_buoyancy = "1.0", phys_chain_nogravity = "1" } 
    }
    CPanel:AddControl("ListBox", { Label = "#tool.phys_chain.props", Options = options })

    CPanel:AddControl("Slider", { Label = "#tool.phys_chain.seglen", Command = "phys_chain_target_segment_length", Type = "Float", Min = 0.1, Max = 20 })
end