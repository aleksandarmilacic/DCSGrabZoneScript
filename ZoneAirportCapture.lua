grabber = {}
grabber.version = "3.0.0"
grabber.uuid = 0
grabber.smokeUnits = {}
grabber.timers = {}  -- Table to store the timer handles

function grabber.getUUID()
    grabber.uuid = grabber.uuid + 1 
    return grabber.uuid 
end

function grabber.isUnitInZone(unit, zone)
    local unitPoint = unit:getPoint()
    local zonePoint = grabber.getZoneCenter(zone)

    local dx = unitPoint.x - zonePoint.x
    local dz = unitPoint.z - zonePoint.y -- zone point needs to use y instead of Z
    local dist = math.sqrt(dx * dx + dz * dz)

    return dist <= trigger.misc.getZone(zone).radius
end

function grabber.checkUnitsInZone(zoneName, coalitionSide)
    local unitsInZone = false
    local groups = coalition.getGroups(coalitionSide)
    for _, group in ipairs(groups) do
        for _, unit in ipairs(group:getUnits()) do
            if grabber.isUnitInZone(unit, zoneName) then
                unitsInZone = true
                break
            end
        end
        if unitsInZone then break end
    end
    return unitsInZone
end

function grabber.getZoneCenter(zoneName)
    local zone = trigger.misc.getZone(zoneName)
    if zone then
        local terrainHeight = land.getHeight({x = zone.point.x, y = zone.point.z})
        local adjustedPoint = {
            x = zone.point.x,
            z = terrainHeight,  -- Correctly use terrain height as the y coordinate
            y = zone.point.z  -- Correctly use y as the z coordinate
        }
        return adjustedPoint
    end
    return nil
end

function grabber.checkZones()
    local airbases = world.getAirbases()
    for _, airbase in pairs(airbases) do
        local zoneName = "Zone_" .. airbase:getName()
        local zonePoint = grabber.getZoneCenter(zoneName)
        if zonePoint then
            local redInZone = grabber.checkUnitsInZone(zoneName, coalition.side.RED)
            local blueInZone = grabber.checkUnitsInZone(zoneName, coalition.side.BLUE)

            -- Determine ownership based on unit presence
            local currentCoalition = airbase:getCoalition()
            if redInZone and not blueInZone then
                if currentCoalition ~= coalition.side.RED then
                    airbase:setCoalition(coalition.side.RED)
                    trigger.action.outText("Airbase " .. airbase:getName() .. " captured by RED", 10)
                    grabber.updateSmoke(zonePoint, coalition.side.RED, zoneName)
                    grabber.awardPointsToPlayers(zoneName, 100, coalition.side.RED)
                    grabber.spawnCaptureUnits(zonePoint, coalition.side.RED, zonePoint)
                end
            elseif blueInZone and not redInZone then
                if currentCoalition ~= coalition.side.BLUE then
                    airbase:setCoalition(coalition.side.BLUE)
                    trigger.action.outText("Airbase " .. airbase:getName() .. " captured by BLUE", 10)
                    grabber.updateSmoke(zonePoint, coalition.side.BLUE, zoneName)
                    grabber.awardPointsToPlayers(zoneName, 100, coalition.side.BLUE)
                    grabber.spawnCaptureUnits(zonePoint, coalition.side.BLUE, zonePoint)
                end
            end
        end
    end
end

function grabber.updateSmoke(zonePoint, coalitionSide, zoneName)
    if grabber.smokeUnits[zoneName] then
        -- Remove existing smoke entries from our table
        grabber.smokeUnits[zoneName] = nil
    end

    -- Cancel the previous timer if it exists
    if grabber.timers[zoneName] then
        timer.removeFunction(grabber.timers[zoneName])
        grabber.timers[zoneName] = nil
    end

    -- Add new smoke for the new coalition
    grabber.addSmoke(zonePoint, coalitionSide, zoneName)
end

