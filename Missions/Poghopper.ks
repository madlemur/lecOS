@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local launch is import("lib/launch.ks", false).
    local staging is import("lib/staging.ks", false).
    local mission_list is list (
        "PreLaunch", { parameter mission. lock steering to st. lock throttle to th. mission["next"](). },
        "Launch", { parameter mission. if ship:status = "PRELAUNCH" { mission["startEvent"]("staging"). mission["next"](). } },
        "InitialAscent", { parameter mission. ascendControls(). if SHIP:ALTITUDE > 80 { mission["next"](). } },
        "Traverse", { parameter mission. ascendControls(true). if ship:apoapsis > 900
           AND ship:verticalspeed < 60 { RCS ON. when im < 3 then {gear on.} mission["next"](). } },
        "Descend", { parameter mission. decendControls(). }
    ).
    local th is 0.
    local st is ship:prograde:forevector.
    local l_time is 0.
    local pitch is 90.
    lock tr to alt:radar.
    local d_g is constant:g * body:mass / body:radius^2.
    lock md to (ship:availablethrust / ship:mass) - d_g.
    lock sd to ship:verticalspeed^2 / (2 * md).
    lock it to sd / tr.
    lock im to tr / abs(ship:verticalspeed).

    function ascendControls {
        parameter traverse is false.
        local cov is vxcl(ship:up:vector, waypoint("Black Monolith"):position).
        if traverse { set pitch to (90 - min(35, cov:mag/10)). }
        if ship:apoapsis > 500 { set th to 0.98/staging["thrustToWeight"](). } else { set th to 1. }
        set st to heading(compass_of_vec(waypoint("Black Monolith"):position), pitch).
    }

    function decendControls {
        // local cov is vxcl(ship:up:vector, waypoint("Black Monolith"):position).
        // set pitch to max(60, 90-cov:mag/100).
        if ship:verticalspeed < -1 AND tr < sd + 2 {
          set th to it.
        } else {
          set th to 0.
        }
        set st to srfretrograde. //heading(compass_of_vec(waypoint("Black Monolith"):position), pitch).
    }

    function compass_of_vec {
        parameter tgt_vec.
        local east is vcrs(ship:up:vector, ship:north:vector).

        local trig_x is vdot(ship:north:vector, tgt_vec).
        local trig_y is vdot(east, tgt_vec).

        return mod(arctan2(trig_y, trig_x) + 360, 360).
    }

    function circControls {
        local dv is launch["circ_deltav"]().
        set th to launch["circ_thrott"](dv).
        set st to lookdirup(dv, -body:position).
    }

    mission["setSequence"](mission_list).
}
