repeat task.wait() until game:IsLoaded()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HS = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- ===== Variables de atardecer (para restaurar) =====
local atardecerOn = false
local savedLighting = {}
local savedAtmosphere = nil
local savedClouds = {}
local savedRainSound = nil

-- 🌅 ATARDECER - TARDE CON NIEBLA Y LLUVIA
local function applyAtardecer()
    if not savedLighting.saved then
        savedLighting.ClockTime = Lighting.ClockTime
        savedLighting.Brightness = Lighting.Brightness
        savedLighting.FogStart = Lighting.FogStart
        savedLighting.FogEnd = Lighting.FogEnd
        savedLighting.FogColor = Lighting.FogColor
        savedLighting.ExposureCompensation = Lighting.ExposureCompensation
        savedLighting.GlobalShadows = Lighting.GlobalShadows
        savedLighting.saved = true
        
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            savedAtmosphere = {
                Density = atm.Density,
                Haze = atm.Haze,
                Glare = atm.Glare,
                Color = atm.Color,
                Parent = atm.Parent,
                exists = true
            }
        else
            savedAtmosphere = { exists = false }
        end
        
        local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
        if clouds then
            savedClouds.Cover = clouds.Cover
            savedClouds.Density = clouds.Density
            savedClouds.Color = clouds.Color
            savedClouds.exists = true
        else
            savedClouds.exists = false
        end
        
        local rain = workspace:FindFirstChild("RainSound")
        if rain and rain:IsA("Sound") then
            savedRainSound = { Volume = rain.Volume, Playing = rain.IsPlaying, exists = true }
        else
            savedRainSound = { exists = false }
        end
    end

    Lighting.ClockTime = 16.5
    Lighting.Brightness = 1.8
    Lighting.FogStart = 50
    Lighting.FogEnd = 250
    Lighting.FogColor = Color3.fromRGB(180, 180, 175)
    Lighting.ExposureCompensation = 0
    Lighting.GlobalShadows = true
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)

    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Parent = Lighting
    end
    atmosphere.Density = 0.45
    atmosphere.Haze = 3
    atmosphere.Glare = 0.15
    atmosphere.Color = Color3.fromRGB(255, 255, 255)

    local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
    if clouds then
        clouds.Cover = 0.65
        clouds.Density = 0.5
        clouds.Color = Color3.fromRGB(220, 220, 220)
    end

    local rainSound = workspace:FindFirstChild("RainSound")
    if rainSound and rainSound:IsA("Sound") then
        rainSound.Volume = 0.4
        rainSound.Looped = true
        rainSound:Play()
    end

    TweenService:Create(atmosphere, TweenInfo.new(5), { 
        Density = 0.5, 
        Haze = 3.5
    }):Play()
end

local function revertAtardecer()
    if not savedLighting.saved then return end
    Lighting.ClockTime = savedLighting.ClockTime
    Lighting.Brightness = savedLighting.Brightness
    Lighting.FogStart = savedLighting.FogStart
    Lighting.FogEnd = savedLighting.FogEnd
    Lighting.FogColor = savedLighting.FogColor
    Lighting.ExposureCompensation = savedLighting.ExposureCompensation
    Lighting.GlobalShadows = savedLighting.GlobalShadows

    if savedAtmosphere.exists then
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then
            atm.Density = savedAtmosphere.Density
            atm.Haze = savedAtmosphere.Haze
            atm.Glare = savedAtmosphere.Glare
            atm.Color = savedAtmosphere.Color
        end
    else
        local atm = Lighting:FindFirstChildOfClass("Atmosphere")
        if atm then atm:Destroy() end
    end

    local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
    if savedClouds.exists and clouds then
        clouds.Cover = savedClouds.Cover
        clouds.Density = savedClouds.Density
        clouds.Color = savedClouds.Color
    end

    local rainSound = workspace:FindFirstChild("RainSound")
    if savedRainSound.exists and rainSound and rainSound:IsA("Sound") then
        rainSound.Volume = savedRainSound.Volume
        if not savedRainSound.Playing then rainSound:Stop() end
    end
end

local function toggleAtardecer()
    atardecerOn = not atardecerOn
    if atardecerOn then
        applyAtardecer()
    else
        revertAtardecer()
    end
    if S.setAtardecerVisual then S.setAtardecerVisual(atardecerOn) end
    saveConfig()
end

-- ===== RESTO DEL CÓDIGO (no se modifica) =====
local removedAccessories = {}

local function removeCharacterAccessories()
    local char = LP.Character
    if not char then return end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Hat") or (child:IsA("Model") and child:FindFirstChild("Handle")) then
            table.insert(removedAccessories, {parent = child.Parent, acc = child})
            child.Parent = nil
        end
    end
end

local function restoreAccessories()
    for _, item in ipairs(removedAccessories) do
        if item.acc and not item.acc.Parent then
            item.acc.Parent = item.parent
        end
    end
    removedAccessories = {}
end

local function safeWritefile(path, data) if type(writefile) == "function" then pcall(writefile, path, data) end end
local function safeReadfile(path) if type(readfile) == "function" then local ok, data = pcall(readfile, path) return ok and data or nil end return nil end
local function safeIsfile(path) if type(isfile) == "function" then local ok, res = pcall(isfile, path) return ok and res end return false end
local function safeSetfpscap(v) if type(setfpscap) == "function" then pcall(setfpscap, v) end end
local function safeSethiddenproperty(obj, prop, val) if type(sethiddenproperty) == "function" then pcall(sethiddenproperty, obj, prop, val) end end

