-- cap base logic

-- Function to get all airbases that are either BLUE or RED
function getBlueAndRedAirbases()
    local airbases = world.getAirbases()
    local airbasesAndZones = {}

    for _, airbase in ipairs(airbases) do
        local coalitionSide = airbase:getCoalition()
        if coalitionSide == coalition.side.RED or coalitionSide == coalition.side.BLUE then
            local airbaseName = airbase:getName()
            local zoneName = "Zone_" .. airbaseName  -- Assuming zones are named "Zone_<AirbaseName>"
            table.insert(airbasesAndZones, {airbase = airbaseName, zone = zoneName})
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
    trigger.action.outText("Infantry units added to " .. airbaseName, 10)
end

-- Function to check and change airbase ownership
function checkAndCaptureAirbase(airbaseName, captureZoneName)

-- Debugging capture zone name
    trigger.action.outText("Debug: Checking capture zone - " .. captureZoneName, 10)
    local redUnitsInZone = mist.getUnitsInZones(mist.makeUnitTable({'[red]'}), {captureZoneName}, 'cylinder')
    local blueUnitsInZone = mist.getUnitsInZones(mist.makeUnitTable({'[blue]'}), {captureZoneName}, 'cylinder')
    local airbase = Airbase.getByName(airbaseName)
  -- Debugging unit counts
    trigger.action.outText("Debug: Units in zone - RED: " .. #redUnitsInZone .. ", BLUE: " .. #blueUnitsInZone, 10)
    
    if #redUnitsInZone > 0 and #blueUnitsInZone == 0 then
        if airbase:getCoalition() ~= coalition.side.RED then
            airbase:setCoalition(coalition.side.RED)
            trigger.action.outText(airbaseName .. " captured by RED", 10)
            addSmokeAndInfantry(airbaseName, coalition.side.RED)
        end
    elseif #blueUnitsInZone > 0 and #redUnitsInZone == 0 then
        if airbase:getCoalition() ~= coalition.side.BLUE then
            airbase:setCoalition(coalition.side.BLUE)
            trigger.action.outText(airbaseName .. " captured by BLUE", 10)
            addSmokeAndInfantry(airbaseName, coalition.side.BLUE)
        end
    end
end

-- Function to initialize capture logic for multiple airbases
function initializeAirbaseCapture()
    -- Get all airbases that are either BLUE or RED
    local airbasesAndZones = getBlueAndRedAirbases()
    local detectedAirbasesMessage = "Detected airbases:\n"

    for _, ab in ipairs(airbasesAndZones) do
        detectedAirbasesMessage = detectedAirbasesMessage .. ab.airbase .. "\n"
        addSmokeAndInfantry(ab.airbase, Airbase.getByName(ab.airbase):getCoalition()) -- Initial setup
        mist.scheduleFunction(checkAndCaptureAirbase, {ab.airbase, ab.zone}, timer.getTime() + 0, 60)
    end

    trigger.action.outText(detectedAirbasesMessage, 10)
end

-- Function to announce the script is starting
function announceScriptStart()
    trigger.action.outText("Airbase capture script will start in 10 seconds", 10)
end

-- Announce the script start and schedule the initial setup
announceScriptStart()
mist.scheduleFunction(initializeAirbaseCapture, {}, timer.getTime() + 10)
