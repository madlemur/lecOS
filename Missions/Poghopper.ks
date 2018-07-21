@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local launch is import("lib/launch.ks", false).
    local staging is import("lib/staging.ks", false).
    local mission_list is list (
        "PreLaunch", { parameter mission. lock steering to st. lock throttle to th. mission["next"](). },
        "Launch", { parameter mission. if ship:status = "PRELAUNCH" { mission["startEvent"]("staging"). mission["next"](). } },
        "InitialAscent", { parameter mission. ascendControls(). if SHIP:ALTITUDE > 150 { mission["next"](). } },
        "Traverse", { parameter mission. ascendControls(true). if ship:altitude > 500 { mission["next"](). } },
        "Descend", { parameter mission. decendControls(). }
    ).
    local th is 0.
    local st is ship:prograde:forevector.
    local l_time is 0.
    local pitch is 90.

    function ascendControls {
        parameter traverse is false.
        local cov is vxcl(ship:up:vector, waypoint("Black Monolith"):position).
        if traverse { set pitch to max(60, 90-cov:mag/150). }
        set th to 1.
        set st to heading(compass_of_vec(waypoint("Black Monolith"):position), pitch).
    }

    function decendControls {
        local cov is vxcl(ship:up:vector, waypoint("Black Monolith"):position).
        set pitch to max(60, 90-cov:mag/100).
        set th to 1/staging["thrustToWeight"]() * 0.9.
        set st to heading(compass_of_vec(waypoint("Black Monolith"):position), pitch).
    }

    function compass_of_vec {
        parameter tgt_vec.
        local trig_x is vdot(heading(90, 0):vector, tgt_vec).
        local trig_y is vdot(heading(0, 0):vector, tgt_vec).

        return mod(arctan2(trig_y, trig_x) + 360, 360).
    }

    function circControls {
        local dv is launch["circ_deltav"]().
        set th to launch["circ_thrott"](dv).
        set st to lookdirup(dv, -body:position).
    }

    mission["setSequence"](mission_list).
}
