@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local launch is import("lib/launch.ks", false).
    local maneuver is import("lib/maneuver.ks", false).
    local domun is import("lib/mun.ks", false).
    local nav_landing is import("lib/nav_landing.ks", false).
    local times is import("lib/time.ks", false).
    local orbiter is import("lib/orbit.ks", false).
    local mission_list is list (
        "ActivateLaunch", {
            parameter mission.
            if AG1 {
                local l_detail is launch["calcLaunchDetails"](100000).
                set l_time to TIME:SECONDS + 10.
                set st to heading(l_detail[0], 90).
                set th to 1.
                __["warpUntil"](l_time - 15).
                lock steering to st.
                lock throttle to th.
                pout("Launch").
                mission["next"]().
            }
        },
        "Launch", {
            parameter mission.
            if ship:status = "PRELAUNCH" and TIME:SECONDS > l_time {
                mission["startEvent"]("staging").
                pout("InitialAscent").
                mission["next"]().
            }
        },
        "InitialAscent", {
            parameter mission.
            if SHIP:AIRSPEED > 100 {
                ascendControls().
                pout("Ascend").
                mission["next"]().
            }
        },
        "Ascend", {
            parameter mission.
            ascendControls().
            if ship:apoapsis > 100000 and ship:altitude > body:atm:height {
                unlock all.
                orbiter["setCircNodeAt"](eta:apoapsis + TIME:SECONDS).
                wait 0.
                maneuver["orientCraft"]().
                wait 1.
                pout("Circularize").
                mission["next"]().
            }
        },
        "Circularize", {
            parameter mission.
            if maneuver["nodeComplete"]() {
                domun["setMunTransfer"](20000).
                wait 0.
                maneuver["orientCraft"]().
                wait 1.
                pout("Transfer").
                mission["next"]().
            }
        },
        "Transfer", {
            parameter mission.
            if maneuver["nodeComplete"]() {
                if orbit:transition = "FINAL" {
                    times["setTime"]("correction", time:seconds + eta:apoapsis/2).
                } else {
                    times["setTime"]("correction", time:seconds + eta:transition/2).
                }
                pout("MidCourseCorrection").
                mission["next"]().
            }
        },
        "MidCourseCorrection", {
            parameter mission.
            __["warpUntil"](times["diffTime"]("correction")).
            wait 1.
            if (not (ship:orbit:transition = "ENCOUNTER")) OR
            (ship:orbit:nextpatch:periapsis < 10000) OR
            (ship:orbit:nextpatch:periapsis > 1000000) {
                domun["setMunTransfer"](20000).
                wait 0.
                maneuver["orientCraft"]().
                wait 1.
                pout("(re)Transfer").
                mission["setRunMode"]("Transfer").
            } else {
                __["warpUntil"](TIME:SECONDS + eta:transition - 10).
                pout("WaitForSOI").
                mission["next"]().
            }
        },
        "WaitForSOI", {
            parameter mission.
            if body = Mun {
                local t is time:seconds + eta:periapsis.
                if periapsis < 15000 {
                    UNTIL (((positionat(ship, t) - body:position):mag > 15000) OR (t < (time:seconds + 15))) { set t to t - 10. }
                }
                orbiter["setCircNodeAt"](t).
                wait 0.
                maneuver["orientCraft"]().
                wait 1.
                pout("CircularizeAndFlatten").
                mission["next"]().
            }
        },
        "CircularizeAndFlatten", {
            parameter mission.
            if maneuver["nodeComplete"](). {
                if not orbiter["matchOrbit"](lex("PER", 15000, "APO", 15000, "INC", 0)) {
                    wait 0.
                    maneuver["orientCraft"]().
                    wait 1.
                } else {
                    pout("Deorbit").
                    mission["next"]().
                }
            }
        },
        "Deorbit", {
            parameter mission.
            nav_landing["setTarget"](list(10.16, 47.5)).
            nav_landing["setLandingNode"](8000).
            wait 0.
            maneuver["orientCraft"]().
            wait 1.
            pout("ExecuteLanding").
            mission["next"]().
        },
        "ExecuteLanding", {
            parameter mission.
            if maneuver["nodeComplete"]() {
                nav_landing["spotLand"]().
                mission["endMission"]().
            }
        }
    ).
    local th is 0.
    local st is ship:prograde:forevector.
    local l_time is 0.

    function ascendControls {
        set th to launch["getThrottle"]().
        set st to heading(launch["getBearing"](),launch["getPitch"]()).
    }

    mission["setSequence"](mission_list).
}
