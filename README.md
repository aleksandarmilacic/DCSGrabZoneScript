# Airbase Capture and Smoke Script for DCS

This script is designed for use in DCS (Digital Combat Simulator) to manage the capture of airbases by either the RED or BLUE coalition. It includes features to spawn smoke and infantry units at captured airbases and award points to players in the capture zone.

## Requirements
- DCS World
- MIST (Mission Scripting Tool) v4.5.126 or later

## Installation

1. **Place the Scripts**:
   - Ensure `mist.lua` is correctly placed in your mission directory.
   - Create a new script file (e.g., `airbase_capture.lua`) and paste the provided script into this file.

2. **Load MIST in Your Mission**:
   - Open the DCS Mission Editor.
   - Create a new trigger to load MIST at mission start:
     - **Event**: MISSION START
     - **Action**: DO SCRIPT FILE
     - **File**: Select the `mist.lua` file.

3. **Load the Airbase Capture Script**:
   - Create another trigger in your mission with the following properties:
     - **Event**: MISSION START
     - **Action**: DO SCRIPT
     - **Script**: Select and load the `airbase_capture.lua` file.

4. **Save and Test Your Mission**:
   - Save your mission in the DCS Mission Editor.
   - Run your mission to verify the script functionality.

## Features

1. **Airbase Capture**:
   - The script detects all airbases held by either RED or BLUE coalitions.
   - It monitors the presence of units in predefined zones around these airbases.
   - When all enemy units are eliminated from a zone, the airbase is captured by the coalition that controls the zone.

2. **Smoke and Infantry Spawn**:
   - When an airbase is captured, smoke in the color of the capturing coalition is spawned at the airbase.
   - Infantry units are also spawned at the airbase for the capturing coalition.
   - Smoke is re-added every 5 minutes to indicate ongoing control.

3. **Points Awarded to Players**:
   - All units in the capture zone receive points when their coalition captures an airbase.
   - Players who participated in the capture, including those who made the last kill, are awarded points.

## Script Overview

```lua
-- Script to manage airbase capture, smoke, and infantry spawning, and to award points to players in the capture zone.

-- Function definitions:
-- getBlueAndRedAirbases: Identifies airbases held by RED or BLUE.
-- adjustCoordinates: Adjusts coordinates to include terrain height.
-- addSmoke: Adds smoke to indicate coalition control of an airbase.
-- updateSmoke: Updates smoke by removing old smoke and adding new smoke.
-- addSmokeAndInfantry: Adds smoke and spawns infantry units at the airbase.
-- awardPointsToUnitsInZone: Awards points to units in a specified zone.
-- checkAndCaptureAirbase: Checks unit presence in capture zones and changes airbase ownership if conditions are met.
-- initializeAirbaseCapture: Initializes capture logic for all detected airbases.
-- announceScriptStart: Announces the script start and schedules the initial setup.

-- Event handling and initialization:
-- Announces script start and schedules the initial setup.

```
Customization
Adjusting Points Awarded: Modify the awardPointsToUnitsInZone function to change the number of points awarded.
Changing Infantry Unit Types: Modify the addSmokeAndInfantry function to change the types of infantry units spawned.
Zone Names: Ensure the zone names in your mission editor match the format "Zone_<AirbaseName>".

**Troubleshooting**
No Smoke or Infantry: Ensure that the zone names in your mission editor match the format "Zone_<AirbaseName>".
Script Not Running: Verify that MIST is correctly loaded before the airbase capture script.
Debugging: Use trigger.action.outText to print debug messages to the screen if you encounter issues.

