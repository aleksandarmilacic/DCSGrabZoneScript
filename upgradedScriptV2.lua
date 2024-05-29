-- Function to get all airbases that are either BLUE or RED
function getBlueAndRedAirbases()
    local airbases = world.getAirbases()
    local airbasesAndZones = {blue = {}, red = {}}

    for _, airbase in ipairs(airbases) do
        local coalitionSide = airbase:getCoalition()
        if coalitionSide == coalition.side.RED then
            table.insert(airbasesAndZones.red, airbase)
        elseif coalitionSide == coalition.side.BLUE then
            table.insert(airbasesAndZones.blue, airbase)
        end
    end

    return airbasesAndZones
end

-- Function to adjust the coordinates of a point
function adjustCoordinates(point)
    local terrainHeight = land.getHeight({x = point.x, y = point.z})
    return {
        x = point.x,
        z = terrainHeight,  -- Correctly use terrain height as the y coordinate
        y = point.z  -- Correctly use y as the z coordinate
    }
end

-- Table to store smoke units and timers
local smokeManagement = {
    smokeUnits = {},
    timers = {}
}

-- Function to add and manage smoke
function addSmoke(zonePoint, coalitionSide, zoneName)
    local smokeColor = trigger.smokeColor.Red
    if coalitionSide == coalition.side.BLUE then
        smokeColor = trigger.smokeColor.Blue
    end

    local smokePoint = {
        x = zonePoint.x,
        y = zonePoint.y,
        z = zonePoint.z
    }
    
    -- Add smoke at the location
    local smokeID = trigger.action.smoke(smokePoint, smokeColor)
    if not smokeManagement.smokeUnits[zoneName] then
        smokeManagement.smokeUnits[zoneName] = {}
    end
    table.insert(smokeManagement.smokeUnits[zoneName], smokeID)
    
    -- Schedule smoke to be added again every 5 minutes (300 seconds)
    smokeManagement.timers[zoneName] = timer.scheduleFunction(function()
        addSmoke(zonePoint, coalitionSide, zoneName)
    end, {}, timer.getTime() + 300)
end

-- Function to update smoke for a zone
function updateSmoke(zonePoint, coalitionSide, zoneName)
    if smokeManagement.smokeUnits[zoneName] then
        -- Remove existing smoke entries
        smokeManagement.smokeUnits[zoneName] = nil
    end

    -- Cancel the previous timer if it exists
    if smokeManagement.timers[zoneName] then
        timer.removeFunction(smokeManagement.timers[zoneName])
        smokeManagement.timers[zoneName] = nil
    end

    -- Add new smoke for the new coalition
    addSmoke(zonePoint, coalitionSide, zoneName)
end

-- Function to add smoke and infantry units to the airbase
function addSmokeAndInfantry(airbaseName, coalitionSide)
    local airbase = Airbase.getByName(airbaseName)
    local position = adjustCoordinates(airbase:getPoint())
    local smokePosition = airbase:getPoint()

    -- Add smoke
    updateSmoke(smokePosition, coalitionSide, airbaseName)

    -- Spawn infantry units
    local infantryGroupData = {
        ["category"] = Group.Category.GROUND,
        ["country"] = coalitionSide == coalition.side.BLUE and country.id.USA or country.id.RUSSIA,
        ["name"] = airbaseName .. "_Infantry_" .. math.random(1000, 9999),
        ["units"] = {}
    }

    for i = 1, 4 do
        local unit = {
            ["type"] = "Soldier M4",
            ["name"] = airbaseName .. "_Infantry_" .. i,
            ["x"] = position.x + math.random(-10, 10), 
            ["y"] = position.y + math.random(-10, 10),
            ["heading"] = math.random() * 2 * math.pi
        }
        table.insert(infantryGroupData.units, unit)
    end

    coalition.addGroup(infantryGroupData["country"], infantryGroupData["category"], infantryGroupData)
    trigger.action.outText("Infantry units arrived and took control of " .. airbaseName, 10)
end

-- Function to award points to units in a zone
function awardPointsToUnitsInZone(units, points)
    for _, unit in ipairs(units) do
        local playerName = unit:getPlayerName()
        if playerName then
            local player = unit:getPlayer()
            if player then
                player:addScore(points)
                trigger.action.outText("Player " .. playerName .. " awarded " .. points .. " points", 10)
            end
        end
    end
end