-- ===== TABLA PRINCIPAL S =====
local S = {
    NS = 60, CS = 30, LS = 15, LS2 = 24.5,
    speedMode = false, laggerMode = 0,
    antiRagdollEnabled = false,
    antiRagdollConn = nil,
    infJumpEnabled = false,
    infJumpMode = "manual",
    medusaCounterEnabled = false,
    medusaDebounce = false, medusaLastUsed = 0, medusaConns = {}, MEDUSA_COOLDOWN = 25,
    unwalkEnabled = false,
    autoLeftEnabled = false, autoRightEnabled = false,
    autoLeftSetVisual = nil, autoRightSetVisual = nil,
    _btnAAL = nil, _bsAAL = nil, _l1AAL = nil, _l2AAL = nil,
    _btnAAR = nil, _bsAAR = nil, _l1AAR = nil, _l2AAR = nil,
    _btnBAT = nil, _bsBAT = nil, _l1BAT = nil, _l2BAT = nil,
    _btnBAT2 = nil, _bsBAT2 = nil, _l1BAT2 = nil, _l2BAT2 = nil,
    _setPButtonActive = nil, speedCounterLabel = nil,
    batAimbotEnabled = false, batAimbotSetVisual = nil, batAimbotConn = nil,
    bat2Enabled = false, bat2SetVisual = nil, bat2Conn = nil,
    batCounterEnabled = false, batCounterConn = nil, batCounterDebounce = false,
    setBatCounterVisual = nil,
    fpsBoostEnabled = false,
    lockUIEnabled = false,
    mainMenuFrame = nil, miniToggleButton = nil, floatingPanelFrame = nil, floatingPanelGui = nil,
    _noclipTimer = 0, _fpsCount = 0, _lastFpsTime = tick(), currentFPS = 0,
    alConn = nil, arConn = nil, alPhase = 1, arPhase = 1,
    progressFill = nil, progressPct = nil, progressBarFrame = nil, topBarHUD = nil,
    stealActive = false,
    setLaggerVisual = nil, speedClk = nil, setFpsVisual = nil, setInfJumpVisual = nil,
    setAntiRagVisual = nil, setMedusaVisual = nil,
    setUnwalkVisual = nil, setAtardecerVisual = nil, setInstaGrab = nil,
    normalBox = nil, carryBox = nil, laggerBox = nil, lagger2Box = nil,
    radInput = nil, setLockUI_Visual = nil, setHideOpiumButtons = nil,
    autoTPDownEnabled = false, autoTPDownThreshold = 20, autoTPDownConn = nil,
    autoTPDownSetVisual = nil, autoTPDownFloatVisual = nil,
    autoTPDownThresholdBox = nil,
    stealDurationBox = nil,
    dropBrainrotActive = false,
    hideOpiumButtonsEnabled = false,
    KB = {
        DropBrainrot = {kb = Enum.KeyCode.X, gp = Enum.KeyCode.ButtonR2},
        AutoLeft = {kb = Enum.KeyCode.Z, gp = Enum.KeyCode.DPadLeft},
        AutoRight = {kb = Enum.KeyCode.C, gp = Enum.KeyCode.DPadRight},
        AutoBat = {kb = Enum.KeyCode.E, gp = Enum.KeyCode.ButtonY},
        AutoBat2 = {kb = Enum.KeyCode.G, gp = nil},
        TPFlor = {kb = Enum.KeyCode.F, gp = Enum.KeyCode.ButtonA},
        GuiHide = {kb = Enum.KeyCode.LeftControl, gp = Enum.KeyCode.ButtonSelect},
        SpeedToggle = {kb = Enum.KeyCode.Q, gp = Enum.KeyCode.DPadUp},
        LaggerToggle = {kb = Enum.KeyCode.R, gp = Enum.KeyCode.DPadDown},
        AutoTPDown = {kb = Enum.KeyCode.T, gp = nil},
        InfJump = {kb = Enum.KeyCode.I, gp = nil},
    },
    AP = {
        L1 = Vector3.new(-476.48, -6.28, 92.73), L2 = Vector3.new(-482.85, -5.03, 93.13),
        L_FACE = Vector3.new(-482.25, -4.96, 92.09),
        R1 = Vector3.new(-476.16, -6.52, 25.62), R2 = Vector3.new(-483.06, -5.03, 27.51),
        R_FACE = Vector3.new(-482.06, -6.93, 35.47),
    },
    Conns = {anchor = {}, progress = nil, aimbot = nil},
    moveConn = nil, speedEnabled = true, h = nil, hrp = nil,
    lastMoveDir = Vector3.new(0,0,0),
    MOVE_KEYS = {
        [Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true,
        [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
        [Enum.KeyCode.Up] = true, [Enum.KeyCode.Left] = true,
        [Enum.KeyCode.Down] = true, [Enum.KeyCode.Right] = true,
    },
    IS_TOUCH_DEVICE = UIS.TouchEnabled,
    IS_MOBILE = UIS.TouchEnabled and not UIS.KeyboardEnabled,
    CONFIG_FILE = "BRDUELS.json",
    _floatingButtons = {},
    autoTPDownCooldownUntil = 0,
    hittingCooldown = false,
}

-- ============================================================
-- AUTO STEAL DE ACE DUELS (COMPLETO)
-- ============================================================
local Steal = {
    AutoStealEnabled = false,
    StealRadius = 60,
    StealDuration = 1.4,
    Data = {},
    cachedPrompts = {},
    promptCacheTime = 0
}

S.Steal = Steal

local isStealing = false
local stealStartTime = nil
local lastStealTick = 0
local STEAL_COOLDOWN = 0.1
local PROMPT_CACHE_REFRESH = 0.15

local function resetProgressBar()
    if S.progressPct then S.progressPct.Text = "0%" end
    if S.progressFill then S.progressFill.Size = UDim2.new(0,0,1,0) end
end

local function isMyPlotByName(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

local function findNearestPrompt()
    local c = LP.Character
    if not c then return nil, math.huge end
    local root = c:FindFirstChild("HumanoidRootPart")
    if not root then return nil, math.huge end
    
    local ct = tick()
    
    if ct - Steal.promptCacheTime < PROMPT_CACHE_REFRESH and #Steal.cachedPrompts > 0 then
        local np, nd = nil, math.huge
        for _, data in ipairs(Steal.cachedPrompts) do
            if data.spawn and data.spawn.Parent and data.prompt and data.prompt.Parent then
                local dist = (data.spawn.Position - root.Position).Magnitude
                if dist <= Steal.StealRadius and dist < nd then
                    np = data.prompt
                    nd = dist
                end
            end
        end
        if np then return np, nd end
    end
    
    Steal.cachedPrompts = {}
    Steal.promptCacheTime = ct
    
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil, math.huge end
    
    local np, nd = nil, math.huge
    
    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        
        local pods = plot:FindFirstChild("AnimalPodiums")
        if not pods then continue end
        
        for _, pod in ipairs(pods:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local sp = base and base:FindFirstChild("Spawn")
                if sp then
                    local att = sp:FindFirstChild("PromptAttachment")
                    if att then
                        for _, child in ipairs(att:GetChildren()) do
                            if child:IsA("ProximityPrompt") then
                                local dist = (sp.Position - root.Position).Magnitude
                                table.insert(Steal.cachedPrompts, {prompt = child, spawn = sp})
                                if dist <= Steal.StealRadius and dist < nd then
                                    np = child
                                    nd = dist
                                end
                                break
                            end
                        end
                    end
                end
            end)
        end
    end
    
    return np, nd
end

local function executeSteal(prompt)
    local ct = tick()
    if ct - lastStealTick < STEAL_COOLDOWN then return end
    if isStealing then return end
    if not prompt or not prompt.Parent then return end
    
    if not Steal.Data[prompt] then
        Steal.Data[prompt] = {hold = {}, trigger = {}, ready = true}
        pcall(function()
            if getconnections then
                for _, c2 in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c2.Function then
                        table.insert(Steal.Data[prompt].hold, c2.Function)
                    end
                end
                for _, c2 in ipairs(getconnections(prompt.Triggered)) do
                    if c2.Function then
                        table.insert(Steal.Data[prompt].trigger, c2.Function)
                    end
                end
            else
                Steal.Data[prompt].useFallback = true
            end
        end)
    end
    
    local data = Steal.Data[prompt]
    if not data.ready then return end
    
    data.ready = false
    isStealing = true
    stealStartTime = ct
    lastStealTick = ct
    
    if S.Conns.progress then S.Conns.progress:Disconnect() end
    S.Conns.progress = RunService.Heartbeat:Connect(function()
        if not isStealing then
            S.Conns.progress:Disconnect()
            S.Conns.progress = nil
            return
        end
        local prog = math.clamp((tick() - stealStartTime) / Steal.StealDuration, 0, 1)
        if S.progressFill then S.progressFill.Size = UDim2.new(prog, 0, 1, 0) end
        if S.progressPct then S.progressPct.Text = math.floor(prog * 100) .. "%" end
    end)
    
    task.spawn(function()
        local ok = false
        
        pcall(function()
            if not data.useFallback and #data.hold > 0 then
                for _, fn in ipairs(data.hold) do
                    task.spawn(function() pcall(fn) end)
                end
                task.wait(Steal.StealDuration)
                for _, fn in ipairs(data.trigger) do
                    task.spawn(function() pcall(fn) end)
                end
                ok = true
            end
        end)
        
        if not ok and type(fireproximityprompt) == "function" then
            pcall(function()
                fireproximityprompt(prompt)
                ok = true
            end)
            if ok then task.wait(Steal.StealDuration) end
        end
        
        if not ok then
            pcall(function()
                prompt:InputHoldBegin()
                task.wait(Steal.StealDuration)
                prompt:InputHoldEnd()
            end)
        end
        
        task.wait(Steal.StealDuration * 0.3)
        
        if S.Conns.progress then
            S.Conns.progress:Disconnect()
            S.Conns.progress = nil
        end
        resetProgressBar()
        task.wait(0.05)
        data.ready = true
        isStealing = false
    end)
end

local function startAutoSteal()
    if S.Conns.autoSteal then return end
    
    S.Conns.autoSteal = RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or isStealing then return end
        
        local p = findNearestPrompt()
        if p then
            executeSteal(p)
        end
    end)
end

local function stopAutoSteal()
    if S.Conns.autoSteal then
        S.Conns.autoSteal:Disconnect()
        S.Conns.autoSteal = nil
    end
    isStealing = false
    lastStealTick = 0
    Steal.cachedPrompts = {}
    resetProgressBar()
end

-- ============================================================
-- NUEVO ANTI-RAGDOLL (integrado)
-- ============================================================
local function startAntiRagdoll()
    if S.antiRagdollConn then return end
    
    S.antiRagdollConn = RunService.Heartbeat:Connect(function()
        if not S.antiRagdollEnabled then return end
        
        local char = LP.Character
        if not char then return end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not (hum and root) then return end
        
        local s = hum:GetState()
        local ragdolled = (s == Enum.HumanoidStateType.Physics or s == Enum.HumanoidStateType.Ragdoll or s == Enum.HumanoidStateType.FallingDown)
        
        local endTime = LP:GetAttribute("RagdollEndTime")
        if endTime and (endTime - workspace:GetServerTimeNow()) > 0 then 
            ragdolled = true 
        end
        
        if ragdolled then
            pcall(function() LP:SetAttribute("RagdollEndTime", workspace:GetServerTimeNow()) end)
            
            for _, d in ipairs(char:GetDescendants()) do
                if d:IsA("BallSocketConstraint") or (d:IsA("Attachment") and d.Name:find("RagdollAttachment")) then 
                    d:Destroy() 
                end
            end
            
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("Motor6D") and obj.Enabled == false then 
                    obj.Enabled = true 
                end
            end
            
            if hum.Health > 0 then 
                hum:ChangeState(Enum.HumanoidStateType.Running) 
            end
            
            workspace.CurrentCamera.CameraSubject = hum
            root.Anchored = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

local function stopAntiRagdoll()
    if S.antiRagdollConn then 
        S.antiRagdollConn:Disconnect() 
        S.antiRagdollConn = nil 
    end
end

local function toggleAntiRag(on)
    S.antiRagdollEnabled = on
    if on then 
        startAntiRagdoll() 
    else 
        stopAntiRagdoll() 
    end
end

-- ============================================================
-- BAT V2 DE CLEAN HUB (adaptado como Bat Aimbot)
-- ============================================================
local BAT_V2_FOLLOW_DIST = 1.0
local BAT_V2_HEIGHT_OFFSET = 1.5
local BAT_V2_VERTICAL_OFFSET = 0.0
local BAT_V2_AIMBOT_SPEED = 60
local BAT_V2_SWING_COOLDOWN = 0.08
local BAT_V2_HIT_DIST = 4.5

local function findAnyToolV2()
    local c = LP.Character
    if c then
        for _, v in ipairs(c:GetChildren()) do if v:IsA("Tool") then return v end end
    end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, v in ipairs(bp:GetChildren()) do if v:IsA("Tool") then return v end end
    end
    return nil
end

local function getClosestPlayerV2()
    if not S.hrp then return nil, math.huge end
    local closest, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            local ph = p.Character:FindFirstChildOfClass("Humanoid")
            if tr and ph and ph.Health > 0 then
                local d = (S.hrp.Position - tr.Position).Magnitude
                if d < bestDist then bestDist = d; closest = p end
            end
        end
    end
    return closest, bestDist
end

local function tryHitBatV2()
    if S.hittingCooldown then return end
    S.hittingCooldown = true
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local tool = findAnyToolV2()
    if tool then
        if tool.Parent ~= char and hum then pcall(function() hum:EquipTool(tool) end) end
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then pcall(function() remote:FireServer() end) else pcall(function() tool:Activate() end) end
    end
    task.delay(BAT_V2_SWING_COOLDOWN, function() S.hittingCooldown = false end)
end

function startBatAimbot()
    if S.batAimbotConn then return end
    S.batAimbotConn = RunService.Heartbeat:Connect(function()
        if not S.batAimbotEnabled then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        local target, dist = getClosestPlayerV2()
        if target and target.Character then
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local targetVel = targetRoot.AssemblyLinearVelocity
                local moveDir = targetVel.Magnitude > 0.1 and targetVel.Unit or targetRoot.CFrame.LookVector
                local offset = moveDir * BAT_V2_FOLLOW_DIST + Vector3.new(0, BAT_V2_HEIGHT_OFFSET + BAT_V2_VERTICAL_OFFSET, 0)
                local desiredPos = targetRoot.Position + offset
                local toTarget = desiredPos - root.Position
                if toTarget.Magnitude > 0.5 then
                    local moveVec = toTarget.Unit * BAT_V2_AIMBOT_SPEED
                    root.AssemblyLinearVelocity = Vector3.new(moveVec.X, moveVec.Y, moveVec.Z)
                else
                    root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.95
                    if root.AssemblyLinearVelocity.Magnitude < 1 then root.AssemblyLinearVelocity = Vector3.zero end
                end
                local distToTarget = (root.Position - targetRoot.Position).Magnitude
                if distToTarget <= BAT_V2_HIT_DIST then tryHitBatV2() end
            end
        else
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity * 0.9
            if root.AssemblyLinearVelocity.Magnitude < 1 then root.AssemblyLinearVelocity = Vector3.zero end
        end
    end)
end

function stopBatAimbot()
    if S.batAimbotConn then S.batAimbotConn:Disconnect(); S.batAimbotConn = nil end
    S.batAimbotEnabled = false
    local c = LP.Character
    local root = c and c:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity = Vector3.zero end
    S.hittingCooldown = false
end

local function setBatAimbot(state)
    if S.batAimbotEnabled == state then return end
    S.batAimbotEnabled = state
    if state then
        if S.autoLeftEnabled then
            S.autoLeftEnabled = false
            if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
            stopAutoLeft()
        end
        if S.autoRightEnabled then
            S.autoRightEnabled = false
            if S.autoRightSetVisual then S.autoRightSetVisual(false) end
            stopAutoRight()
        end
        if S.bat2Enabled then setBat2(false) end
        startBatAimbot()
    else
        stopBatAimbot()
    end
    if S.batAimbotSetVisual then S.batAimbotSetVisual(state) end
    if S._setPButtonActive and S._btnBAT then
        S._setPButtonActive(S._btnBAT, S._bsBAT, S._l1BAT, S._l2BAT, state)
    end
    S.restartMovement()
    saveConfig()
end

S.ui = function(pcVal, mobVal) return S.IS_MOBILE and mobVal or pcVal end
S.getActiveSpeed = function()
    if S.laggerMode == 1 then return S.LS
    elseif S.laggerMode == 2 then return S.LS2
    elseif S.speedMode then return S.CS
    else return S.NS
    end
end

local saveConfig
local updateFloatingButtons

local function updateLaggerButtonVisual()
    local fb = S._floatingButtons
    if not fb.lagger then return end
    local text = ""
    local active = false
    if S.speedMode then
        text = "OFF"
        active = false
    else
        if S.laggerMode == 1 then
            text = "1"
            active = true
        elseif S.laggerMode == 2 then
            text = "2"
            active = true
        else
            text = "OFF"
            active = false
        end
    end
    fb.l2Lagger.Text = text
    S._setPButtonActive(fb.lagger, fb.strokeLagger, fb.l1Lagger, fb.l2Lagger, active)
end

S.setupSpeedBillboard = function(char)
    local head = char:WaitForChild("Head", 5)
    if not head then return end
    local oldBB = head:FindFirstChild("BRDUELSSpeedBB")
    if oldBB then oldBB:Destroy() end
    local bb = Instance.new("BillboardGui", head)
    bb.Name = "BRDUELSSpeedBB"
    bb.Size = UDim2.new(0, 100, 0, 32)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    local speedLbl = Instance.new("TextLabel", bb)
    speedLbl.Name = "SpeedBillLbl"
    speedLbl.Size = UDim2.new(1,0,1,0)
    speedLbl.BackgroundTransparency = 1
    speedLbl.Text = "0"
    speedLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedLbl.Font = Enum.Font.GothamBlack
    speedLbl.TextScaled = true
    speedLbl.TextStrokeTransparency = 0.1
    speedLbl.TextStrokeColor3 = Color3.new(0,0,0)
    S.speedCounterLabel = speedLbl
end

local _lastSpeedDisplay = -1
RunService.Heartbeat:Connect(function()
    if not (S.h and S.hrp) or not S.speedCounterLabel then return end
    local baseSpeed = 0
    if S.autoLeftEnabled or S.autoRightEnabled then
        baseSpeed = S.NS
    else
        if S.laggerMode == 1 then baseSpeed = S.LS
        elseif S.laggerMode == 2 then baseSpeed = S.LS2
        elseif S.speedMode then baseSpeed = S.CS
        else baseSpeed = S.NS end
    end
    if baseSpeed ~= _lastSpeedDisplay then
        _lastSpeedDisplay = baseSpeed
        S.speedCounterLabel.Text = tostring(baseSpeed)
    end
end)

local DROP_ASCEND_DURATION = 0.2
local DROP_ASCEND_SPEED = 150

local function runDropBrainrot()
    if S.dropBrainrotActive then return end
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    S.dropBrainrotActive = true
    local startTime = tick()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local r = char and char:FindFirstChild("HumanoidRootPart")
        if not r then
            conn:Disconnect()
            S.dropBrainrotActive = false
            return
        end
        if tick() - startTime >= DROP_ASCEND_DURATION then
            conn:Disconnect()
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {char}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local rayResult = workspace:Raycast(r.Position, Vector3.new(0, -2000, 0), raycastParams)
            if rayResult then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local offset = (hum and hum.HipHeight or 2) + (r.Size.Y / 2)
                r.CFrame = CFrame.new(r.Position.X, rayResult.Position.Y + offset, r.Position.Z)
                r.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
            S.dropBrainrotActive = false
            return
        end
        r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, DROP_ASCEND_SPEED, r.AssemblyLinearVelocity.Z)
    end)
end

S.startMovement = function()
    if S.moveConn then S.moveConn:Disconnect() end
    S.moveConn = RunService.RenderStepped:Connect(function()
        if not S.speedEnabled then return end
        if not (S.h and S.hrp) then return end
        if S.batAimbotEnabled or S.bat2Enabled or S.autoLeftEnabled or S.autoRightEnabled then return end
        local md = S.h.MoveDirection
        local spd
        if S.laggerMode ~= 0 then
            spd = (S.laggerMode == 1) and S.LS or S.LS2
        elseif S.speedMode then
            spd = S.CS
        else
            spd = S.NS
        end
        if md.Magnitude > 0 then
            S.lastMoveDir = md
            S.hrp.Velocity = Vector3.new(md.X * spd, S.hrp.Velocity.Y, md.Z * spd)
        elseif S.antiRagdollEnabled and S.lastMoveDir.Magnitude > 0 then
            local anyHeld = false
            for key in pairs(S.MOVE_KEYS) do
                if UIS:IsKeyDown(key) then anyHeld = true; break end
            end
            if anyHeld then
                S.hrp.Velocity = Vector3.new(S.lastMoveDir.X * spd, S.hrp.Velocity.Y, S.lastMoveDir.Z * spd)
            end
        end
    end)
end
S.stopMovement = function()
    if S.moveConn then S.moveConn:Disconnect(); S.moveConn = nil end
end
S.restartMovement = function() S.stopMovement(); S.startMovement() end
S.speedEnabled = true
S.startMovement()

-- ============================================================
-- INFINITE JUMP
-- ============================================================
local function startInfiniteJump()
    if S.IJ_JumpConn then S.IJ_JumpConn:Disconnect() end
    if S.IJ_HeartbeatConn then S.IJ_HeartbeatConn:Disconnect() end
    
    S.IJ_JumpConn = UIS.JumpRequest:Connect(function()
        if not S.infJumpEnabled then return end
        if S.infJumpMode ~= "manual" then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
        end
    end)
    
    S.IJ_HeartbeatConn = RunService.Heartbeat:Connect(function()
        if not S.infJumpEnabled then return end
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        if S.infJumpMode == "hold" then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local spaceHeld = UIS:IsKeyDown(Enum.KeyCode.Space) or (hum and hum.Jump == true)
            if spaceHeld and root.Velocity.Y < 30 then
                root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
            end
        end
        
        if root.Velocity.Y < -120 then
            root.Velocity = Vector3.new(root.Velocity.X, -120, root.Velocity.Z)
        end
    end)
end

local function stopInfiniteJump()
    if S.IJ_JumpConn then S.IJ_JumpConn:Disconnect(); S.IJ_JumpConn = nil end
    if S.IJ_HeartbeatConn then S.IJ_HeartbeatConn:Disconnect(); S.IJ_HeartbeatConn = nil end
    local char = LP.Character
    if char then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root and root.Velocity.Y > 55 then
            root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)
        end
    end
end

-- ============================================================
-- AUTO TP DOWN
-- ============================================================
local function startAutoTPDown()
    if S.autoTPDownConn then S.autoTPDownConn:Disconnect() end
    local _tpDownTimer = 0
    local _tpRayParams = nil
    S.autoTPDownConn = RunService.Heartbeat:Connect(function(dt)
        if not S.autoTPDownEnabled then return end
        if S.autoLeftEnabled or S.autoRightEnabled or S.batAimbotEnabled or S.bat2Enabled then return end
        if tick() < S.autoTPDownCooldownUntil then return end
        _tpDownTimer = _tpDownTimer + dt
        if _tpDownTimer < 0.05 then return end
        _tpDownTimer = 0
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if hrp.Position.Y >= S.autoTPDownThreshold then
            if not _tpRayParams then
                _tpRayParams = RaycastParams.new()
                _tpRayParams.FilterType = Enum.RaycastFilterType.Exclude
            end
            _tpRayParams.FilterDescendantsInstances = {char}
            local ray = workspace:Raycast(hrp.Position, Vector3.new(0, -1000, 0), _tpRayParams)
            if ray then
                local hum = char:FindFirstChildOfClass("Humanoid")
                local offset = (hum and hum.HipHeight or 2) + hrp.Size.Y / 2
                hrp.CFrame = CFrame.new(hrp.Position.X, ray.Position.Y + offset, hrp.Position.Z)
                hrp.AssemblyLinearVelocity = Vector3.zero
            end
        end
    end)
end

local function stopAutoTPDown()
    if S.autoTPDownConn then S.autoTPDownConn:Disconnect(); S.autoTPDownConn = nil end
end

