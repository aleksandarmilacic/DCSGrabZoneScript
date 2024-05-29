-- Function to get all groups that start with "Respawn_"
function getRespawnGroups()
    local respawnGroups = {}

    -- Check all coalitions for groups
    local sides = { coalition.side.RED, coalition.side.BLUE, coalition.side.NEUTRAL }
    for _, side in ipairs(sides) do
        local groups = coalition.getGroups(side)
        for _, group in ipairs(groups) do
            if string.sub(group:getName(), 1, 8) == "Respawn_" then
                table.insert(respawnGroups, group:getName())
            end
        end
    end

    return respawnGroups
end

-- Function to initialize the continuous spawn logic for a group
function continuousSpawn(groupName)
    -- Check if the group is dead
    if mist.groupIsDead(groupName) then
        -- Respawn the group
        mist.respawnGroup(groupName, true)
        trigger.action.outText(groupName .. " has been respawned", 10)
    end
    -- Schedule the next check in 30 seconds
    mist.scheduleFunction(continuousSpawn, {groupName}, timer.getTime() + 30)
end

-- Function to start the continuous spawn logic for all "Respawn_" groups
function startContinuousSpawn()
    local respawnGroups = getRespawnGroups()
    local detectedGroupsMessage = "Detected groups:\n"
    
    for _, groupName in ipairs(respawnGroups) do
        detectedGroupsMessage = detectedGroupsMessage .. groupName .. "\n"
        continuousSpawn(groupName)
    end
    
    trigger.action.outText(detectedGroupsMessage, 10)
end

-- Start the continuous spawn logic after a short delay to ensure mission initialization
trigger.action.outText("Starting respawn logic in 10 seconds", 10)
mist.scheduleFunction(startContinuousSpawn, {}, timer.getTime() + 10)
