local function IsPlayerVisible(player)
    if not IsValid(player) or not player:Alive() then
        return false
    end

    local start = LocalPlayer():EyePos()
    local endPos = player:EyePos()

    local trace = util.TraceLine({
        start = start,
        endpos = endPos,
        filter = {LocalPlayer(), player},
    })

    return not trace.Hit
end

local extrasensoryperception = true 

local function DrawPlayerBox(player)
    if not IsValid(player) or not player:Alive() or not extrasensoryperception then
        return
    end

    local isPlayerVisible = IsPlayerVisible(player)

    local min, max = player:GetRenderBounds()
    local pos = player:GetPos()
    local ang = player:GetAngles()

    local corners = {
        Vector(min.x, min.y, min.z),
        Vector(min.x, max.y, min.z),
        Vector(max.x, max.y, min.z),
        Vector(max.x, min.y, min.z),

        Vector(min.x, min.y, max.z),
        Vector(min.x, max.y, max.z),
        Vector(max.x, max.y, max.z),
        Vector(max.x, min.y, max.z),
    }

    for i = 1, 8 do
        corners[i]:Rotate(ang)
        corners[i] = corners[i] + pos
    end

    local screenCorners = {}
    for _, corner in pairs(corners) do
        local screenPos = corner:ToScreen()
        table.insert(screenCorners, screenPos)
    end

    local minX, minY, maxX, maxY = ScrW(), ScrH(), 0, 0
    for _, corner in pairs(screenCorners) do
        minX = math.min(minX, corner.x)
        minY = math.min(minY, corner.y)
        maxX = math.max(maxX, corner.x)
        maxY = math.max(maxY, corner.y)
    end

    local healthBarColor = Color(0, 255, 0)

    local health = player:Health()
    local maxHealth = player:GetMaxHealth()
    local healthPercentage = math.Clamp(health / maxHealth, 0, 1)

    local healthBarWidth = 3
    local healthBarHeight = (maxY - minY) * healthPercentage
    local healthBarX = minX - healthBarWidth - 3
    local healthBarY = minY + (maxY - minY - healthBarHeight)

    local boxColor = isPlayerVisible and Color(0, 255, 0) or Color(255, 255, 255)
    local outlineColor = Color(0, 0, 0, 255) 


    surface.SetDrawColor(outlineColor)
    surface.DrawOutlinedRect(minX - 1, minY - 1, (maxX - minX) + 2, (maxY - minY) + 2)
    surface.DrawOutlinedRect(minX + 1, minY + 1, (maxX - minX) - 2, (maxY - minY) - 2)

    surface.SetDrawColor(0, 0, 0, 0) 
    surface.DrawRect(minX, minY, maxX - minX, maxY - minY)

    surface.SetDrawColor(boxColor)
    surface.DrawOutlinedRect(minX, minY, maxX - minX, maxY - minY)

    surface.SetDrawColor(0, 0, 0) 
    surface.DrawOutlinedRect(healthBarX - 1, healthBarY - 1, healthBarWidth + 2, healthBarHeight + 2)
    surface.SetDrawColor(healthBarColor)
    surface.DrawRect(healthBarX, healthBarY, healthBarWidth, healthBarHeight)

    

    local playerName = player:Nick()
    local textWidth, textHeight = surface.GetTextSize(playerName)
    local nameX = minX 
    local nameY = minY - 18  
    
    draw.SimpleText(playerName, "ChatFont", nameX, nameY, Color(255, 255, 255), TEXT_ALIGN_TOP, TEXT_ALIGN_LEFT)
end

local function isVisible(target)
    local ply = LocalPlayer()
    local targetPos = target:EyePos()
    local traceData = {}
    traceData.start = ply:EyePos()
    traceData.endpos = targetPos
    traceData.filter = {ply, target}

    local traceResult = util.TraceLine(traceData)

    return not traceResult.Hit
end

local function findNearestVisibleTarget()
    local ply = LocalPlayer()
    local players = player.GetAll()
    local nearestPlayer, nearestDist

    for _, target in ipairs(players) do
        if target ~= ply and target:Alive() and target:Health() > 0 and target:GetPos():Distance(ply:GetPos()) < 99999 then
            local headPos = target:GetBonePosition(target:LookupBone("ValveBiped.Bip01_Head1"))
            local dist = headPos:Distance(ply:EyePos())

            if not nearestDist or dist < nearestDist then
                if isVisible(target) then
                    nearestPlayer = target
                    nearestDist = dist
                end
            end
        end
    end

    return nearestPlayer
end

local aimFOV = 7
local smoothingFactor = 85
local lastShotTime = 0

local function aimbot()
    if input.IsMouseDown(MOUSE_4) then
        local ply = LocalPlayer()
        local target = findNearestVisibleTarget()

        if target then
            local headPos = target:GetBonePosition(target:LookupBone("ValveBiped.Bip01_Head1"))
            local viewDir = ply:EyeAngles():Forward()
            local aimDir = (headPos - ply:EyePos()):GetNormalized()

            local angle = math.deg(math.acos(viewDir:Dot(aimDir)))

            if angle < aimFOV then
                local targetAngle = (headPos - ply:GetShootPos()):Angle()
                local currentAngle = ply:EyeAngles()
                local smoothedAngle = LerpAngle(1 - (smoothingFactor / 100), currentAngle, targetAngle)
                ply:SetEyeAngles(smoothedAngle)
            end
        end
    end
end