saveConfig = function()
    pcall(function()
        local function ks(e)
            return {kb = e.kb and e.kb.Name or nil, gp = e.gp and e.gp.Name or nil}
        end
        local cfg = {
            normalSpeed = S.NS, carrySpeed = S.CS, laggerSpeed = S.LS, laggerSpeed2 = S.LS2,
            laggerMode = S.speedMode and 0 or S.laggerMode,
            dropBrainrotKey = ks(S.KB.DropBrainrot), autoLeftKey = ks(S.KB.AutoLeft),
            autoRightKey = ks(S.KB.AutoRight), autoBatKey = ks(S.KB.AutoBat),
            autoBat2Key = ks(S.KB.AutoBat2),
            tpFloorKey = ks(S.KB.TPFlor), guiHideKey = ks(S.KB.GuiHide),
            speedToggleKey = ks(S.KB.SpeedToggle), laggerToggleKey = ks(S.KB.LaggerToggle),
            grabRadius = Steal.StealRadius, antiRagdoll = S.antiRagdollEnabled,
            autoStealEnabled = Steal.AutoStealEnabled, 
            infiniteJump = S.infJumpEnabled,
            infiniteJumpMode = S.infJumpMode,
            medusaCounter = S.medusaCounterEnabled, carryMode = S.speedMode,
            batAimbot = S.batAimbotEnabled,
            bat2 = S.bat2Enabled,
            unwalkEnabled = S.unwalkEnabled,
            lockUI = S.lockUIEnabled, fpsBoost = S.fpsBoostEnabled,
            hideOpiumButtons = S.hideOpiumButtonsEnabled or false,
            autoTPDownEnabled = S.autoTPDownEnabled, autoTPDownThreshold = S.autoTPDownThreshold,
            autoTPDownKey = ks(S.KB.AutoTPDown),
            batCounter = S.batCounterEnabled,
            stealDuration = Steal.StealDuration,
            atardecer = atardecerOn,
            infJumpKey = ks(S.KB.InfJump),
            floatingPanelPos = S.floatingPanelFrame and {X = S.floatingPanelFrame.Position.X.Offset, Y = S.floatingPanelFrame.Position.Y.Offset} or nil,
        }
        local ok, data = pcall(function() return HS:JSONEncode(cfg) end)
        if ok and data then safeWritefile(S.CONFIG_FILE, data) end
    end)
end

local function resetFloatingPanel()
    if S.floatingPanelFrame then
        S.floatingPanelFrame.Position = UDim2.new(1, -138, 0.5, -150)
        saveConfig()
    end
end

local function resetProgressBar()
    if S.progressPct then S.progressPct.Text = "0%" end
    if S.progressFill then S.progressFill.Size = UDim2.new(0,0,1,0) end
end

local savedAnimate = nil

local function startUnwalk()
    local c = LP.Character
    if not c then return end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            t:Stop()
        end
    end
    local anim = c:FindFirstChild("Animate")
    if anim then
        if not savedAnimate then
            savedAnimate = anim:Clone()
        end
        anim:Destroy()
    end
    S.unwalkEnabled = true
end

local function stopUnwalk()
    if not S.unwalkEnabled then return end
    S.unwalkEnabled = false
    local c = LP.Character
    if c and savedAnimate then
        local existing = c:FindFirstChild("Animate")
        if existing and existing ~= savedAnimate then existing:Destroy() end
        savedAnimate.Parent = c
        savedAnimate.Disabled = false
        savedAnimate = nil
    end
end

local POS = S.AP

function startAutoLeft()
    if S.alConn then S.alConn:Disconnect() end
    S.alPhase = 1
    S.alConn = RunService.Heartbeat:Connect(function()
        if not S.autoLeftEnabled then return end
        local c = LP.Character; if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        local spd = S.NS
        if S.alPhase == 1 then
            local tgt = Vector3.new(POS.L1.X, root.Position.Y, POS.L1.Z)
            if (tgt - root.Position).Magnitude < 1 then
                S.alPhase = 2
                return
            end
            local d = (POS.L1 - root.Position)
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
        elseif S.alPhase == 2 then
            local tgt = Vector3.new(POS.L2.X, root.Position.Y, POS.L2.Z)
            if (tgt - root.Position).Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                S.autoLeftEnabled = false
                if S.alConn then S.alConn:Disconnect(); S.alConn = nil end
                S.alPhase = 1
                if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
                if S._setPButtonActive and S._btnAAL then
                    S._setPButtonActive(S._btnAAL, S._bsAAL, S._l1AAL, S._l2AAL, false)
                end
                task.defer(S.startMovement)
                return
            end
            local d = (POS.L2 - root.Position)
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
        end
    end)
end

function stopAutoLeft()
    if S.alConn then S.alConn:Disconnect(); S.alConn = nil end
    S.alPhase = 1
    local c = LP.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.zero, false) end
        local root = c:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0) end
    end
    S.autoLeftEnabled = false
    if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
end

function startAutoRight()
    if S.arConn then S.arConn:Disconnect() end
    S.arPhase = 1
    S.arConn = RunService.Heartbeat:Connect(function()
        if not S.autoRightEnabled then return end
        local c = LP.Character; if not c then return end
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end
        local spd = S.NS
        if S.arPhase == 1 then
            local tgt = Vector3.new(POS.R1.X, root.Position.Y, POS.R1.Z)
            if (tgt - root.Position).Magnitude < 1 then
                S.arPhase = 2
                return
            end
            local d = (POS.R1 - root.Position)
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
        elseif S.arPhase == 2 then
            local tgt = Vector3.new(POS.R2.X, root.Position.Y, POS.R2.Z)
            if (tgt - root.Position).Magnitude < 1 then
                hum:Move(Vector3.zero, false)
                root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                S.autoRightEnabled = false
                if S.arConn then S.arConn:Disconnect(); S.arConn = nil end
                S.arPhase = 1
                if S.autoRightSetVisual then S.autoRightSetVisual(false) end
                if S._setPButtonActive and S._btnAAR then
                    S._setPButtonActive(S._btnAAR, S._bsAAR, S._l1AAR, S._l2AAR, false)
                end
                task.defer(S.startMovement)
                return
            end
            local d = (POS.R2 - root.Position)
            local mv = Vector3.new(d.X, 0, d.Z).Unit
            hum:Move(mv, false)
            root.AssemblyLinearVelocity = Vector3.new(mv.X * spd, root.AssemblyLinearVelocity.Y, mv.Z * spd)
        end
    end)
end

function stopAutoRight()
    if S.arConn then S.arConn:Disconnect(); S.arConn = nil end
    S.arPhase = 1
    local c = LP.Character
    if c then
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then hum:Move(Vector3.zero, false) end
        local root = c:FindFirstChild("HumanoidRootPart")
        if root then root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0) end
    end
    S.autoRightEnabled = false
    if S.autoRightSetVisual then S.autoRightSetVisual(false) end
end

-- ===== BAT 2 (Clean Hub style) =====
local function findBat2Tool()
    local char = LP.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then
            return tool
        end
    end
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then
                return tool
            end
        end
    end
    return nil
end

