@LAZYGLOBAL OFF.
{
    parameter mission.
    local mission_list is list (
        "PreLaunch", { pout("PreLaunch"). wait(5). mission["next"](). },
        "Launch", { pout("Whee!"). mission["startEvent"]("staging"). wait(5). mission["next"](). },
        "MECO", { pout("Bamf!"). wait(5). mission["next"](). },
        "Circularize", { pout("I think I can..."). wait(5). }
    ).
    mission["setSequence"](mission_list).
}