-- Function to check and change airbase ownership
function checkAndCaptureAirbase(airbaseName, captureZoneName)
    local redUnitsInZone = mist.getUnitsInZones(mist.makeUnitTable({'[red]'}), {captureZoneName}, 'cylinder')
    local blueUnitsInZone = mist.getUnitsInZones(mist.makeUnitTable({'[blue]'}), {captureZoneName}, 'cylinder')
    local airbase = Airbase.getByName(airbaseName)

    if #redUnitsInZone > 0 and #blueUnitsInZone == 0 then
        if airbase:getCoalition() ~= coalition.side.RED then
            airbase:setCoalition(coalition.side.RED)
            trigger.action.outText(airbaseName .. " captured by RED", 10)
            addSmokeAndInfantry(airbaseName, coalition.side.RED)
            awardPointsToUnitsInZone(redUnitsInZone, 100)
        end
    elseif #blueUnitsInZone > 0 and #redUnitsInZone == 0 then
        if airbase:getCoalition() ~= coalition.side.BLUE then
            airbase:setCoalition(coalition.side.BLUE)
            trigger.action.outText(airbaseName .. " captured by BLUE", 10)
            addSmokeAndInfantry(airbaseName, coalition.side.BLUE)
            awardPointsToUnitsInZone(blueUnitsInZone, 100)
        end
    elseif #redUnitsInZone > 0 and #blueUnitsInZone > 0 then
        trigger.action.outText("Contact at Zone_" .. airbaseName .. ": " .. #redUnitsInZone .. " RED units and " .. #blueUnitsInZone .. " BLUE units engaged!", 10)
    end
end

-- Function to check for win conditions
function checkWinConditions()
    local airbasesAndZones = getBlueAndRedAirbases()
    if #airbasesAndZones.blue == 0 then
        trigger.action.outText("RED Wins! Restarting mission...", 10)
        trigger.action.setUserFlag("win_flag", 1)
    elseif #airbasesAndZones.red == 0 then
        trigger.action.outText("BLUE Wins! Restarting mission...", 10)
        trigger.action.setUserFlag("win_flag", 1)
    end
end

-- Function to initialize capture logic for multiple airbases
function initializeAirbaseCapture()
    -- Get all airbases that are either BLUE or RED
    local airbasesAndZones = getBlueAndRedAirbases()
    local detectedAirbasesMessage = "Detected airbases:\n"

    for _, ab in ipairs(airbasesAndZones.blue) do
        detectedAirbasesMessage = detectedAirbasesMessage .. ab:getName() .. " (BLUE)\n"
        addSmokeAndInfantry(ab:getName(), coalition.side.BLUE) -- Initial setup
        mist.scheduleFunction(checkAndCaptureAirbase, {ab:getName(), "Zone_" .. ab:getName()}, timer.getTime() + 0, 60)
    end

    for _, ab in ipairs(airbasesAndZones.red) do
        detectedAirbasesMessage = detectedAirbasesMessage .. ab:getName() .. " (RED)\n"
        addSmokeAndInfantry(ab:getName(), coalition.side.RED) -- Initial setup
        mist.scheduleFunction(checkAndCaptureAirbase, {ab:getName(), "Zone_" .. ab:getName()}, timer.getTime() + 0, 60)
    end

    trigger.action.outText(detectedAirbasesMessage, 10)
end

-- Function to announce the script is starting
function announceScriptStart()
    trigger.action.outText("Airbase capture script will start in 10 seconds", 10)
end

-- Function to end the mission after 4 hours if no side has won
function endMissionAfterTimeLimit()
    local airbasesAndZones = getBlueAndRedAirbases()
    if #airbasesAndZones.blue > #airbasesAndZones.red then
        trigger.action.outText("Time limit reached. BLUE Wins! Restarting mission...", 10)
    elseif #airbasesAndZones.red > #airbasesAndZones.blue then
        trigger.action.outText("Time limit reached. RED Wins! Restarting mission...", 10)
    else
        trigger.action.outText("Time limit reached. It's a draw! Restarting mission...", 10)
    end
    trigger.action.setUserFlag("win_flag", 1)
end

-- Function to announce remaining mission time
function announceRemainingTime()
    local currentTime = timer.getTime()
    local elapsedTime = currentTime - missionStartTime
    local remainingTime = (4 * 3600) - elapsedTime
    local hours = math.floor(remainingTime / 3600)
    local minutes = math.floor((remainingTime % 3600) / 60)
    trigger.action.outText(string.format("Time remaining: %02d:%02d", hours, minutes), 10)
end

-- Event handler function
function eventHandler(event)
    if event.id == world.event.S_EVENT_KILL then
        local target = event.target
        if target and target:getCategory() == Object.Category.UNIT then
            local unitCoalition = target:getCoalition()
            if unitCoalition == coalition.side.RED or unitCoalition == coalition.side.BLUE then
                local unitPoint = target:getPoint()
                for airbaseName, zoneName in pairs(airbaseZones) do
                    if mist.utils.get2DDist(unitPoint, trigger.misc.getZone(zoneName).point) < trigger.misc.getZone(zoneName).radius then
                        checkAndCaptureAirbase(airbaseName, zoneName)
                    end
                end
            end
        end
    elseif event.id == world.event.S_EVENT_UNIT_LOST then
        local unit = event.initiator
        if unit and unit:getCategory() == Object.Category.UNIT then
            local unitCoalition = unit:getCoalition()
            if unitCoalition == coalition.side.RED or unitCoalition == coalition.side.BLUE then
                local unitPoint = unit:getPoint()
                for airbaseName, zoneName in pairs(airbaseZones) do
                    if mist.utils.get2DDist(unitPoint, trigger.misc.getZone(zoneName).point) < trigger.misc.getZone(zoneName).radius then
                        checkAndCaptureAirbase(airbaseName, zoneName)
                    end
                end
            end
        end
    end
end

-- Register the event handler
world.addEventHandler(eventHandler)

-- Announce the script start and schedule the initial setup
announceScriptStart()
mist.scheduleFunction(initializeAirbaseCapture, {}, timer.getTime() + 10)

-- Schedule periodic checks for win conditions every minute
mist.scheduleFunction(checkWinConditions, {}, timer.getTime() + 60, 60)

-- Schedule the end of mission after 4 hours
missionStartTime = timer.getTime()
mist.scheduleFunction(endMissionAfterTimeLimit, {}, missionStartTime + 4 * 3600)

-- Schedule periodic announcements of remaining mission time every 15 minutes
mist.scheduleFunction(function()
    announceRemainingTime()
    mist.scheduleFunction(announceRemainingTime, {}, timer.getTime() + 15 * 60)
end, {}, timer.getTime() + 15 * 60)