local function getClosestBat2Target()
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local closest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if tRoot and hum and hum.Health > 0 then
                local dist = (tRoot.Position - root.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = tRoot
                end
            end
        end
    end
    return closest
end

local BAT2_SWING_COOLDOWN = 0.08

local function tryHitBat2()
    if S.hittingCooldown then return end
    S.hittingCooldown = true
    pcall(function()
        local c = LP.Character
        if not c then return end
        local tool = findBat2Tool()
        if not tool then return end
        if tool.Parent ~= c then
            local hum = c:FindFirstChildOfClass("Humanoid")
            if hum then pcall(function() hum:EquipTool(tool) end) end
        end
        local remote = tool:FindFirstChildOfClass("RemoteEvent")
        if remote then
            pcall(function() remote:FireServer() end)
        else
            pcall(function() tool:Activate() end)
        end
    end)
    task.delay(BAT2_SWING_COOLDOWN, function() S.hittingCooldown = false end)
end

local BAT2_CHASE_SPEED = 58
local BAT2_PREDICT_TIME = 0.14
local BAT2_Y_OFFSET = 3.7
local BAT2_TILT_SPEED = 42
local BAT2_MAX_TILT = 2.5

function startBat2()
    if S.bat2Conn then S.bat2Conn:Disconnect() end
    S.bat2Enabled = true

    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = false
    end

    S.bat2Conn = RunService.RenderStepped:Connect(function()
        if not S.bat2Enabled then return end

        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        if not char:FindFirstChildOfClass("Tool") then
            local bat = findBat2Tool()
            if bat then pcall(function() hum:EquipTool(bat) end) end
        end

        local target = getClosestBat2Target()
        if target then
            local targetVel = target.AssemblyLinearVelocity
            local myPos = root.Position
            local targetPos = target.Position

            local predictTime = math.clamp(targetVel.Magnitude / 150, 0.05, BAT2_PREDICT_TIME)
            local predictedPos = targetPos + targetVel * predictTime
            predictedPos = predictedPos + target.CFrame.LookVector * 0.3

            local direction = predictedPos - myPos
            local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
            local chaseSpeed = BAT2_CHASE_SPEED

            local desiredHeight = targetPos.Y + BAT2_Y_OFFSET
            local yVel = (desiredHeight - myPos.Y) * 19.5 + targetVel.Y * 0.8
            if hum.FloorMaterial ~= Enum.Material.Air then
                yVel = math.max(yVel, 13)
            end
            yVel = math.clamp(yVel, -70, 110)

            local desiredVel = Vector3.new(flatDir.X * chaseSpeed, yVel, flatDir.Z * chaseSpeed)
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(desiredVel, 0.8)

            local toPredict = predictedPos - myPos
            if toPredict.Magnitude > 0.1 then
                local goalCF = CFrame.lookAt(myPos, predictedPos)
                local curCF = root.CFrame
                local diffCF = curCF:Inverse() * goalCF
                local rx, ry, rz = diffCF:ToEulerAnglesXYZ()
                rx = math.clamp(rx, -BAT2_MAX_TILT, BAT2_MAX_TILT)
                ry = math.clamp(ry, -BAT2_MAX_TILT, BAT2_MAX_TILT)
                rz = math.clamp(rz, -BAT2_MAX_TILT, BAT2_MAX_TILT)
                root.AssemblyAngularVelocity = root.CFrame:VectorToWorldSpace(
                    Vector3.new(rx * BAT2_TILT_SPEED, ry * BAT2_TILT_SPEED, rz * BAT2_TILT_SPEED)
                )
            end

            local distToTarget = (targetPos - myPos).Magnitude
            if distToTarget <= 16 then
                tryHitBat2()
            end
        else
            root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            root.AssemblyAngularVelocity = Vector3.zero
        end
    end)
end

function stopBat2()
    if S.bat2Conn then S.bat2Conn:Disconnect(); S.bat2Conn = nil end
    S.bat2Enabled = false
    local c = LP.Character
    if c then
        local root = c:FindFirstChild("HumanoidRootPart")
        local hum = c:FindFirstChildOfClass("Humanoid")
        if root then
            root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
            root.AssemblyAngularVelocity = Vector3.zero
        end
        if hum then
            hum.AutoRotate = true
        end
    end
    S.hittingCooldown = false
end

local function setBat2(state)
    if S.bat2Enabled == state then return end
    S.bat2Enabled = state
    if state then
        if S.autoLeftEnabled then
            S.autoLeftEnabled = false
            if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
            stopAutoLeft()
        end
        if S.autoRightEnabled then
            S.autoRightEnabled = false
            if S.autoRightSetVisual then S.autoRightSetVisual(false) end
            stopAutoRight()
        end
        if S.batAimbotEnabled then setBatAimbot(false) end
        startBat2()
    else
        stopBat2()
    end
    if S.bat2SetVisual then S.bat2SetVisual(state) end
    if S._setPButtonActive and S._btnBAT2 then
        S._setPButtonActive(S._btnBAT2, S._bsBAT2, S._l1BAT2, S._l2BAT2, state)
    end
    S.restartMovement()
    saveConfig()
end

-- ===== BAT COUNTER =====
local BAT_COUNTER_SLAP_LIST = {"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}

local function findBatForCounter()
    local c = LP.Character; if not c then return nil end
    local bp = LP:FindFirstChildOfClass("Backpack")
    for _, name in ipairs(BAT_COUNTER_SLAP_LIST) do
        local t = c:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if t then return t end
    end
    for _, ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
    if bp then for _, ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
    return nil
end

local function swingBatForCounter(bat, char)
    local hum2 = char:FindFirstChildOfClass("Humanoid")
    if bat.Parent ~= char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end; task.wait(0.03) end
    local remote = bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
    if remote and remote:IsA("RemoteEvent") then
        pcall(function() remote:FireServer() end); task.wait(0.05); pcall(function() remote:FireServer() end)
    else pcall(function() bat:Activate() end); task.wait(0.05); pcall(function() bat:Activate() end) end
end

local function startBatCounter()
    if S.batCounterConn then S.batCounterConn:Disconnect() end
    S.batCounterConn = RunService.Heartbeat:Connect(function()
        if not S.batCounterEnabled then return end
        if S.batCounterDebounce then return end
        local char = LP.Character; if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        local st = hum:GetState()
        local isRagged = st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown
        if isRagged then
            S.batCounterDebounce = true
            task.spawn(function()
                local bat = findBatForCounter()
                if bat then swingBatForCounter(bat, char) end
                task.wait(0.1)
                S.batCounterDebounce = false
            end)
        end
    end)
end

local function stopBatCounter()
    if S.batCounterConn then S.batCounterConn:Disconnect(); S.batCounterConn = nil end
    S.batCounterDebounce = false
end

-- ===== MEDUSA =====
local function findMedusa()
    local char = LP.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("medusa") or name:find("head") or name:find("stone") then
                return tool
            end
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("medusa") or name:find("head") or name:find("stone") then
                    return tool
                end
            end
        end
    end
    return nil
end

local function useMedusaCounter()
    if S.medusaDebounce then return end
    if tick() - S.medusaLastUsed < S.MEDUSA_COOLDOWN then return end
    local char = LP.Character
    if not char then return end
    S.medusaDebounce = true
    local med = findMedusa()
    if not med then
        S.medusaDebounce = false
        return
    end
    if med.Parent ~= char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:EquipTool(med) end
    end
    pcall(function() med:Activate() end)
    S.medusaLastUsed = tick()
    S.medusaDebounce = false
end

local function onAnchorChanged(part)
    return part:GetPropertyChangedSignal("Anchored"):Connect(function()
        if part.Anchored and part.Transparency == 1 and S.medusaCounterEnabled then
            useMedusaCounter()
        end
    end)
end

local function setupMedusaCounter(char)
    for _, c in pairs(S.medusaConns) do pcall(function() c:Disconnect() end) end
    S.medusaConns = {}
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            table.insert(S.medusaConns, onAnchorChanged(part))
        end
    end
    table.insert(S.medusaConns, char.DescendantAdded:Connect(function(part)
        if part:IsA("BasePart") then
            table.insert(S.medusaConns, onAnchorChanged(part))
        end
    end))
end

local function stopMedusaCounter()
    for _, c in pairs(S.medusaConns) do pcall(function() c:Disconnect() end) end
    S.medusaConns = {}
end

-- ===== FPS BOOST =====
local function applyFPSBoost()
    safeSetfpscap(999999999)
    removeCharacterAccessories()
    local function pO(v)
        pcall(function()
            if v:IsA("Model") then
                v.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled
                v.ModelStreamingMode = Enum.ModelStreamingMode.Nonatomic
            elseif v:IsA("MeshPart") then
                v.CastShadow = false; v.DoubleSided = false
                v.RenderFidelity = Enum.RenderFidelity.Performance
            elseif v:IsA("BasePart") then
                v.CastShadow = false; v.Material = Enum.Material.Plastic; v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1
            elseif v:IsA("SpecialMesh") then
                v.TextureId = ""
            elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke")
                or v:IsA("Sparkles") or v:IsA("ParticleEmitter")
                or v:IsA("Trail") or v:IsA("Beam") then
                v.Enabled = false
            elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then
                v:Destroy()
            elseif v:IsA("Attachment") then
                v.Visible = false
            end
        end)
    end
    for _, v in pairs(workspace:GetDescendants()) do pO(v) end
    pcall(function()
        local L = Lighting
        for _, v in pairs(L:GetDescendants()) do
            pcall(function()
                if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect")
                    or v:IsA("BlurEffect") or v:IsA("SunRaysEffect")
                    or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds")
                    or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then
                    v:Destroy()
                end
            end)
        end
        safeSethiddenproperty(L, "Technology", Enum.Technology.Legacy)
        L.GlobalShadows = false; L.FogEnd = 9e9; L.Brightness = 0
        local ter = workspace:FindFirstChildOfClass("Terrain")
        if ter then
            safeSethiddenproperty(ter, "Decoration", false)
            ter.WaterReflectance = 0; ter.WaterTransparency = 0.7
            ter.WaterWaveSize = 0; ter.WaterWaveSpeed = 0
        end
    end)
    workspace.DescendantAdded:Connect(function(v)
        if S.fpsBoostEnabled then task.spawn(pO, v) end
    end)
end

local function stopFPSBoost()
    S.fpsBoostEnabled = false
    restoreAccessories()
end

local function runTPFloor()
    pcall(function()
        local char = LP.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local rp = RaycastParams.new()
        rp.FilterDescendantsInstances = {char}
        rp.FilterType = Enum.RaycastFilterType.Exclude
        local res = workspace:Raycast(hrp.Position, Vector3.new(0, -500, 0), rp)
        if res then
            hrp.CFrame = CFrame.new(hrp.Position.X, res.Position.Y + hrp.Size.Y/2 + 0.5, hrp.Position.Z)
            hrp.Velocity = Vector3.zero
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
            pcall(function() hrp.AssemblyAngularVelocity = Vector3.zero end)
        end
    end)
end

-- ===== NOCLIP =====
local _noclipCache = {}
RunService.Stepped:Connect(function(_, dt)
    S._noclipTimer = S._noclipTimer + dt
    if S._noclipTimer < 0.15 then return end
    S._noclipTimer = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local cached = _noclipCache[p]
            if not cached or cached.char ~= p.Character then
                local parts = {}
                for _, obj in ipairs(p.Character:GetDescendants()) do
                    if obj:IsA("BasePart") then table.insert(parts, obj) end
                end
                _noclipCache[p] = {char = p.Character, parts = parts}
                cached = _noclipCache[p]
            end
            for _, part in ipairs(cached.parts) do
                if part and part.Parent then part.CanCollide = false end
            end
        else
            _noclipCache[p] = nil
        end
    end
end)

RunService.RenderStepped:Connect(function()
    S._fpsCount = S._fpsCount + 1
    local now = tick()
    if now - S._lastFpsTime >= 1 then
        S.currentFPS = math.floor(S._fpsCount/(now - S._lastFpsTime))
        S._fpsCount = 0
        S._lastFpsTime = now
    end
end)

updateFloatingButtons = function()
    if not S._setPButtonActive then return end
    local fb = S._floatingButtons
    if fb.lagger then updateLaggerButtonVisual() end
    if fb.carry then S._setPButtonActive(fb.carry, fb.strokeCarry, fb.l1Carry, fb.l2Carry, S.speedMode) end
    if fb.autoLeft then S._setPButtonActive(fb.autoLeft, fb.strokeAutoLeft, fb.l1AutoLeft, fb.l2AutoLeft, S.autoLeftEnabled) end
    if fb.autoRight then S._setPButtonActive(fb.autoRight, fb.strokeAutoRight, fb.l1AutoRight, fb.l2AutoRight, S.autoRightEnabled) end
    if fb.bat then S._setPButtonActive(fb.bat, fb.strokeBat, fb.l1Bat, fb.l2Bat, S.batAimbotEnabled) end
    if fb.bat2 then S._setPButtonActive(fb.bat2, fb.strokeBat2, fb.l1Bat2, fb.l2Bat2, S.bat2Enabled) end
    if fb.autoTPDown then S._setPButtonActive(fb.autoTPDown, fb.strokeAutoTPDown, fb.l1AutoTPDown, fb.l2AutoTPDown, S.autoTPDownEnabled) end
end

local function setUILock(enabled)
    S.lockUIEnabled = enabled
    if S.mainMenuFrame then S.mainMenuFrame.Active = not enabled end
    if S.miniToggleButton then S.miniToggleButton.Active = not enabled end
    if S.floatingPanelFrame then S.floatingPanelFrame.Active = not enabled end
end

local function makeDraggable(frame, isFloatingPanel)
    local dragging, dragStart, startPos = false, nil, nil
    frame.InputBegan:Connect(function(inp)
        if S.lockUIEnabled then return end
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if S.lockUIEnabled or not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local delta = inp.Position - dragStart
            if delta.Magnitude > 2 then
                local newX = startPos.X.Offset + delta.X
                local newY = startPos.Y.Offset + delta.Y
                frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
                if isFloatingPanel then saveConfig() end
            end
        end
    end)
end

-- ============================================================
-- CONSTRUCCIÓN DE LA INTERFAZ CON CORES VERMELHO, PRETO E BRANCO
-- ============================================================
local function buildGui()
    -- CORES
    local C_BG_OUTER  = Color3.fromRGB(10,0,0)    -- Preto avermelhado
    local C_BG_INNER  = Color3.fromRGB(8,0,0)     -- Preto avermelhado
    local C_WHITE     = Color3.fromRGB(255,255,255)
    local C_DIM       = Color3.fromRGB(180,180,180)
    local C_ACCENT    = Color3.fromRGB(200,0,0)   -- VERMELHO VIVO
    local C_BORDER    = Color3.fromRGB(80,0,0)    -- Vermelho escuro
    local C_CARD_BG   = Color3.fromRGB(12,0,0)    -- Preto avermelhado
    local C_ACTIVE_BG = Color3.fromRGB(30,5,5)    -- Vermelho muito escuro

    local TOTAL_W  = 480
    local TOTAL_H  = 482
    local SIDEBAR_W = 155

    local old = game:GetService("CoreGui"):FindFirstChild("BRDUELS")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "BRDUELS"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 100
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LP:WaitForChild("PlayerGui") end

    local main = Instance.new("Frame", gui)
    main.Name = "Main"
    main.Size = UDim2.new(0, TOTAL_W, 0, TOTAL_H)
    main.Position = UDim2.new(0, 40, 0, 0)
    main.BackgroundColor3 = C_BG_OUTER
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Visible = true
    local mainCorner = Instance.new("UICorner", main)
    mainCorner.CornerRadius = UDim.new(0, 12)
    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = C_BORDER
    mainStroke.Thickness = 1
    S.mainMenuFrame = main
    makeDraggable(main, false)

    local sidebar = Instance.new("Frame", main)
    sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
    sidebar.Position = UDim2.new(0,0,0,0)
    sidebar.BackgroundColor3 = C_BG_OUTER
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants = true
    local sidebarCorner = Instance.new("UICorner", sidebar)
    sidebarCorner.CornerRadius = UDim.new(0, 12)

    local divider = Instance.new("Frame", main)
    divider.Size = UDim2.new(0,1,1,-24)
    divider.Position = UDim2.new(0,SIDEBAR_W,0,12)
    divider.BackgroundColor3 = C_BORDER
    divider.BorderSizePixel = 0

    -- HEADER
    local headerFrame = Instance.new("Frame", sidebar)
    headerFrame.Size = UDim2.new(1,0,0,200)
    headerFrame.Position = UDim2.new(0,0,0,0)
    headerFrame.BackgroundTransparency = 1
    headerFrame.ClipsDescendants = false

    local titleLabel = Instance.new("TextLabel", headerFrame)
    titleLabel.Size = UDim2.new(1,-16,0,32)
    titleLabel.Position = UDim2.new(0,8,0,10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌹 BR DUELS"
    titleLabel.TextColor3 = C_ACCENT
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextSize = 20
    titleLabel.TextXAlignment = Enum.TextXAlignment.Center
    titleLabel.ZIndex = 5

    local logoImage = Instance.new("ImageLabel", headerFrame)
    logoImage.Size = UDim2.new(0, 100, 0, 100)
    logoImage.Position = UDim2.new(0.5, -50, 0, 70)
    logoImage.BackgroundTransparency = 1
    logoImage.Image = "rbxassetid://122790624923322"
    logoImage.ScaleType = Enum.ScaleType.Fit
    logoImage.ZIndex = 5

    local accentLine = Instance.new("Frame", headerFrame)
    accentLine.Size = UDim2.new(0,40,0,2)
    accentLine.Position = UDim2.new(0.5,-20,0,175)
    accentLine.BackgroundColor3 = C_ACCENT
    accentLine.BackgroundTransparency = 0.6
    accentLine.BorderSizePixel = 0
    accentLine.ZIndex = 5
    Instance.new("UICorner", accentLine).CornerRadius = UDim.new(1,0)

    local logoDiv = Instance.new("Frame", sidebar)
    logoDiv.Size = UDim2.new(1,-20,0,1)
    logoDiv.Position = UDim2.new(0,10,0,200)
    logoDiv.BackgroundColor3 = C_BORDER
    logoDiv.BorderSizePixel = 0

    -- PESTAÑAS
    local TAB_NAMES = {"Speed", "Main", "Move", "Config"}
    local tabBtns = {}

    local tabListFrame = Instance.new("Frame", sidebar)
    tabListFrame.Size = UDim2.new(1,0,1,-210)
    tabListFrame.Position = UDim2.new(0,0,0,205)
    tabListFrame.BackgroundTransparency = 1

    local tabLL = Instance.new("UIListLayout", tabListFrame)
    tabLL.SortOrder = Enum.SortOrder.LayoutOrder
    tabLL.Padding = UDim.new(0, 8)
    local tabPad = Instance.new("UIPadding", tabListFrame)
    tabPad.PaddingLeft = UDim.new(0, 12)
    tabPad.PaddingRight = UDim.new(0, 12)
    tabPad.PaddingTop = UDim.new(0, 8)

    local function switchTab(name) end

    for i, name in ipairs(TAB_NAMES) do
        local btn = Instance.new("TextButton", tabListFrame)
        btn.Size = UDim2.new(1,0,0,36)
        btn.BackgroundColor3 = C_CARD_BG
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.LayoutOrder = i
        btn.AutoButtonColor = false

        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = C_BORDER
        stroke.Thickness = 1
        stroke.Transparency = 0.4

        local lbl = Instance.new("TextLabel", btn)
        lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = name
        lbl.TextColor3 = C_DIM
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.TextXAlignment = Enum.TextXAlignment.Center

        local activeIndicator = Instance.new("Frame", btn)
        activeIndicator.Size = UDim2.new(0.8,0,0,2)
        activeIndicator.Position = UDim2.new(0.1,0,1,-2)
        activeIndicator.BackgroundColor3 = C_ACCENT
        activeIndicator.BorderSizePixel = 0
        activeIndicator.Visible = (name == "Speed")
        Instance.new("UICorner", activeIndicator).CornerRadius = UDim.new(1,0)

        tabBtns[name] = {bg = btn, lbl = lbl, ind = activeIndicator, stroke = stroke}
        btn.MouseButton1Click:Connect(function()
            switchTab(name)
        end)
    end

    local rightPanel = Instance.new("Frame", main)
    rightPanel.Size = UDim2.new(0, TOTAL_W - SIDEBAR_W - 1, 1, 0)
    rightPanel.Position = UDim2.new(0, SIDEBAR_W+1, 0, 0)
    rightPanel.BackgroundColor3 = C_BG_INNER
    rightPanel.BorderSizePixel = 0
    rightPanel.ClipsDescendants = true
    local rightCorner = Instance.new("UICorner", rightPanel)
    rightCorner.CornerRadius = UDim.new(0, 12)

    local topBar = Instance.new("Frame", rightPanel)
    topBar.Size = UDim2.new(1,0,0,44)
    topBar.BackgroundColor3 = C_BG_INNER
    topBar.BorderSizePixel = 0
    local topBarDiv = Instance.new("Frame", rightPanel)
    topBarDiv.Size = UDim2.new(1,-20,0,1)
    topBarDiv.Position = UDim2.new(10,0,0,44)
    topBarDiv.BackgroundColor3 = C_BORDER
    topBarDiv.BorderSizePixel = 0

    local panelTitle = Instance.new("TextLabel", topBar)
    panelTitle.Size = UDim2.new(1,-50,1,0)
    panelTitle.Position = UDim2.new(0,16,0,0)
    panelTitle.BackgroundTransparency = 1
    panelTitle.Text = "Speed"
    panelTitle.TextColor3 = C_ACCENT
    panelTitle.Font = Enum.Font.GothamBlack
    panelTitle.TextSize = 16
    panelTitle.TextXAlignment = Enum.TextXAlignment.Left

    local closeBtn = Instance.new("TextButton", topBar)
    closeBtn.Size = UDim2.new(0,28,0,28)
    closeBtn.Position = UDim2.new(1,-34,0.5,-14)
    closeBtn.BackgroundColor3 = Color3.fromRGB(20,0,0)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "–"
    closeBtn.TextColor3 = C_ACCENT
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 20
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 50
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        if S.miniToggleButton then S.miniToggleButton.Visible = true end
    end)

    local contentArea = Instance.new("Frame", rightPanel)
    contentArea.Size = UDim2.new(1,0,1,-45)
    contentArea.Position = UDim2.new(0,0,0,45)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true

    -- FUNCIONES AUXILIARES PARA LA GUI
    local function buildGui_createScrollingPages(rightPanel)
        local pages = {}
        for _, n in ipairs({"Speed", "Main", "Move", "Config"}) do
            local sf = Instance.new("ScrollingFrame", rightPanel)
            sf.Size = UDim2.new(1,0,1,0)
            sf.BackgroundTransparency = 1
            sf.BorderSizePixel = 0
            sf.ScrollBarThickness = 6
            sf.ScrollBarImageColor3 = C_WHITE
            sf.ScrollingEnabled = true
            sf.Visible = false
            sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
            sf.CanvasSize = UDim2.new(0,0,0,0)

            local ll = Instance.new("UIListLayout", sf)
            ll.SortOrder = Enum.SortOrder.LayoutOrder
            ll.Padding = UDim.new(0, 4)
            ll.FillDirection = Enum.FillDirection.Vertical

            local pp = Instance.new("UIPadding", sf)
            pp.PaddingLeft = UDim.new(0, 12)
            pp.PaddingRight = UDim.new(0, 12)
            pp.PaddingTop = UDim.new(0, 12)
            pp.PaddingBottom = UDim.new(0, 40)

            pages[n] = sf
        end
        return pages
    end

    local rowCounts = {Speed = 0, Main = 0, Move = 0, Config = 0}

    local function mkCard(pg, pages, h)
        local C_CARD = Color3.fromRGB(12,0,0)
        rowCounts[pg] = rowCounts[pg] + 1
        local f = Instance.new("Frame", pages[pg])
        f.Size = UDim2.new(1,0,0,h or 38)
        f.BackgroundColor3 = C_CARD
        f.BorderSizePixel = 0
        f.LayoutOrder = rowCounts[pg]
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
        local stroke = Instance.new("UIStroke", f)
        stroke.Color = Color3.fromRGB(80,0,0)
        stroke.Thickness = 0.5
        return f
    end

    local function mkToggle(pg, pages, label, defKey, defOn, onToggle, onKeyChanged)
        local C_ON = C_ACCENT   -- vermelho
        local C_OFF = Color3.fromRGB(60,0,0)
        local C_WHITE = Color3.fromRGB(255,255,255)
        local card = mkCard(pg, pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0,140,1,0)
        lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = C_ACCENT
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local keyBtn = nil
        if defKey then
            local keyName = (defKey or Enum.KeyCode.Unknown).Name
            keyBtn = Instance.new("TextButton", card)
            keyBtn.Size = UDim2.new(0,60,0,24)
            keyBtn.Position = UDim2.new(1,-110,0.5,-12)
            keyBtn.BackgroundColor3 = Color3.fromRGB(30,0,0)
            keyBtn.BorderSizePixel = 0
            keyBtn.Text = keyName
            keyBtn.TextColor3 = C_WHITE
            keyBtn.Font = Enum.Font.GothamBold
            keyBtn.TextSize = 10
            Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 5)
            local listening = false
            keyBtn.MouseButton1Click:Connect(function()
                if listening then return end
                listening = true
                local prev = keyBtn.Text
                keyBtn.Text = "..."
                local conn
                conn = UIS.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.Keyboard or inp.UserInputType == Enum.UserInputType.Gamepad1 then
                        if inp.KeyCode ~= Enum.KeyCode.Escape then
                            keyBtn.Text = inp.KeyCode.Name
                            if onKeyChanged then onKeyChanged(inp.KeyCode, inp.UserInputType == Enum.UserInputType.Gamepad1) end
                        else
                            keyBtn.Text = prev
                        end
                        listening = false
                        conn:Disconnect()
                    end
                end)
            end)
        end

        local pillBg = Instance.new("TextButton", card)
        pillBg.Size = UDim2.new(0,28,0,16)
        pillBg.Position = UDim2.new(1,-36,0.5,-8)
        pillBg.BackgroundColor3 = defOn and C_ON or C_OFF
        pillBg.BorderSizePixel = 0
        pillBg.Text = ""
        pillBg.AutoButtonColor = false
        pillBg.ZIndex = 5
        Instance.new("UICorner", pillBg).CornerRadius = UDim.new(1,0)

        local dot = Instance.new("Frame", pillBg)
        dot.Size = UDim2.new(0,12,0,12)
        dot.Position = defOn and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
        dot.BackgroundColor3 = defOn and Color3.fromRGB(12,0,0) or C_WHITE
        dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)

        local isOn = defOn or false
        local function setV(on)
            isOn = on
            pillBg.BackgroundColor3 = on and C_ON or C_OFF
            dot.Position = on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
            dot.BackgroundColor3 = on and Color3.fromRGB(12,0,0) or C_WHITE
        end

        pillBg.MouseButton1Click:Connect(function()
            isOn = not isOn
            setV(isOn)
            if onToggle then onToggle(isOn) end
        end)

        if defOn then setV(true) end
        return setV, keyBtn
    end

    local function mkInput(pg, pages, label, default, onChange)
        local C_WHITE = Color3.fromRGB(255,255,255)
        local card = mkCard(pg, pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0.5,-10,1,0)
        lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = C_ACCENT
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local box = Instance.new("TextBox", card)
        box.Size = UDim2.new(0,70,0,28)
        box.Position = UDim2.new(1,-78,0.5,-14)
        box.BackgroundColor3 = Color3.fromRGB(30,0,0)
        box.BorderSizePixel = 0
        box.Text = tostring(default)
        box.TextColor3 = C_WHITE
        box.Font = Enum.Font.GothamBlack
        box.TextSize = 11
        box.ClearTextOnFocus = false
        box.MultiLine = false
        pcall(function() box.ReturnKeyType = Enum.ReturnKeyType.Done end)
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

        local lastVal = tostring(default)
        local isFocused = false

        local function applyValue()
            if not isFocused then return end
            isFocused = false
            local n = tonumber(box.Text)
            if n then
                lastVal = tostring(n)
                box.Text = lastVal
                onChange(n)
            else
                box.Text = lastVal
            end
            pcall(function() box:ReleaseFocus(false) end)
        end

        box.Focused:Connect(function()
            isFocused = true
        end)

        box.FocusLost:Connect(function()
            if isFocused then
                isFocused = false
                local n = tonumber(box.Text)
                if n then
                    lastVal = tostring(n)
                    box.Text = lastVal
                    onChange(n)
                else
                    box.Text = lastVal
                end
            end
        end)

        pcall(function()
            box.ReturnPressedFromOnScreenKeyboard:Connect(function()
                applyValue()
            end)
        end)

        UIS.TouchTap:Connect(function(positions)
            if not isFocused then return end
            pcall(function()
                local abs = box.AbsolutePosition
                local sz  = box.AbsoluteSize
                local tp  = positions[1]
                if tp then
                    local inside = tp.X >= abs.X and tp.X <= abs.X + sz.X
                               and tp.Y >= abs.Y and tp.Y <= abs.Y + sz.Y
                    if not inside then
                        applyValue()
                    end
                end
            end)
        end)

        return box
    end

    local function buildGui_createMiniToggle(gui, showGuiFn)
        local miniToggleBtn = Instance.new("TextButton", gui)
        miniToggleBtn.Name = "MiniToggle"
        miniToggleBtn.Size = UDim2.new(0, 80, 0, 36)
        miniToggleBtn.Position = UDim2.new(0, 38, 0, 60)
        miniToggleBtn.BackgroundColor3 = Color3.fromRGB(10,0,0)
        miniToggleBtn.BorderSizePixel = 0
        miniToggleBtn.Text = ""
        miniToggleBtn.ZIndex = 20
        miniToggleBtn.Visible = false
        Instance.new("UICorner", miniToggleBtn).CornerRadius = UDim.new(0, 8)
        local miniStroke = Instance.new("UIStroke", miniToggleBtn)
        miniStroke.Color = C_ACCENT
        miniStroke.Thickness = 1
        miniStroke.Transparency = 0.92
        local miniMainText = Instance.new("TextLabel", miniToggleBtn)
        miniMainText.Size = UDim2.new(1,0,1,0)
        miniMainText.Position = UDim2.new(0,0,0,0)
        miniMainText.BackgroundTransparency = 1
        miniMainText.Text = "🌹"
        miniMainText.TextColor3 = C_ACCENT
        miniMainText.Font = Enum.Font.GothamBlack
        miniMainText.TextSize = 20
        miniMainText.TextXAlignment = Enum.TextXAlignment.Center
        miniMainText.ZIndex = 21
        makeDraggable(miniToggleBtn, false)
        miniToggleBtn.MouseButton1Click:Connect(showGuiFn)
        return miniToggleBtn
    end

    local pages = buildGui_createScrollingPages(contentArea)
    local activePage = pages["Speed"]
    activePage.Visible = true

    switchTab = function(name)
        if activePage then activePage.Visible = false end
        activePage = pages[name]
        activePage.Visible = true
        panelTitle.Text = name
        for tName, tData in pairs(tabBtns) do
            local isActive = (tName == name)
            tData.lbl.TextColor3 = isActive and C_ACCENT or C_DIM
            tData.ind.Visible = isActive
            tData.bg.BackgroundColor3 = isActive and C_ACTIVE_BG or C_CARD_BG
            tData.stroke.Transparency = isActive and 0 or 0.4
        end
    end

    -- ===== SPEED TAB =====
    S.normalBox = mkInput("Speed", pages, "Normal Speed", S.NS, function(v)
        if v>0 and v<=500 then S.NS = v; S.restartMovement(); saveConfig() end
    end)
    S.carryBox = mkInput("Speed", pages, "Carry Speed", S.CS, function(v)
        if v>0 and v<=500 then S.CS = v; S.restartMovement(); saveConfig() end
    end)
    S.laggerBox = mkInput("Speed", pages, "Lagger Speed 1", S.LS, function(v)
        if v>0 and v<=500 then S.LS = v; S.restartMovement(); saveConfig() end
    end)
    S.lagger2Box = mkInput("Speed", pages, "Lagger Speed 2", S.LS2, function(v)
        if v>0 and v<=500 then S.LS2 = v; S.restartMovement(); saveConfig() end
    end)

    S.speedClk, _ = mkToggle("Speed", pages, "Carry Mode", S.KB.SpeedToggle.kb, false, function(on)
        if on then
            if S.laggerMode ~= 0 then
                S.laggerMode = 0
                if S.setLaggerVisual then S.setLaggerVisual(false) end
                updateLaggerButtonVisual()
            end
        end
        S.speedMode = on
        S.restartMovement()
        updateFloatingButtons()
        saveConfig()
    end, function(k, isGp)
        if isGp then S.KB.SpeedToggle.gp = k; S.KB.SpeedToggle.kb = nil
        else S.KB.SpeedToggle.kb = k; S.KB.SpeedToggle.gp = nil end
        saveConfig()
    end)

    S.setLaggerVisual, _ = mkToggle("Speed", pages, "Lagger Mode", S.KB.LaggerToggle.kb, false, function(on)
        if on then
            if S.speedMode then
                S.speedMode = false
                if S.speedClk then S.speedClk(false) end
            end
            if S.laggerMode == 0 then
                S.laggerMode = 1
            elseif S.laggerMode == 1 then
                S.laggerMode = 2
            else
                S.laggerMode = 0
            end
        else
            S.laggerMode = 0
        end
        updateLaggerButtonVisual()
        S.restartMovement()
        updateFloatingButtons()
        saveConfig()
    end, function(k, isGp)
        if isGp then S.KB.LaggerToggle.gp = k; S.KB.LaggerToggle.kb = nil
        else S.KB.LaggerToggle.kb = k; S.KB.LaggerToggle.gp = nil end
        saveConfig()
    end)

    -- ===== MAIN TAB =====
    S.setAtardecerVisual, _ = mkToggle("Main", pages, "Atardecer", nil, false, function(on)
        if on then applyAtardecer() else revertAtardecer() end
        atardecerOn = on
        saveConfig()
    end, nil)

    S.setFpsVisual, _ = mkToggle("Main", pages, "FPS Boost", nil, false, function(on)
        S.fpsBoostEnabled = on
        if on then applyFPSBoost() else stopFPSBoost() end
        saveConfig()
    end, nil)

    S.setInfJumpVisual, _ = mkToggle("Main", pages, "Inf Jump", S.KB.InfJump.kb, false, function(on)
        S.infJumpEnabled = on
        if on then startInfiniteJump() else stopInfiniteJump() end
        saveConfig()
    end, function(k, isGp)
        if isGp then S.KB.InfJump.gp = k; S.KB.InfJump.kb = nil
        else S.KB.InfJump.kb = k; S.KB.InfJump.gp = nil end
        saveConfig()
    end)

    local jumpModeCard = mkCard("Main", pages, 38)
    local jumpModeContainer = Instance.new("Frame", jumpModeCard)
    jumpModeContainer.Size = UDim2.new(1,0,1,0)
    jumpModeContainer.BackgroundTransparency = 1
    jumpModeContainer.BorderSizePixel = 0

    local manuelBtn = Instance.new("TextButton", jumpModeContainer)
    manuelBtn.Size = UDim2.new(0.5, -3, 1, -4)
    manuelBtn.Position = UDim2.new(0, 0, 0, 2)
    manuelBtn.BackgroundColor3 = C_WHITE
    manuelBtn.BorderSizePixel = 0
    manuelBtn.Text = "Manual"
    manuelBtn.TextColor3 = C_ACCENT
    manuelBtn.Font = Enum.Font.GothamBold
    manuelBtn.TextSize = 10
    manuelBtn.AutoButtonColor = false
    Instance.new("UICorner", manuelBtn).CornerRadius = UDim.new(0, 6)
    local ms = Instance.new("UIStroke", manuelBtn)
    ms.Color = Color3.fromRGB(80,0,0)
    ms.Thickness = 0.5

    local holdBtn = Instance.new("TextButton", jumpModeContainer)
    holdBtn.Size = UDim2.new(0.5, -3, 1, -4)
    holdBtn.Position = UDim2.new(0.5, 3, 0, 2)
    holdBtn.BackgroundColor3 = Color3.fromRGB(60,0,0)
    holdBtn.BorderSizePixel = 0
    holdBtn.Text = "Hold"
    holdBtn.TextColor3 = C_WHITE
    holdBtn.Font = Enum.Font.GothamBold
    holdBtn.TextSize = 10
    holdBtn.AutoButtonColor = false
    Instance.new("UICorner", holdBtn).CornerRadius = UDim.new(0, 6)
    local hs = Instance.new("UIStroke", holdBtn)
    hs.Color = Color3.fromRGB(80,0,0)
    hs.Thickness = 0.5

    local function updateInfJumpModeUI()
        if S.infJumpMode == "manual" then
            manuelBtn.BackgroundColor3 = C_WHITE
            manuelBtn.TextColor3 = C_ACCENT
            holdBtn.BackgroundColor3 = Color3.fromRGB(60,0,0)
            holdBtn.TextColor3 = C_WHITE
        else
            manuelBtn.BackgroundColor3 = Color3.fromRGB(60,0,0)
            manuelBtn.TextColor3 = C_WHITE
            holdBtn.BackgroundColor3 = C_WHITE
            holdBtn.TextColor3 = C_ACCENT
        end
    end

    manuelBtn.MouseButton1Click:Connect(function()
        S.infJumpMode = "manual"
        updateInfJumpModeUI()
        saveConfig()
    end)

    holdBtn.MouseButton1Click:Connect(function()
        S.infJumpMode = "hold"
        updateInfJumpModeUI()
        saveConfig()
    end)

    updateInfJumpModeUI()

    -- ===== MOVE TAB =====
    local batToggleVisual, batKeyBtn = mkToggle("Move", pages, "Bat Aimbot", S.KB.AutoBat.kb, false, function(on)
        if on then
            if S.autoLeftEnabled then
                S.autoLeftEnabled = false
                if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
                stopAutoLeft()
            end
            if S.autoRightEnabled then
                S.autoRightEnabled = false
                if S.autoRightSetVisual then S.autoRightSetVisual(false) end
                stopAutoRight()
            end
        end
        setBatAimbot(on)
        updateFloatingButtons()
    end, function(k, isGp)
        if isGp then S.KB.AutoBat.gp = k; S.KB.AutoBat.kb = nil
        else S.KB.AutoBat.kb = k; S.KB.AutoBat.gp = nil end
        saveConfig()
    end)
    S.batAimbotSetVisual = batToggleVisual

    local bat2ToggleVisual, _ = mkToggle("Move", pages, "Bat 2", S.KB.AutoBat2.kb, false, function(on)
        if on then
            if S.autoLeftEnabled then
                S.autoLeftEnabled = false
                if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
                stopAutoLeft()
            end
            if S.autoRightEnabled then
                S.autoRightEnabled = false
                if S.autoRightSetVisual then S.autoRightSetVisual(false) end
                stopAutoRight()
            end
        end
        setBat2(on); updateFloatingButtons()
    end, function(k, isGp)
        if isGp then S.KB.AutoBat2.gp = k; S.KB.AutoBat2.kb = nil
        else S.KB.AutoBat2.kb = k; S.KB.AutoBat2.gp = nil end
        saveConfig()
    end)
    S.bat2SetVisual = bat2ToggleVisual

    S.setBatCounterVisual, _ = mkToggle("Move", pages, "Bat Counter", nil, false, function(on)
        S.batCounterEnabled = on
        if on then startBatCounter() else stopBatCounter() end
        saveConfig()
    end, nil)

    local setALVis, _ = mkToggle("Move", pages, "Auto Left", S.KB.AutoLeft.kb, false, function(on)
        S.autoLeftEnabled = on
        if on then
            if S.autoRightEnabled then
                S.autoRightEnabled = false; stopAutoRight()
                if S.autoRightSetVisual then S.autoRightSetVisual(false) end
            end
            if S.batAimbotEnabled then setBatAimbot(false) end
            if S.bat2Enabled then setBat2(false) end
            startAutoLeft()
        else
            stopAutoLeft()
        end
        if S.autoLeftSetVisual then S.autoLeftSetVisual(on) end
        S.restartMovement(); updateFloatingButtons(); saveConfig()
    end, function(k, isGp)
        if isGp then S.KB.AutoLeft.gp = k; S.KB.AutoLeft.kb = nil
        else S.KB.AutoLeft.kb = k; S.KB.AutoLeft.gp = nil end
        saveConfig()
    end)
    S.autoLeftSetVisual = setALVis

    local setARVis, _ = mkToggle("Move", pages, "Auto Right", S.KB.AutoRight.kb, false, function(on)
        S.autoRightEnabled = on
        if on then
            if S.autoLeftEnabled then
                S.autoLeftEnabled = false; stopAutoLeft()
                if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
            end
            if S.batAimbotEnabled then setBatAimbot(false) end
            if S.bat2Enabled then setBat2(false) end
            startAutoRight()
        else
            stopAutoRight()
        end
        if S.autoRightSetVisual then S.autoRightSetVisual(on) end
        S.restartMovement(); updateFloatingButtons(); saveConfig()
    end, function(k, isGp)
        if isGp then S.KB.AutoRight.gp = k; S.KB.AutoRight.kb = nil
        else S.KB.AutoRight.kb = k; S.KB.AutoRight.gp = nil end
        saveConfig()
    end)
    S.autoRightSetVisual = setARVis

    S.autoTPDownSetVisual, _ = mkToggle("Move", pages, "Auto TP Down", S.KB.AutoTPDown.kb, false, function(on)
        S.autoTPDownEnabled = on
        if on then startAutoTPDown() else stopAutoTPDown() end
        if S.autoTPDownFloatVisual then S.autoTPDownFloatVisual(on) end
        saveConfig()
    end, function(k, isGp)
        if isGp then S.KB.AutoTPDown.gp = k; S.KB.AutoTPDown.kb = nil
        else S.KB.AutoTPDown.kb = k; S.KB.AutoTPDown.gp = nil end
        saveConfig()
    end)

    S.setUnwalkVisual, _ = mkToggle("Move", pages, "Unwalk", nil, false, function(on)
        if on then startUnwalk() else stopUnwalk() end
        saveConfig()
    end, nil)

    S.setAntiRagVisual, _ = mkToggle("Move", pages, "Anti Ragdoll", nil, false, function(on)
        toggleAntiRag(on)
        saveConfig()
    end, nil)

    S.setMedusaVisual, _ = mkToggle("Move", pages, "Medusa Counter", nil, false, function(on)
        S.medusaCounterEnabled = on
        if on then
            setupMedusaCounter(LP.Character)
        else
            stopMedusaCounter()
        end
        saveConfig()
    end, nil)

    local function actionRow(pg, lbl, keyEntry)
        local card = mkCard(pg, pages, 38)
        local lblObj = Instance.new("TextLabel", card)
        lblObj.Size = UDim2.new(0,120,1,0); lblObj.Position = UDim2.new(0,12,0,0)
        lblObj.BackgroundTransparency = 1; lblObj.Text = lbl
        lblObj.TextColor3 = C_ACCENT
        lblObj.Font = Enum.Font.GothamBold; lblObj.TextSize = 11
        lblObj.TextXAlignment = Enum.TextXAlignment.Left
        local keyBtn = Instance.new("TextButton", card)
        keyBtn.Size = UDim2.new(0,60,0,24); keyBtn.Position = UDim2.new(1,-70,0.5,-12)
        keyBtn.BackgroundColor3 = Color3.fromRGB(30,0,0); keyBtn.BorderSizePixel = 0
        keyBtn.Text = (keyEntry.kb or keyEntry.gp or Enum.KeyCode.Unknown).Name
        keyBtn.TextColor3 = C_WHITE; keyBtn.Font = Enum.Font.GothamBold; keyBtn.TextSize = 10
        Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0,5)
        local listening = false
        keyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            local prev = keyBtn.Text; keyBtn.Text = "..."
            local conn
            conn = UIS.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Keyboard or inp.UserInputType == Enum.UserInputType.Gamepad1 then
                    if inp.KeyCode ~= Enum.KeyCode.Escape then
                        keyBtn.Text = inp.KeyCode.Name
                        if inp.UserInputType == Enum.UserInputType.Gamepad1 then
                            keyEntry.gp = inp.KeyCode; keyEntry.kb = nil
                        else
                            keyEntry.kb = inp.KeyCode; keyEntry.gp = nil
                        end
                        saveConfig()
                    else
                        keyBtn.Text = prev
                    end
                    conn:Disconnect(); listening = false
                end
            end)
        end)
    end
    actionRow("Move", "Drop Brainrot", S.KB.DropBrainrot)
    actionRow("Move", "TP Down", S.KB.TPFlor)

    -- ===== CONFIG TAB =====
    do
        local card = mkCard("Config", pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0,120,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Auto Steal"; lbl.TextColor3 = C_ACCENT
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        local pill = Instance.new("Frame", card)
        pill.Size = UDim2.new(0,28,0,16); pill.Position = UDim2.new(1,-36,0.5,-8)
        pill.BackgroundColor3 = Color3.fromRGB(60,0,0)
        pill.BorderSizePixel = 0
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)
        local dot = Instance.new("Frame", pill)
        dot.Size = UDim2.new(0,12,0,12); dot.Position = UDim2.new(0,2,0.5,-6)
        dot.BackgroundColor3 = C_WHITE; dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        local stealOn = false
        local function setStealVis(on)
            stealOn = on
            pill.BackgroundColor3 = on and C_ACCENT or Color3.fromRGB(60,0,0)
            dot.Position = on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
            dot.BackgroundColor3 = on and Color3.fromRGB(12,0,0) or C_WHITE
        end
        S.setInstaGrab = setStealVis
        local click = Instance.new("TextButton", card)
        click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""; click.ZIndex = 3
        click.MouseButton1Click:Connect(function()
            stealOn = not stealOn; setStealVis(stealOn); Steal.AutoStealEnabled = stealOn
            if stealOn then startAutoSteal() else stopAutoSteal() end
            saveConfig()
        end)
    end

    S.radInput = mkInput("Config", pages, "Steal Radius", Steal.StealRadius, function(v)
        if v>=1 and v<=300 then Steal.StealRadius = math.floor(v) end; saveConfig()
    end)

    S.stealDurationBox = mkInput("Config", pages, "Steal Duration", Steal.StealDuration, function(v)
        if v >= 0.05 and v <= 2 then Steal.StealDuration = v; saveConfig() end
    end)

    S.autoTPDownThresholdBox = mkInput("Config", pages, "TP Threshold", S.autoTPDownThreshold, function(v)
        local n = tonumber(v); if n and n >= 1 and n <= 500 then S.autoTPDownThreshold = n; saveConfig() end
    end)

    do
        local card = mkCard("Config", pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0,100,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Hide GUI"; lbl.TextColor3 = C_ACCENT
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        local keyBtn = Instance.new("TextButton", card)
        keyBtn.Size = UDim2.new(0,60,0,24); keyBtn.Position = UDim2.new(1,-70,0.5,-12)
        keyBtn.BackgroundColor3 = Color3.fromRGB(30,0,0); keyBtn.BorderSizePixel = 0
        keyBtn.Text = (S.KB.GuiHide.kb or S.KB.GuiHide.gp or Enum.KeyCode.Unknown).Name
        keyBtn.TextColor3 = C_WHITE; keyBtn.Font = Enum.Font.GothamBold; keyBtn.TextSize = 10
        Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0,5)
        local listening = false
        keyBtn.MouseButton1Click:Connect(function()
            if listening then return end
            listening = true
            local prev = keyBtn.Text; keyBtn.Text = "..."
            local conn
            conn = UIS.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Keyboard or inp.UserInputType == Enum.UserInputType.Gamepad1 then
                    if inp.KeyCode ~= Enum.KeyCode.Escape then
                        keyBtn.Text = inp.KeyCode.Name
                        if inp.UserInputType == Enum.UserInputType.Gamepad1 then
                            S.KB.GuiHide.gp = inp.KeyCode; S.KB.GuiHide.kb = nil
                        else
                            S.KB.GuiHide.kb = inp.KeyCode; S.KB.GuiHide.gp = nil
                        end
                        saveConfig()
                    else
                        keyBtn.Text = prev
                    end
                    conn:Disconnect(); listening = false
                end
            end)
        end)
    end

    do
        local card = mkCard("Config", pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0,100,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Lock UI"; lbl.TextColor3 = C_ACCENT
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        local pill = Instance.new("Frame", card)
        pill.Size = UDim2.new(0,28,0,16); pill.Position = UDim2.new(1,-36,0.5,-8)
        pill.BackgroundColor3 = Color3.fromRGB(60,0,0)
        pill.BorderSizePixel = 0
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)
        local dot = Instance.new("Frame", pill)
        dot.Size = UDim2.new(0,12,0,12); dot.Position = UDim2.new(0,2,0.5,-6)
        dot.BackgroundColor3 = C_WHITE; dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        local lockOn = false
        local function setLockVis(on)
            lockOn = on
            pill.BackgroundColor3 = on and C_ACCENT or Color3.fromRGB(60,0,0)
            dot.Position = on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
            dot.BackgroundColor3 = on and Color3.fromRGB(12,0,0) or C_WHITE
        end
        S.setLockUI_Visual = setLockVis
        local click = Instance.new("TextButton", card)
        click.Size = UDim2.new(1,0,1,0); click.BackgroundTransparency = 1; click.Text = ""; click.ZIndex = 3
        click.MouseButton1Click:Connect(function()
            lockOn = not lockOn; setLockVis(lockOn); setUILock(lockOn); saveConfig()
        end)
    end

    do
        local card = mkCard("Config", pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0,140,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Hide Buttons"; lbl.TextColor3 = C_ACCENT
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        local pill = Instance.new("Frame", card)
        pill.Size = UDim2.new(0,28,0,16); pill.Position = UDim2.new(1,-36,0.5,-8)
        pill.BackgroundColor3 = Color3.fromRGB(60,0,0)
        pill.BorderSizePixel = 0
        Instance.new("UICorner", pill).CornerRadius = UDim.new(1,0)
        local dot = Instance.new("Frame", pill)
        dot.Size = UDim2.new(0,12,0,12); dot.Position = UDim2.new(0,2,0.5,-6)
        dot.BackgroundColor3 = C_WHITE; dot.BorderSizePixel = 0
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        local hideButtonsOn = false
        local function setHideButtonsVis(on)
            hideButtonsOn = on
            pill.BackgroundColor3 = on and C_ACCENT or Color3.fromRGB(60,0,0)
            dot.Position = on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
            dot.BackgroundColor3 = on and Color3.fromRGB(12,0,0) or C_WHITE
        end
        S.setHideOpiumButtons = setHideButtonsVis
        local click2 = Instance.new("TextButton", card)
        click2.Size = UDim2.new(1,0,1,0); click2.BackgroundTransparency = 1; click2.Text = ""; click2.ZIndex = 3
        click2.MouseButton1Click:Connect(function()
            hideButtonsOn = not hideButtonsOn
            setHideButtonsVis(hideButtonsOn)
            if S.floatingPanelGui then
                S.floatingPanelGui.Enabled = not hideButtonsOn
            end
            pcall(function()
                local pg = LP:FindFirstChild("PlayerGui")
                if pg then
                    local opiumGui = pg:FindFirstChild("OpiumGGV5_2")
                    if opiumGui then opiumGui.Enabled = not hideButtonsOn end
                end
            end)
            S.hideOpiumButtonsEnabled = hideButtonsOn
            saveConfig()
        end)
    end

    do
        local card = mkCard("Config", pages, 38)
        local lbl = Instance.new("TextLabel", card)
        lbl.Size = UDim2.new(0,140,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = "Reset Panel"; lbl.TextColor3 = C_ACCENT
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11
        local resetBtn = Instance.new("TextButton", card)
        resetBtn.Size = UDim2.new(0,80,0,28)
        resetBtn.Position = UDim2.new(1,-90,0.5,-14)
        resetBtn.BackgroundColor3 = Color3.fromRGB(30,0,0)
        resetBtn.BorderSizePixel = 0
        resetBtn.Text = "Reset"
        resetBtn.TextColor3 = C_WHITE
        resetBtn.Font = Enum.Font.GothamBold
        resetBtn.TextSize = 11
        Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0,6)
        resetBtn.MouseButton1Click:Connect(function()
            local originalText = resetBtn.Text
            resetBtn.Text = "..."
            task.spawn(function()
                resetFloatingPanel()
                task.wait(0.2)
                resetBtn.Text = originalText
            end)
        end)
    end

    local function showGui()
        main.Visible = true
        if S.miniToggleButton then S.miniToggleButton.Visible = false end
    end
    S.miniToggleButton = buildGui_createMiniToggle(gui, showGui)

    -- Eventos de teclas (igual que antes)
    UIS.InputBegan:Connect(function(input, gpe)
        if input.UserInputType ~= Enum.UserInputType.Keyboard and input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
        local kc = input.KeyCode
        local function match(entry)
            return kc == entry.kb or (entry.gp and kc == entry.gp)
        end
        if gpe then
            if match(S.KB.GuiHide) then
                if main.Visible then
                    main.Visible = false
                    if S.miniToggleButton then S.miniToggleButton.Visible = true end
                else
                    showGui()
                end
            end
            return
        end
        if match(S.KB.DropBrainrot) then
            task.spawn(runDropBrainrot)
        elseif match(S.KB.TPFlor) then
            runTPFloor()
        elseif match(S.KB.AutoLeft) then
            S.autoLeftEnabled = not S.autoLeftEnabled
            if S.autoLeftEnabled then
                if S.autoRightEnabled then S.autoRightEnabled = false; stopAutoRight(); if S.autoRightSetVisual then S.autoRightSetVisual(false) end end
                if S.batAimbotEnabled then setBatAimbot(false) end
                if S.bat2Enabled then setBat2(false) end
                startAutoLeft()
            else stopAutoLeft() end
            if S.autoLeftSetVisual then S.autoLeftSetVisual(S.autoLeftEnabled) end
            S.restartMovement(); updateFloatingButtons(); saveConfig()
        elseif match(S.KB.AutoRight) then
            S.autoRightEnabled = not S.autoRightEnabled
            if S.autoRightEnabled then
                if S.autoLeftEnabled then S.autoLeftEnabled = false; stopAutoLeft(); if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end end
                if S.batAimbotEnabled then setBatAimbot(false) end
                if S.bat2Enabled then setBat2(false) end
                startAutoRight()
            else stopAutoRight() end
            if S.autoRightSetVisual then S.autoRightSetVisual(S.autoRightEnabled) end
            S.restartMovement(); updateFloatingButtons(); saveConfig()
        elseif match(S.KB.AutoBat) then
            setBatAimbot(not S.batAimbotEnabled)
        elseif match(S.KB.AutoBat2) then
            setBat2(not S.bat2Enabled)
        elseif match(S.KB.GuiHide) then
            if main.Visible then
                main.Visible = false
                if S.miniToggleButton then S.miniToggleButton.Visible = true end
            else
                showGui()
            end
        elseif match(S.KB.SpeedToggle) then
            if S.laggerMode ~= 0 then
                S.laggerMode = 0
                if S.setLaggerVisual then S.setLaggerVisual(false) end
                updateLaggerButtonVisual()
            end
            S.speedMode = not S.speedMode
            if S.speedClk then S.speedClk(S.speedMode) end
            S.restartMovement(); updateFloatingButtons(); saveConfig()
        elseif match(S.KB.LaggerToggle) then
            if S.speedMode then
                S.speedMode = false
                if S.speedClk then S.speedClk(false) end
            end
            if S.laggerMode == 1 then
                S.laggerMode = 2
            else
                S.laggerMode = 1
            end
            updateLaggerButtonVisual()
            if S.setLaggerVisual then S.setLaggerVisual(true) end            
            S.restartMovement(); updateFloatingButtons(); saveConfig()
        elseif match(S.KB.AutoTPDown) then
            S.autoTPDownEnabled = not S.autoTPDownEnabled
            if S.autoTPDownEnabled then startAutoTPDown() else stopAutoTPDown() end
            if S.autoTPDownSetVisual then S.autoTPDownSetVisual(S.autoTPDownEnabled) end
            if S.autoTPDownFloatVisual then S.autoTPDownFloatVisual(S.autoTPDownEnabled) end
            saveConfig()
        elseif match(S.KB.InfJump) then
            S.infJumpEnabled = not S.infJumpEnabled
            if S.setInfJumpVisual then S.setInfJumpVisual(S.infJumpEnabled) end
            if S.infJumpEnabled then startInfiniteJump() else stopInfiniteJump() end
            saveConfig()
        end
    end)

    showGui()
end

-- ===========================
-- PANEL FLOTANTE CON BOTONES Y TEXTOS VERMELHO/PRETO/BRANCO
-- ===========================
local function createFloatingButtonPanel()
    local panelGui = Instance.new("ScreenGui")
    panelGui.Name = "BRDUELS_FloatingPanel"
    panelGui.ResetOnSpawn = false
    panelGui.IgnoreGuiInset = true; panelGui.DisplayOrder = 8
    if not pcall(function() panelGui.Parent = game:GetService("CoreGui") end) then
        panelGui.Parent = LP:WaitForChild("PlayerGui")
    end
    S.floatingPanelGui = panelGui

    local panelFrame = Instance.new("Frame", panelGui)
    panelFrame.Size = UDim2.new(0, 220, 0, 0)
    panelFrame.Position = UDim2.new(1, -228, 0.5, -150)
    panelFrame.BackgroundColor3 = Color3.fromRGB(4,0,0)
    panelFrame.BackgroundTransparency = 1
    panelFrame.BorderSizePixel = 0
    panelFrame.Active = true
    panelFrame.ZIndex = 20
    panelFrame.AutomaticSize = Enum.AutomaticSize.Y
    Instance.new("UICorner", panelFrame).CornerRadius = UDim.new(0, 14)
    S.floatingPanelFrame = panelFrame
    makeDraggable(panelFrame, true)

    local mainLayout = Instance.new("UIListLayout", panelFrame)
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
    mainLayout.Padding = UDim.new(0, 4)
    mainLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local pad = Instance.new("UIPadding", panelFrame)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 6)

    local BLACK_OFF = Color3.fromRGB(0,0,0)
    local WHITE = Color3.fromRGB(255,255,255)
    local VERMELHO = Color3.fromRGB(200,0,0)
    local STROKE_OFF = Color3.fromRGB(80,0,0)
    local STROKE_ON = VERMELHO

    local function makePButton(label1, label2)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 60, 0, 55)
        btn.BackgroundColor3 = BLACK_OFF
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.ZIndex = 22
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
        local stroke = Instance.new("UIStroke", btn)
        stroke.Color = STROKE_OFF
        stroke.Thickness = 1
        stroke.Transparency = 0.2
        local t1 = Instance.new("TextLabel", btn)
        t1.Size = UDim2.new(1,0,0.55,0)
        t1.Position = UDim2.new(0,0,0.06,0)
        t1.BackgroundTransparency = 1
        t1.Text = label1
        t1.TextColor3 = VERMELHO
        t1.Font = Enum.Font.GothamBlack
        t1.TextSize = 10
        t1.TextXAlignment = Enum.TextXAlignment.Center
        t1.ZIndex = 23
        local t2 = Instance.new("TextLabel", btn)
        t2.Size = UDim2.new(1,0,0.4,0)
        t2.Position = UDim2.new(0,0,0.55,0)
        t2.BackgroundTransparency = 1
        t2.Text = label2
        t2.TextColor3 = VERMELHO
        t2.Font = Enum.Font.GothamBlack
        t2.TextSize = 8
        t2.TextXAlignment = Enum.TextXAlignment.Center
        t2.ZIndex = 23
        if label1 == "DROP" then
            t2.Visible = false
            t1.Size = UDim2.new(1,0,1,0)
            t1.Position = UDim2.new(0,0,0,0)
            t1.TextScaled = false
            t1.TextSize = 11
        end
        return btn, stroke, t1, t2
    end

    local function setButtonActive(btn, stroke, label1, label2, active)
        if active then
            btn.BackgroundColor3 = VERMELHO
            stroke.Color = STROKE_ON
            stroke.Transparency = 0
            if label1 then label1.TextColor3 = WHITE end
            if label2 then label2.TextColor3 = WHITE end
        else
            btn.BackgroundColor3 = BLACK_OFF
            stroke.Color = STROKE_OFF
            stroke.Transparency = 0.2
            if label1 then label1.TextColor3 = VERMELHO end
            if label2 then label2.TextColor3 = VERMELHO end
        end
    end
    S._setPButtonActive = setButtonActive

    local btnBAT2, bsBAT2, l1BAT2, l2BAT2 = makePButton("BAT", "2")
    local btnDROP, bsDROP, l1DROP, l2DROP = makePButton("DROP", "BRAINROT")
    local btnAL, bsAL, l1AL, l2AL = makePButton("AUTO", "LEFT")
    local btnBAT, bsBAT, l1BAT, l2BAT = makePButton("BAT", "AIMBOT")
    local btnAR, bsAR, l1AR, l2AR = makePButton("AUTO", "RIGHT")
    local btnTP, bsTP, l1TP, l2TP = makePButton("TP", "DOWN")
    local btnCS, bsCS, l1CS, l2CS = makePButton("CARRY", "SPD")
    local btnLAG, bsLAG, l1LAG, l2LAG = makePButton("LAGGER", "MODE")
    local btnATD, bsATD, l1ATD, l2ATD = makePButton("AUTO TP", "DOWN")

    S._btnAAL = btnAL; S._bsAAL = bsAL; S._l1AAL = l1AL; S._l2AAL = l2AL
    S._btnAAR = btnAR; S._bsAAR = bsAR; S._l1AAR = l1AR; S._l2AAR = l2AR
    S._btnBAT = btnBAT; S._bsBAT = bsBAT; S._l1BAT = l1BAT; S._l2BAT = l2BAT
    S._btnBAT2 = btnBAT2; S._bsBAT2 = bsBAT2; S._l1BAT2 = l1BAT2; S._l2BAT2 = l2BAT2

    S._floatingButtons = {
        lagger = btnLAG, strokeLagger = bsLAG, l1Lagger = l1LAG, l2Lagger = l2LAG,
        carry = btnCS, strokeCarry = bsCS, l1Carry = l1CS, l2Carry = l2CS,
        autoLeft = btnAL, strokeAutoLeft = bsAL, l1AutoLeft = l1AL, l2AutoLeft = l2AL,
        autoRight = btnAR, strokeAutoRight = bsAR, l1AutoRight = l1AR, l2AutoRight = l2AR,
        bat = btnBAT, strokeBat = bsBAT, l1Bat = l1BAT, l2Bat = l2BAT,
        bat2 = btnBAT2, strokeBat2 = bsBAT2, l1Bat2 = l1BAT2, l2Bat2 = l2BAT2,
        autoTPDown = btnATD, strokeAutoTPDown = bsATD, l1AutoTPDown = l1ATD, l2AutoTPDown = l2ATD,
    }

    local function addRowWithPlaceholders(...)
        local row = Instance.new("Frame", panelFrame)
        row.Size = UDim2.new(1, 0, 0, 60)
        row.BackgroundTransparency = 1
        row.LayoutOrder = #panelFrame:GetChildren() - 1
        local grid = Instance.new("UIGridLayout", row)
        grid.CellSize = UDim2.new(0, 60, 0, 55)
        grid.CellPadding = UDim2.new(0, 8, 0, 0)
        grid.FillDirection = Enum.FillDirection.Horizontal
        grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
        local buttons = {...}
        for i = 1, 3 do
            local btnOrPlaceholder = buttons[i]
            if btnOrPlaceholder then
                btnOrPlaceholder.Parent = row
            else
                local ph = Instance.new("Frame", row)
                ph.Size = UDim2.new(0, 60, 0, 55)
                ph.BackgroundTransparency = 1
                ph.Visible = true
            end
        end
        return row
    end

    addRowWithPlaceholders(btnBAT2, btnDROP, btnAL)
    addRowWithPlaceholders(nil, btnBAT, btnAR)
    addRowWithPlaceholders(btnTP, btnCS, nil)
    addRowWithPlaceholders(btnLAG, btnATD, nil)

    l1LAG.Text = "LAGGER"
    l2LAG.Text = (S.laggerMode == 1 and "1") or "2"
    setButtonActive(btnLAG, bsLAG, l1LAG, l2LAG, true)
    setButtonActive(btnCS, bsCS, l1CS, l2CS, S.speedMode)
    setButtonActive(btnAL, bsAL, l1AL, l2AL, S.autoLeftEnabled)
    setButtonActive(btnAR, bsAR, l1AR, l2AR, S.autoRightEnabled)
    setButtonActive(btnBAT, bsBAT, l1BAT, l2BAT, S.batAimbotEnabled)
    setButtonActive(btnBAT2, bsBAT2, l1BAT2, l2BAT2, S.bat2Enabled)
    setButtonActive(btnATD, bsATD, l1ATD, l2ATD, S.autoTPDownEnabled)

    S.autoTPDownFloatVisual = function(state)
        setButtonActive(btnATD, bsATD, l1ATD, l2ATD, state)
    end

    -- Eventos de botones
    btnBAT2.MouseButton1Click:Connect(function()
        local newState = not S.bat2Enabled
        if newState then
            if S.autoLeftEnabled then
                S.autoLeftEnabled = false; stopAutoLeft()
                if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
                setButtonActive(btnAL, bsAL, l1AL, l2AL, false)
            end
            if S.autoRightEnabled then
                S.autoRightEnabled = false; stopAutoRight()
                if S.autoRightSetVisual then S.autoRightSetVisual(false) end
                setButtonActive(btnAR, bsAR, l1AR, l2AR, false)
            end
            if S.batAimbotEnabled then
                setBatAimbot(false)
                setButtonActive(btnBAT, bsBAT, l1BAT, l2BAT, false)
            end
        end
        setBat2(newState)
    end)

    btnDROP.MouseButton1Click:Connect(function()
        setButtonActive(btnDROP, bsDROP, l1DROP, l2DROP, true)
        task.delay(0.5, function() setButtonActive(btnDROP, bsDROP, l1DROP, l2DROP, false) end)
        task.spawn(runDropBrainrot)
    end)

    btnTP.MouseButton1Click:Connect(function()
        setButtonActive(btnTP, bsTP, l1TP, l2TP, true)
        task.delay(0.35, function() setButtonActive(btnTP, bsTP, l1TP, l2TP, false) end)
        runTPFloor()
    end)

    btnBAT.MouseButton1Click:Connect(function()
        local newState = not S.batAimbotEnabled
        if newState then
            if S.autoLeftEnabled then
                S.autoLeftEnabled = false; stopAutoLeft()
                if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
                setButtonActive(btnAL, bsAL, l1AL, l2AL, false)
            end
            if S.autoRightEnabled then
                S.autoRightEnabled = false; stopAutoRight()
                if S.autoRightSetVisual then S.autoRightSetVisual(false) end
                setButtonActive(btnAR, bsAR, l1AR, l2AR, false)
            end
            if S.bat2Enabled then
                setBat2(false)
                setButtonActive(btnBAT2, bsBAT2, l1BAT2, l2BAT2, false)
            end
        end
        setBatAimbot(newState)
    end)

    btnAL.MouseButton1Click:Connect(function()
        local newState = not S.autoLeftEnabled
        if newState then
            if S.autoRightEnabled then
                S.autoRightEnabled = false; stopAutoRight()
                if S.autoRightSetVisual then S.autoRightSetVisual(false) end
                setButtonActive(btnAR, bsAR, l1AR, l2AR, false)
            end
            if S.batAimbotEnabled then setBatAimbot(false); setButtonActive(btnBAT, bsBAT, l1BAT, l2BAT, false) end
            if S.bat2Enabled then setBat2(false); setButtonActive(btnBAT2, bsBAT2, l1BAT2, l2BAT2, false) end
            S.autoLeftEnabled = true; startAutoLeft()
        else
            S.autoLeftEnabled = false; stopAutoLeft()
        end
        if S.autoLeftSetVisual then S.autoLeftSetVisual(newState) end
        setButtonActive(btnAL, bsAL, l1AL, l2AL, newState)
        S.restartMovement(); updateFloatingButtons(); saveConfig()
    end)

    btnAR.MouseButton1Click:Connect(function()
        local newState = not S.autoRightEnabled
        if newState then
            if S.autoLeftEnabled then
                S.autoLeftEnabled = false; stopAutoLeft()
                if S.autoLeftSetVisual then S.autoLeftSetVisual(false) end
                setButtonActive(btnAL, bsAL, l1AL, l2AL, false)
            end
            if S.batAimbotEnabled then setBatAimbot(false); setButtonActive(btnBAT, bsBAT, l1BAT, l2BAT, false) end
            if S.bat2Enabled then setBat2(false); setButtonActive(btnBAT2, bsBAT2, l1BAT2, l2BAT2, false) end
            S.autoRightEnabled = true; startAutoRight()
        else
            S.autoRightEnabled = false; stopAutoRight()
        end
        if S.autoRightSetVisual then S.autoRightSetVisual(newState) end
        setButtonActive(btnAR, bsAR, l1AR, l2AR, newState)
        S.restartMovement(); updateFloatingButtons(); saveConfig()
    end)

    btnLAG.MouseButton1Click:Connect(function()
        if S.laggerMode == 1 then
            S.laggerMode = 2
        else
            S.laggerMode = 1
        end
        if S.speedMode then
            S.speedMode = false
            if S.speedClk then S.speedClk(false) end
            setButtonActive(btnCS, bsCS, l1CS, l2CS, false)
        end
        updateLaggerButtonVisual()
        if S.setLaggerVisual then S.setLaggerVisual(true) end
        S.restartMovement()
        updateFloatingButtons()
        saveConfig()
    end)

    btnCS.MouseButton1Click:Connect(function()
        local newState = not S.speedMode
        if newState and S.laggerMode ~= 0 then
            S.laggerMode = 0
            if S.setLaggerVisual then S.setLaggerVisual(false) end
            updateLaggerButtonVisual()
        end
        S.speedMode = newState
        if S.speedClk then S.speedClk(newState) end
        setButtonActive(btnCS, bsCS, l1CS, l2CS, newState)
        S.restartMovement(); updateFloatingButtons(); saveConfig()
    end)

    btnATD.MouseButton1Click:Connect(function()
        local newState = not S.autoTPDownEnabled
        S.autoTPDownEnabled = newState
        if newState then startAutoTPDown() else stopAutoTPDown() end
        if S.autoTPDownSetVisual then S.autoTPDownSetVisual(newState) end
        if S.autoTPDownFloatVisual then S.autoTPDownFloatVisual(newState) end
        saveConfig()
    end)
