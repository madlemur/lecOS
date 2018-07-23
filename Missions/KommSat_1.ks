@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local launch is import("lib/launch.ks", false).
    local maneuver is import("lib/maneuver.ks", false).
    local mission_list is list (
        "ActivateLaunch", { parameter mission. if AG1 { mission["next"](). } },
        "PreLaunch", { parameter mission. local l_detail is launch["calcLaunchDetails"](450000). for d in l_detail { pout(d). }. set l_time to TIME:SECONDS + 10. set st to heading(l_detail[0], 90). set th to 1. __["warpUntil"](l_time - 15). lock steering to st. lock throttle to th. mission["next"](). },
        "Launch", { parameter mission. if ship:status = "PRELAUNCH" and TIME:SECONDS > l_time { mission["startEvent"]("staging"). mission["next"](). } },
        "InitialAscent", { parameter mission. if SHIP:AIRSPEED > 100 { mission["next"](). } },
        "Turn", { parameter mission. ascendControls(). mission["next"](). },
        "Ascend", { parameter mission. ascendControls(). if ship:apoapsis > 450000 and ship:altitude > body:atm:height { RCS ON. mission["next"](). } },
        "Circularize", { parameter mission. circControls(). if maneuver["circularized"]() { mission["next"](). } },
        "Finish", { parameter mission. lock throttle to 0. lock steering to body("sun"):position. wait(15). RCS OFF. unlock throttle. unlock steering. mission["endMission"](). }
    ).
    local th is 0.
    local st is ship:prograde:forevector.
    local l_time is 0.

    function ascendControls {
        set th to launch["getThrottle"]().
        set st to heading(launch["getBearing"](),launch["getPitch"]()).
    }

    function circControls {
        local dv is maneuver["circ_deltav"]().
        set th to maneuver["circ_thrott"](dv).
        set st to lookdirup(dv, -body:position).
    }

    mission["setSequence"](mission_list).
}
