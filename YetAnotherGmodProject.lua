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

local function DrawPlayerBox(player)
    if not IsValid(player) or not player:Alive() then
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

    local boxColor = isPlayerVisible and Color(255, 255, 0) or Color(255, 255, 255)
    local healthBarColor = Color(0, 255, 0)

    local health = player:Health()
    local maxHealth = player:GetMaxHealth()
    local healthPercentage = math.Clamp(health / maxHealth, 0, 1)

    local healthBarWidth = 4
    local healthBarHeight = (maxY - minY) * healthPercentage
    local healthBarX = minX - healthBarWidth - 2
    local healthBarY = minY + (maxY - minY - healthBarHeight)

    surface.SetDrawColor(boxColor)
    surface.DrawOutlinedRect(minX, minY, maxX - minX, maxY - minY)

    surface.SetDrawColor(healthBarColor)
    surface.DrawRect(healthBarX, healthBarY, healthBarWidth, healthBarHeight)

    local playerName = player:Nick()
    local textWidth, textHeight = surface.GetTextSize(playerName)
    local nameX = minX + (maxX - minX - textWidth) / 2
    local nameY = maxY + 2
    draw.SimpleText(playerName, "DermaDefault", nameX, nameY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

local function DrawWatermark()
    local localPlayer = LocalPlayer()
    
    if not IsValid(localPlayer) or not localPlayer:Alive() then
        return
    end
    
    local offset = localPlayer:GetPos()
    local ping = LocalPlayer():Ping()
    local watermarkText = "Yet Another Lua Project Dev Build / Offset: " .. tostring(offset) .. " / Ping: " .. tostring(ping)

    surface.SetFont("BudgetLabel")

    local textWidth, textHeight = surface.GetTextSize(watermarkText)

    local watermarkX = 10
    local watermarkY = 10

    draw.SimpleText(watermarkText, "BudgetLabel", watermarkX, watermarkY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

local function DrawVelocityIndicator()
    local localPlayer = LocalPlayer()

    if not IsValid(localPlayer) or not localPlayer:Alive() then
        return
    end

    local velocity = localPlayer:GetVelocity()
    local velocityLength = velocity:Length()

    surface.SetFont("BudgetLabel")

    local velocityText = "Velocity: " .. tostring(velocityLength)
    local textColor = Color(255, 0, 0)

    if velocityLength > 500 then
        textColor = Color(0, 255, 0)
    end

    local textWidth, textHeight = surface.GetTextSize(velocityText)

    local velocityX = ScrW() - textWidth - 10
    local velocityY = 10

    draw.SimpleText(velocityText, "BudgetLabel", velocityX, velocityY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

hook.Add("HUDPaint", "DrawPlayerESP", function()
    for _, ply in pairs(player.GetAll()) do
        if ply ~= LocalPlayer() then
            DrawPlayerBox(ply)
            DrawWatermark()
            DrawVelocityIndicator()
        end
    end
end)

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

hook.Add("Think", "Bunnyhop", Bunnyhop)

local function DrawCrosshair()
    local screenWidth = ScrW()
    local screenHeight = ScrH()

    local crosshairSize = 10
    local crosshairThickness = 2

    local crosshairX = screenWidth / 2
    local crosshairY = screenHeight / 2

    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawLine(crosshairX - crosshairSize, crosshairY, crosshairX + crosshairSize, crosshairY)
    surface.DrawLine(crosshairX, crosshairY - crosshairSize, crosshairX, crosshairY + crosshairSize)
end

hook.Add("HUDPaint", "DrawCustomCrosshair", DrawCrosshair)

local aimFOV = 3
local smoothingFactor = 75
local lastShotTime = 0

local aimbotStatus = "Aimbot: On"
local aimbotColor = Color(255, 0, 0)
local aimFOVText = "Aim FOV: 3"
local aimFOVDraw = "Draw FOV: On"
local smoothFactorText = "Smooth Factor: 75"
local espstatus = "Box: On"
local espstatus2 = "Healthbar: On"
local espstatus3 = "Names: On"
local espstatus4 = "Visible Check: On"
local bunnyHopStatus = "BunnyHop: On"
local crosshairstatus = "Crosshair: On"

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

local function aimbot()
    if input.IsMouseDown(MOUSE_LEFT) then
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

local function drawWatermark()
    local scrW, scrH = ScrW(), ScrH()
    local center = Vector(scrW / 2, scrH / 2, 0)
    local fovRadius = scrH * (aimFOV / 90)

    surface.SetDrawColor(255, 255, 255, 100)
    surface.DrawCircle(center.x, center.y, fovRadius, Color(255, 255, 255, 100))

    local fontSize = 20
    local lineHeight = fontSize + 2
    
    local textX = 20
    local textY = ScrH() / 2

    draw.SimpleText(aimbotStatus, "BudgetLabel", textX, textY, aimbotColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(aimFOVText, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(aimFOVDraw, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(smoothFactorText, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(espstatus, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(espstatus2, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(espstatus3, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(espstatus4, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(crosshairstatus, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    textY = textY + lineHeight
    draw.SimpleText(bunnyHopStatus, "BudgetLabel", textX, textY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

local function main()
    hook.Add("Think", "Aimbot", aimbot)
    hook.Add("HUDPaint", "Watermark", drawWatermark)
end

hook.Add("CalcView", "", function()
    return{fov = 100}
end)

main()