end

-- ===========================
-- HUD (barra de progreso y FPS)
-- ===========================
local function createHUD()
    local HudGui = Instance.new("ScreenGui")
    HudGui.Name = "BRDUELS_HUD"
    HudGui.ResetOnSpawn = false
    HudGui.IgnoreGuiInset = true; HudGui.DisplayOrder = 15
    if not pcall(function() HudGui.Parent = game:GetService("CoreGui") end) then
        HudGui.Parent = LP:WaitForChild("PlayerGui")
    end
    S.topBarHUD = Instance.new("Frame")
    S.topBarHUD.Size = UDim2.new(0,235,0,29); S.topBarHUD.Position = UDim2.new(0.5,-117.5,0,12)
    S.topBarHUD.BackgroundColor3 = Color3.fromRGB(8,0,0); S.topBarHUD.BackgroundTransparency = 0.25
    S.topBarHUD.BorderSizePixel = 0; S.topBarHUD.Visible = true; S.topBarHUD.Parent = HudGui
    Instance.new("UICorner", S.topBarHUD).CornerRadius = UDim.new(0,9)
    local topStroke = Instance.new("UIStroke", S.topBarHUD)
    topStroke.Thickness = 1.3; topStroke.Color = Color3.fromRGB(200,0,0); topStroke.Transparency = 0.88
    local topLabel = Instance.new("TextLabel", S.topBarHUD)
    topLabel.Size = UDim2.new(1,-10,1,0)
    topLabel.Position = UDim2.new(0,5,0,0)
    topLabel.BackgroundTransparency = 1
    topLabel.Text = "🌹 BR DUELS | FPS: 0 PING: 0ms"
    topLabel.TextColor3 = Color3.fromRGB(200,0,0)
    topLabel.Font = Enum.Font.GothamBold
    topLabel.TextSize = 12.5; topLabel.TextStrokeTransparency = 0.6
    topLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    topLabel.TextScaled = false; topLabel.ClipsDescendants = true
    S.progressBarFrame = Instance.new("Frame")
    S.progressBarFrame.Size = UDim2.new(0,235,0,15); S.progressBarFrame.Position = UDim2.new(0.5,-117.5,0,38)
    S.progressBarFrame.BackgroundColor3 = Color3.fromRGB(8,0,0); S.progressBarFrame.BackgroundTransparency = 0.35
    S.progressBarFrame.BorderSizePixel = 0; S.progressBarFrame.Visible = true; S.progressBarFrame.Parent = HudGui
    S.progressBarFrame.ClipsDescendants = true
    Instance.new("UICorner", S.progressBarFrame).CornerRadius = UDim.new(0,6)
    local progStroke = Instance.new("UIStroke", S.progressBarFrame)
    progStroke.Thickness = 1.1; progStroke.Color = Color3.fromRGB(200,0,0); progStroke.Transparency = 0.88
    S.progressFill = Instance.new("Frame", S.progressBarFrame)
    S.progressFill.Size = UDim2.new(0,0,1,0); S.progressFill.Position = UDim2.new(0,0,0,0)
    S.progressFill.BackgroundColor3 = Color3.fromRGB(200,0,0)
    S.progressFill.BorderSizePixel = 0
    Instance.new("UICorner", S.progressFill).CornerRadius = UDim.new(0,4)
    S.progressPct = Instance.new("TextLabel", S.progressBarFrame)
    S.progressPct.Size = UDim2.new(1,0,1,0); S.progressPct.BackgroundTransparency = 1
    S.progressPct.Text = "0%"; S.progressPct.TextColor3 = Color3.fromRGB(0,0,0)
    S.progressPct.Font = Enum.Font.GothamBold; S.progressPct.TextSize = 10.5; S.progressPct.TextStrokeTransparency = 0.7
    local _hudTimer = 0
    RunService.Heartbeat:Connect(function(dt)
        _hudTimer = _hudTimer + dt
        if _hudTimer >= 0.5 then
            _hudTimer = 0
            local ping = 0
            pcall(function() ping = math.floor(LP:GetNetworkPing()*1000) end)
            topLabel.Text = "🌹 BR DUELS | FPS: "..S.currentFPS.." PING: "..ping.."ms"
        end
    end)
