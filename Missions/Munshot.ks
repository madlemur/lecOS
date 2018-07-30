@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local launch is import("lib/launch.ks", false).
    local maneuver is import("lib/maneuver.ks", false).
    local domun is import("lib/mun.ks", false).
    local nav_landing is import("lib/nav_landing.ks", false).
    local mission_list is list (
        "ActivateLaunch", { parameter mission. if AG1 { mission["next"](). } },
        "PreLaunch", { parameter mission. local l_detail is launch["calcLaunchDetails"](100000). set l_time to TIME:SECONDS + 10. set st to heading(l_detail[0], 90). set th to 1. __["warpUntil"](l_time - 15). lock steering to st. lock throttle to th. mission["next"](). },
        "Launch", { parameter mission. if ship:status = "PRELAUNCH" and TIME:SECONDS > l_time { mission["startEvent"]("staging"). mission["next"](). } },
        "InitialAscent", { parameter mission. if SHIP:AIRSPEED > 100 { mission["next"](). } },
        "Turn", { parameter mission. ascendControls(). mission["next"](). },
        "Ascend", { parameter mission. ascendControls(). if ship:apoapsis > 100000 and ship:altitude > body:atm:height { mission["next"](). } },
        "Circularize", { parameter mission. circControls(). if maneuver["circularized"]() { mission["next"](). } },
        "CalcTransfer", { parameter mission. domun["setTransfer"](60000). maneuver["orientCraft"](). mission["next"](). },
        "PrepTransfer", { parameter mission. if maneuver["isOriented"]() { mission["next"](). } },
        "Transfer", { parameter mission. if maneuver["nodeComplete"]() { mission["next"](). } },
        "Capture", { parameter mission. circControls(false). if maneuver["circularized"]() { mission["next"](). } },
        "CalcLanding", { parameter mission. nav_landing["setTarget"](10.16, 47.5). nav_landing["setLandingNode"](18000). maneuver["orientCraft"](). mission["next"](). },
        "PrepLanding",  { parameter mission. if maneuver["isOriented"]() { mission["next"](). } },
        "ExecuteFlyover", { parameter mission. if maneuver["nodeComplete"]() { mission["next"](). } },
        "Landing", { parameter mission. nav_landing["spotLand"](). mission["endMission"](). }
    ).
    local th is 0.
    local st is ship:prograde:forevector.
    local l_time is 0.

    function ascendControls {
        set th to launch["getThrottle"]().
        set st to heading(launch["getBearing"](),launch["getPitch"]()).
    }

    function circControls {
        parameter at_apo is true.
        local dv is maneuver["circ_deltav"](at_apo).
        set th to maneuver["circ_thrott"](dv, at_apo).
        set st to lookdirup(dv, -body:position).
    }

    mission["setSequence"](mission_list).
}
