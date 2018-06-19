@LAZYGLOBAL OFF.
{
    parameter mission.
    local mission_list is list (
        "PreLaunch", { parameter mission. pout("PreLaunch"). wait(5). mission["next"](). },
        "Launch", { parameter mission. pout("Whee!"). lock throttle to 1. mission["startEvent"]("staging"). mission["next"](). },
        "MECO", { parameter mission. if ship:apoapsis > 85000 { lock throttle to 0. mission["next"](). } },
        "Circularize", { parameter mission. pout("I think I can..."). if ship:altitude > body:atm:height { panels on. unlock throttle. unlock steering. mission["endMission"](). } wait(2). }
    ).
    mission["setSequence"](mission_list).
}