end

buildGui()
createFloatingButtonPanel()
createHUD()

local function loadConfig()
    if not safeIsfile(S.CONFIG_FILE) then return end
    local data = safeReadfile(S.CONFIG_FILE)
    if not data then return end
    local ok, cfg = pcall(function() return HS:JSONDecode(data) end)
    if not ok or type(cfg) ~= "table" then return end

    if cfg.normalSpeed then S.NS = cfg.normalSpeed; if S.normalBox then S.normalBox.Text = tostring(S.NS) end end
    if cfg.carrySpeed then S.CS = cfg.carrySpeed; if S.carryBox then S.carryBox.Text = tostring(S.CS) end end
    if cfg.laggerSpeed then S.LS = cfg.laggerSpeed; if S.laggerBox then S.laggerBox.Text = tostring(S.LS) end end
    if cfg.laggerSpeed2 then S.LS2 = cfg.laggerSpeed2; if S.lagger2Box then S.lagger2Box.Text = tostring(S.LS2) end end
    if cfg.laggerMode then S.laggerMode = cfg.laggerMode end

    if S.laggerMode == 0 then S.laggerMode = 1 end

    local function tryLoadKey(entry, kbName, gpName)
        if kbName and Enum.KeyCode[kbName] then
            entry.kb = Enum.KeyCode[kbName]; entry.gp = nil
        elseif gpName and Enum.KeyCode[gpName] then
            entry.gp = Enum.KeyCode[gpName]; entry.kb = nil
        end
    end
    if cfg.dropBrainrotKey then tryLoadKey(S.KB.DropBrainrot, cfg.dropBrainrotKey.kb, cfg.dropBrainrotKey.gp) end
    if cfg.autoLeftKey then tryLoadKey(S.KB.AutoLeft, cfg.autoLeftKey.kb, cfg.autoLeftKey.gp) end
    if cfg.autoRightKey then tryLoadKey(S.KB.AutoRight, cfg.autoRightKey.kb, cfg.autoRightKey.gp) end
    if cfg.autoBatKey then tryLoadKey(S.KB.AutoBat, cfg.autoBatKey.kb, cfg.autoBatKey.gp) end
    if cfg.autoBat2Key then tryLoadKey(S.KB.AutoBat2, cfg.autoBat2Key.kb, cfg.autoBat2Key.gp) end
    if cfg.tpFloorKey then tryLoadKey(S.KB.TPFlor, cfg.tpFloorKey.kb, cfg.tpFloorKey.gp) end
    if cfg.guiHideKey then tryLoadKey(S.KB.GuiHide, cfg.guiHideKey.kb, cfg.guiHideKey.gp) end
    if cfg.speedToggleKey then tryLoadKey(S.KB.SpeedToggle, cfg.speedToggleKey.kb, cfg.speedToggleKey.gp) end
    if cfg.laggerToggleKey then tryLoadKey(S.KB.LaggerToggle, cfg.laggerToggleKey.kb, cfg.laggerToggleKey.gp) end
    if cfg.autoTPDownKey then tryLoadKey(S.KB.AutoTPDown, cfg.autoTPDownKey.kb, cfg.autoTPDownKey.gp) end
    if cfg.infJumpKey then tryLoadKey(S.KB.InfJump, cfg.infJumpKey.kb, cfg.infJumpKey.gp) end

    if cfg.grabRadius then Steal.StealRadius = cfg.grabRadius; if S.radInput then S.radInput.Text = tostring(cfg.grabRadius) end end
    if cfg.stealDuration then Steal.StealDuration = cfg.stealDuration; if S.stealDurationBox then S.stealDurationBox.Text = tostring(cfg.stealDuration) end end

    if cfg.autoTPDownThreshold then S.autoTPDownThreshold = cfg.autoTPDownThreshold; if S.autoTPDownThresholdBox then S.autoTPDownThresholdBox.Text = tostring(cfg.autoTPDownThreshold) end end

    if cfg.antiRagdoll then 
        toggleAntiRag(true)
        if S.setAntiRagVisual then S.setAntiRagVisual(true) end 
    end
    
    if cfg.autoStealEnabled then Steal.AutoStealEnabled = true; if S.setInstaGrab then S.setInstaGrab(true) end; startAutoSteal() end
    if cfg.infiniteJump then 
        S.infJumpEnabled = true
        if S.setInfJumpVisual then S.setInfJumpVisual(true) end
        startInfiniteJump()
    end
    if cfg.infiniteJumpMode then S.infJumpMode = cfg.infiniteJumpMode end
    if cfg.medusaCounter then S.medusaCounterEnabled = true; setupMedusaCounter(LP.Character); if S.setMedusaVisual then S.setMedusaVisual(true) end end
    if cfg.carryMode then S.speedMode = true; S.laggerMode = 0; if S.speedClk then S.speedClk(true) end end
    if cfg.laggerMode and cfg.laggerMode > 0 and not cfg.carryMode then
        S.laggerMode = cfg.laggerMode
        if S.setLaggerVisual then S.setLaggerVisual(true) end
    end
    if cfg.batAimbot then setBatAimbot(true) end
    if cfg.bat2 then setBat2(true) end
    if cfg.batCounter then S.batCounterEnabled = true; startBatCounter(); if S.setBatCounterVisual then S.setBatCounterVisual(true) end end
    if cfg.unwalkEnabled then S.unwalkEnabled = true; startUnwalk(); if S.setUnwalkVisual then S.setUnwalkVisual(true) end end
    if cfg.lockUI then S.lockUIEnabled = true; setUILock(true); if S.setLockUI_Visual then S.setLockUI_Visual(true) end end
    if cfg.hideOpiumButtons then S.hideOpiumButtonsEnabled = true; if S.setHideOpiumButtons then S.setHideOpiumButtons(true) end; if S.floatingPanelGui then S.floatingPanelGui.Enabled = false end end
    if cfg.fpsBoost then S.fpsBoostEnabled = true; applyFPSBoost(); if S.setFpsVisual then S.setFpsVisual(true) end end
    if cfg.atardecer then
        atardecerOn = true
        applyAtardecer()
        if S.setAtardecerVisual then S.setAtardecerVisual(true) end
    end
    if cfg.autoTPDownEnabled then S.autoTPDownEnabled = true; startAutoTPDown(); if S.autoTPDownSetVisual then S.autoTPDownSetVisual(true) end end

    if cfg.floatingPanelPos and S.floatingPanelFrame then
        local x = cfg.floatingPanelPos.X or -138
        local y = cfg.floatingPanelPos.Y or -150
        S.floatingPanelFrame.Position = UDim2.new(1, x, 0.5, y)
    end

    local fb = S._floatingButtons
    if fb.lagger then updateLaggerButtonVisual() end

    S.restartMovement()
    updateFloatingButtons()
