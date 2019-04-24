@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local launchFactory is import("class/launch.ks", false).
    local maneuver is import("lib/maneuver.ks", false).
    local target_altitude = 250000.
    local target_inclination = 0.
    local target_LAN = false.
    local launch is false.
    local mission_list is list (
        // Runs once, sets up the launch parameters and moves on to countdown and launch
        "PreLaunch", { 
            parameter mission. 
            set launch to launchFactory(target_altitude, target_inclination, target_LAN). 
            mission["next"](). 
        },
        // Waits for the launch time, then sets the controls and activates staging
        "Launch", { 
            parameter mission. 
            if ship:status = "PRELAUNCH" and launch["isCountdownDone"]() { 
                set ship:control:pilotmainthrottle to 0.
                mission["startEvent"]("staging"). 
                mission["next"](). 
            } 
        },
        // Continues to update controls until the ascent is complete
        "Ascend", { 
            parameter mission. 
            if launch["isAscentComplete"]() { 
                mission["next"](). 
            } 
        },
        // Circularizes the craft
        "Circularize", { 
            parameter mission. 
            if maneuver["isCircularized"](target_altitude) { 
                mission["next"](). 
            } 
        },
        // Disables the controls and releases them
        "Finish", { 
            parameter mission.  
            wait(15). 
            mission["endMission"](). 
        }
    ).

    mission["setSequence"](mission_list).
}
