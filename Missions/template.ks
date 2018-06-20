@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local launch is import("lib/launch.ks").
    local mission_list is list (
        "PreLaunch", { parameter mission. local l_detail is launch["calcLaunchDetails"](100000, 15, 59). for d in l_detail { pout(d). }. set l_time to l_detail[1]. lock steering to heading(l_detail[0], 90). lock throttle to 1. __["warpUntil"](l_time - 15). mission["next"](). },
        "Launch", { parameter mission. if TIME:SECONDS > l_time mission["startEvent"]("staging"). if SHIP:AIRSPEED > 100 { mission["next"](). } },
        "Turn", { parameter mission. lock steering to st. set th to launch["getThrottle"](). set st to heading(launch["getBearing"](),launch["getPitch"]()). mission["next"](). },
        "Ascend", { parameter mission. ascendControls(). if ship:apoapsis > 100000 { mission["next"](). } },
        "Circularize", { parameter mission. circControls(). if launch["circularized"]() { mission["next"](). } },
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
        set th to launch["circ_thrott"]().
        set st to heading(launch["circ_heading"](), launch["circ_pitch"]()).
    }

    mission["setSequence"](mission_list).
}