end

task.wait(0.5); loadConfig()

task.spawn(function()
    task.wait(0.2)
    if S.antiRagdollEnabled then startAntiRagdoll() end
    if S.unwalkEnabled then startUnwalk() end
    if S.medusaCounterEnabled and LP.Character then setupMedusaCounter(LP.Character) end
    if S.batAimbotEnabled then startBatAimbot() end
    if S.bat2Enabled then startBat2() end
    if S.batCounterEnabled then startBatCounter() end
    if S.infJumpEnabled then startInfiniteJump() end
    if S.autoTPDownEnabled then startAutoTPDown() end
    if Steal.AutoStealEnabled then startAutoSteal() end
    if S.fpsBoostEnabled then applyFPSBoost() end
    if atardecerOn then applyAtardecer() end
end)

if LP.Character then task.wait(0.3); S.setupSpeedBillboard(LP.Character) end

LP.CharacterAdded:Connect(function(char)
    if S.autoLeftEnabled then stopAutoLeft() end
    if S.autoRightEnabled then stopAutoRight() end
    if S.batAimbotEnabled then stopBatAimbot() end
    if S.bat2Enabled then stopBat2() end
    if S.batCounterEnabled then stopBatCounter() end

    if S.antiRagdollEnabled then task.wait(0.1); startAntiRagdoll() end
    if S.unwalkEnabled then task.wait(0.5); startUnwalk() end
    if S.medusaCounterEnabled then setupMedusaCounter(char) end
    task.wait(0.3)
    S.h = char:WaitForChild("Humanoid", 5)
    S.hrp = char:WaitForChild("HumanoidRootPart", 5)
    if S.h and S.hrp then S.setupSpeedBillboard(char) end
    if S.autoLeftEnabled then startAutoLeft() end
    if S.autoRightEnabled then startAutoRight() end
    if S.batAimbotEnabled then startBatAimbot() end
    if S.bat2Enabled then startBat2() end
    if S.batCounterEnabled then startBatCounter() end
    S.restartMovement()
    if S.infJumpEnabled then startInfiniteJump() end
    if S.autoTPDownEnabled then startAutoTPDown() end
    if Steal.AutoStealEnabled then startAutoSteal() end
    if S.fpsBoostEnabled then
        task.wait(0.5); applyFPSBoost()
        if atardecerOn then applyAtardecer() end
    else
        if atardecerOn then applyAtardecer() end
    end
end)

if LP.Character then
    task.spawn(function()
        local char = LP.Character
        if S.antiRagdollEnabled then startAntiRagdoll() end
        if S.unwalkEnabled then startUnwalk() end
        if S.medusaCounterEnabled then setupMedusaCounter(char) end
        S.h = char:FindFirstChildOfClass("Humanoid")
        S.hrp = char:FindFirstChild("HumanoidRootPart")
        if S.h and S.hrp then S.setupSpeedBillboard(char) end
        if S.autoLeftEnabled then startAutoLeft() end
        if S.autoRightEnabled then startAutoRight() end
        S.restartMovement()
        if S.infJumpEnabled then startInfiniteJump() end
        if S.batAimbotEnabled then startBatAimbot() end
        if S.bat2Enabled then startBat2() end
        if S.batCounterEnabled then startBatCounter() end
        if S.autoTPDownEnabled then startAutoTPDown() end
        if Steal.AutoStealEnabled then startAutoSteal() end
        if S.fpsBoostEnabled then
            applyFPSBoost()
            if atardecerOn then applyAtardecer() end
        else
            if atardecerOn then applyAtardecer() end
        end
    end)
end

print("🌹 BR DUELS carregado com sucesso! Cores vermelho, preto e branco.")