function grabber.addSmoke(zonePoint, coalitionSide, zoneName)
    local smokeColor = trigger.smokeColor.Red
    if coalitionSide == coalition.side.BLUE then
        smokeColor = trigger.smokeColor.Blue
    end

    local smokePoint = {
        x = zonePoint.x,
        y = zonePoint.y,
        z = zonePoint.z
    }
    
    -- Add smoke at the smoke location 
    local smokeID = trigger.action.smoke({x = smokePoint.x,  y = smokePoint.z, z = smokePoint.y}, smokeColor)
    if not grabber.smokeUnits[zoneName] then
        grabber.smokeUnits[zoneName] = {}
    end
    table.insert(grabber.smokeUnits[zoneName], smokeID)
    
    -- Respawn smoke every 5 minutes (300 seconds)
    grabber.timers[zoneName] = timer.scheduleFunction(function()
        grabber.addSmoke(zonePoint, coalitionSide, zoneName)
    end, {}, timer.getTime() + 300)
end

function grabber.spawnCaptureUnits(tentPoint, coalitionSide, zonePoint)
    local spawnUnits = {
        ["RED"] = {
            {type = "BTR-80", name = "Red APC"},
            {type = "Soldier M4", name = "Red Soldier"},
            {type = "ZU-23 Emplacement Closed", name = "Red AAA"},
            {type = "outpost_tent", name = "Red Tent"}
        },
        ["BLUE"] = {
            {type = "HMMWV", name = "Blue Vehicle"},
            {type = "Soldier M4", name = "Blue Soldier"},
            {type = "Vulcan", name = "Blue AAA"},
            {type = "outpost_tent", name = "Blue Tent"}
        }
    }
    local coalitionName = coalitionSide == coalition.side.BLUE and "BLUE" or "RED"
    local groupData = {
        ["category"] = Group.Category.GROUND,
        ["country"] = coalitionSide == coalition.side.BLUE and country.id.USA or country.id.RUSSIA,
        ["name"] = "Capture Group " .. grabber.getUUID(),
        ["units"] = {}
    }
    for _, unitData in ipairs(spawnUnits[coalitionName]) do
        local unitOffset = 40  -- Increase offset distance for spacing
        local unitPoint = {
            x = tentPoint.x + math.random(-unitOffset, unitOffset),
            y = tentPoint.y,
            z = tentPoint.z + math.random(-unitOffset, unitOffset)
        }
        table.insert(groupData.units, {
            ["type"] = unitData.type,
            ["name"] = unitData.name .. " " .. grabber.getUUID(),
            ["x"] = unitPoint.x,
            ["y"] = unitPoint.y,
            ["heading"] = math.random() * 2 * math.pi
        })
    end
    coalition.addGroup(groupData["country"], Group.Category.GROUND, groupData)
    trigger.action.outText("Spawned capture units for " .. coalitionName .. " at tent location", 10)
end

function grabber.awardPointsToPlayers(zoneName, points, coalitionSide)
    local groups = coalition.getGroups(coalitionSide)

    for _, group in ipairs(groups) do
        for _, unit in ipairs(group:getUnits()) do
            if unit:getPlayerName() and grabber.isUnitInZone(unit, zoneName) then
                local playerName = unit:getPlayerName()
                unit:getPlayer():addScore(points)
                trigger.action.outText("Player " .. playerName .. " awarded " .. points .. " points for capturing " .. zoneName, 10)
            end
        end
    end
end

function grabber.initializeSmokesAndUnits()
    local airbases = world.getAirbases()
    for _, airbase in pairs(airbases) do
        local zoneName = "Zone_" .. airbase:getName()
        local zonePoint = grabber.getZoneCenter(zoneName)
        if zonePoint then
            local currentCoalition = airbase:getCoalition()
            grabber.addSmoke(zonePoint, currentCoalition, zoneName)
        end
    end
end

function grabber:onEvent(event)
    if not event then return end 
    if event.id == world.event.S_EVENT_LAND or event.id == world.event.S_EVENT_TAKEOFF or event.id == world.event.S_EVENT_BASE_CAPTURE then
        grabber.checkZones()
    end
end

-- Start up
world.addEventHandler(grabber)
timer.scheduleFunction(grabber.initializeSmokesAndUnits, {}, timer.getTime() + 5)  -- Initialize smokes and units at mission start
timer.scheduleFunction(grabber.checkZones, {}, timer.getTime() + 10, 60)  -- Check zones every 60 seconds
