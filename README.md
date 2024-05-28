# DCS Smoke and Capture Points Script

This script manages the spawning of smoke at airbases in DCS World and awards points to player-controlled units that capture the airbase. The script ensures that the smoke is continuously spawned every 5 minutes and that points are awarded to players within the capture zone. Additionally, the script stops the previous smoke respawn timer when a coalition change occurs to prevent multiple smokes from overlapping.

## Features

- **Smoke Management**: Spawns smoke at airbases and updates it every 5 minutes.
- **Coalition Change Handling**: Updates smoke color when the coalition changes.
- **Points Awarding**: Awards points to player-controlled units in the capture zone when the airbase is captured.
- **Timer Management**: Ensures that previous timers are stopped when a coalition change occurs.

## Installation

1. Copy the script to your DCS mission scripting environment.
2. Ensure you have the required permissions to execute scripts in your mission.
3. Include the script in your mission startup scripts.

## Usage

The script automatically initializes and runs in the background once included in your mission. It will:
1. Initialize smoke at all airbases.
2. Check the status of airbases and update smoke color and coalition ownership as needed.
3. Award points to player-controlled units within the capture zone upon capturing an airbase.

### Example

```lua
world.addEventHandler(grabber)
timer.scheduleFunction(grabber.initializeSmokesAndUnits, {}, timer.getTime() + 5)  -- Initialize smokes and units at mission start
timer.scheduleFunction(grabber.checkZones, {}, timer.getTime() + 10, 60)  -- Check zones every 60 seconds
