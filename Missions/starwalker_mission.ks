// Herald Mission Script
// Kevin Gisi
// http://youtube.com/gisikw

{
  local TARGET_ALTITUDE is 80000.

  global starwalker_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "circularize", circularize@,
      "idle", idle@
    ),
    "events", lex()
  ).

  function preflight {
    parameter mission.
    set ship:control:pilotmainthrottle to 0.
    lock throttle to 1.
    lock steering to heading(10, 90).
    wait 5.
    mission["next"]().
  }

  function launch {
    parameter mission.
    stage. wait 5.
    lock pct_alt to alt:radar / TARGET_ALTITUDE.
    lock target_pitch to -90 * pct_alt^0.5 + 90.
    lock throttle to 1. // Honestly, just lock throttle to 1
    lock steering to heading(10, target_pitch).
    mission["next"]().
  }

  function ascent {
    parameter mission.
    if available_twr < .01 {
      stage.
    }
    if apoapsis > TARGET_ALTITUDE {
      lock throttle to 0.
      lock steering to prograde.
      wait 1.
      stage.
      wait until alt:radar > body:atm:height.
      mission["next"]().
    }
  }

  function circularize {
    parameter mission.

    // Find good circularization dV
    local dV is list(0).
    set dV to hillclimb["seek"](dV, circular_fitness@, 100).
    set dV to hillclimb["seek"](dV, circular_fitness@, 10).
    set dV to hillclimb["seek"](dV, circular_fitness@, 1).
    set dV to hillclimb["seek"](dV, circular_fitness@, 0.2).

    // Execute maneuver
    add node(time:seconds + eta:apoapsis, 0, 0, dV[0]). wait 0.1.
    maneuver["exec"]().
    lock throttle to 0.
    wait 1.
    mission["next"]().
  }

  function enable_antennae {
    parameter mission.

    local p to ship:partstitled("Communotron 16")[0].
    local m to p:getmodule("ModuleRTAntenna").
    m:doevent("Activate").
    mission["next"]().
  }

  function idle {
    parameter mission.
    // Do nothing
  }

  function available_twr {
    local g is body:mu / (ship:altitude + body:radius)^2.
    return ship:maxthrust / g / ship:mass.
  }

  function circular_fitness {
    parameter data.
    local maneuver is node(time:seconds + eta:apoapsis, 0, 0, data[0]).
    local fitness is 0.
    add maneuver. wait 0.01.
    set fitness to -maneuver:orbit:eccentricity.
    remove_any_nodes().
    return fitness.
  }

  function remove_any_nodes {
    until not hasnode {
      remove nextnode. wait 0.01.
    }
  }
}
