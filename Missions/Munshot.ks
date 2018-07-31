@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local launch is import("lib/launch.ks", false).
    local maneuver is import("lib/maneuver.ks", false).
    local domun is import("lib/mun.ks", false).
    local nav_landing is import("lib/nav_landing.ks", false).
    local times is import("lib/time.ks", false).
    local mission_list is list (
        "ActivateLaunch", { parameter mission. if AG1 { local l_detail is launch["calcLaunchDetails"](100000). set l_time to TIME:SECONDS + 10. set st to heading(l_detail[0], 90). set th to 1. __["warpUntil"](l_time - 15). lock steering to st. lock throttle to th. mission["next"](). } },
        "Launch", { parameter mission. if ship:status = "PRELAUNCH" and TIME:SECONDS > l_time { mission["startEvent"]("staging"). mission["next"](). } },
        "InitialAscent", { parameter mission. if SHIP:AIRSPEED > 100 { ascendControls(). mission["next"](). } },
        "Ascend", { parameter mission. ascendControls(). if ship:apoapsis > 100000 and ship:altitude > body:atm:height { maneuver["setCircAt"](eta:apoapsis + TIME:SECONDS). maneuver["orientCraft"](). mission["next"](). } },
        "Circularize", { parameter mission. if maneuver["nodeComplete"]() { domun["setTransfer"](60000). maneuver["orientCraft"](). mission["next"](). } },
        "Transfer", { parameter mission. if maneuver["nodeComplete"]() { if orbit:transition = "ENCOUNTER" { times["setTime"]("correction", time:seconds + eta:transition/2). } if orbit:transition = "FINAL" { times["setTime"]("correction", time:seconds + eta:apoapsis/2). } mission["next"](). } },
        "MidCourseCorrection", { parameter mission. __["warpUntil"](times["diffTime"]("correction")). if (not (ship:orbit:transition = "ENCOUNTER")) OR (ship:orbit:nextpatch:periapsis < 10000) { domun["setTransfer"](40000). maneuver["orientCraft"](). mission["setRunMode"]("Transfer"). } else { __["warpUntil"](TIME:SECONDS + eta:transition - 10). mission["next"](). } },
        "WaitForSOI", { parameter mission. if body = Mun { maneuver["setCircAt"](eta:periapsis + TIME:SECONDS). maneuver["orientCraft"](). mission["next"](). } },
        "Capture", { parameter mission. if maneuver["nodeComplete"]() { nav_landing["setTarget"](list(10.16, 47.5)). nav_landing["setLandingNode"](8000). maneuver["orientCraft"](). mission["next"](). } },
        "ExecuteLanding", { parameter mission. if maneuver["nodeComplete"]() { nav_landing["spotLand"](). mission["endMission"](). } }
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