local triggerbotKey = MOUSE_4
local triggerbotEnabled = true 
local traceLength = 10000

local function Triggerbot()
    if triggerbotEnabled and input.IsMouseDown(triggerbotKey) then
        local ply = LocalPlayer()
        local eyePos = ply:EyePos()
        local eyeAngles = ply:EyeAngles()
        local aimVector = eyeAngles:Forward()

        local traceData = {}
        traceData.start = eyePos
        traceData.endpos = eyePos + (aimVector * traceLength)
        traceData.filter = ply
        traceData.mask = MASK_SHOT

        local traceResult = util.TraceLine(traceData)

        if traceResult.Hit and traceResult.HitNonWorld and traceResult.Entity:IsPlayer() and traceResult.Entity:Alive() then
            ply:SetEyeAngles((traceResult.Entity:EyePos() - eyePos):Angle())
            RunConsoleCommand("+attack")
            timer.Simple(0.01, function() RunConsoleCommand("-attack") end)
        end
    end
end

local function DrawWatermark()
    local localPlayer = LocalPlayer()

    if not IsValid(localPlayer) or not localPlayer:Alive() then
        return
    end

    local offset = localPlayer:GetPos() 
    local ping = localPlayer:Ping()
    local kills = localPlayer:Frags()

    local offsetX = math.floor(offset.x)
    local offsetY = math.floor(offset.y)
    local offsetZ = math.floor(offset.z)

    local watermarkText = string.format("| Offset: %d, %d, %d | Ping: %d | Taps: %d |", offsetX, offsetY, offsetZ, ping, kills)

    surface.SetFont("BudgetLabel")

    local textWidth, textHeight = surface.GetTextSize(watermarkText)

    local watermarkX = 10
    local watermarkY = 10

    draw.SimpleText(watermarkText, "BudgetLabel", watermarkX, watermarkY, Color(255, 255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

    
local function DrawVelocityIndicator()
    local localPlayer = LocalPlayer()

    if not IsValid(localPlayer) or not localPlayer:Alive() then
        return
    end

    local velocity = localPlayer:GetVelocity()
    local velocityLength = math.floor(velocity:Length())  

    surface.SetFont("BudgetLabel")

    local velocityText = "Vel: " .. velocityLength
    local textColor = Color(255, 0, 0)

    if velocityLength > 500 then
        textColor = Color(0, 255, 0)
    end

    local textWidth, textHeight = surface.GetTextSize(velocityText)

    local velocityX = ScrW() - textWidth - 10  
    local velocityY = 10  

    draw.SimpleText(velocityText, "BudgetLabel", velocityX, velocityY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

CreateClientConVar("bunnyhop", 1, true, false)

function Bunnyhop()
    if GetConVar("bunnyhop"):GetInt() == 1 then
        if input.IsKeyDown(KEY_SPACE) then
            if LocalPlayer():IsOnGround() then
                RunConsoleCommand("+jump")
                timer.Create("Bhop", 0, 0.01, function()
                    RunConsoleCommand("-jump")
                end)
            end
        end
    end
end



local triggerbotWatermark = triggerbotEnabled
local aimFOVText = "Aim FOV: " .. aimFOV
local tracelengthtext = "Trigger Bot Distance: " .. traceLength
local aimFOVDraw = "Draw FOV: On"
local smoothFactorText = "Smooth Factor: " .. smoothingFactor
local espstatus = "ESP: " .. (extrasensoryperception and "On" or "Off")
local bunnyHopStatus = "BunnyHop: Off"

local function UpdateTriggerbotWatermark()
    triggerbotWatermark = "Trigger Bot: " .. (triggerbotEnabled and "On" or "Off")
end

UpdateTriggerbotWatermark()

local function UpdateBunnyHopStatus()
    local bhConVar = GetConVar("bunnyhop")
    if bhConVar and bhConVar:GetInt() == 1 then
        bunnyHopStatus = "BunnyHop: On"
    else
        bunnyHopStatus = "BunnyHop: Off"
    end
end

UpdateBunnyHopStatus()

hook.Add("Think", "CheckBunnyHopConVar", function()
    UpdateBunnyHopStatus()
end)



local function drawWatermark()
    local scrW, scrH = ScrW(), ScrH()
    local center = Vector(scrW / 2, scrH / 2, 0)
    local fovRadius = scrH * (aimFOV / 90)

    surface.SetDrawColor(255, 255, 255, 100)
    surface.DrawCircle(center.x, center.y, fovRadius, Color(255, 255, 255, 255))

    local fontSize = 20
    local lineHeight = fontSize + 2
    
    local textX = 10
    local textY = ScrH() / 2 - 35

    draw.SimpleText(triggerbotWatermark, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(tracelengthtext, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(aimFOVText, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(aimFOVDraw, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(smoothFactorText, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(espstatus, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(bunnyHopStatus, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end




local function main()
    hook.Add("Think", "Aimbot", aimbot)
    hook.Add("Think", "Bunnyhop", Bunnyhop)
    hook.Add("HUDPaint", "DrawPlayerESP", function()
        for _, ply in pairs(player.GetAll()) do
            if ply ~= LocalPlayer() then
                DrawPlayerBox(ply)
                DrawWatermark()
                DrawVelocityIndicator()
            end
        end
    end)
    hook.Add("HUDPaint", "Watermark", drawWatermark)
    hook.Add("CalcView", "", function()
        return { fov = 100 }
    end)
end

hook.Add("Think", "Triggerbot", Triggerbot)

main()
