// Herald Mission Script
// Kevin Gisi
// http://youtube.com/gisikw

{
  local TARGET_ALTITUDE is 100000.

  global munview_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "circularize", circularize@,
      "enable_antennae", enable_antennae@,
      "perform_transfer", perform_transfer@,
      "perform_capture", perform_capture@,
      "idle", idle@
    ),
    "events", lex()
  ).

  function preflight {
    parameter mission.
    set ship:control:pilotmainthrottle to 0.
    lock throttle to 1.
    lock steering to heading(90, 90).
    wait 5.
    mission["next"]().
  }

  function launch {
    parameter mission.
    stage. wait 5.
    lock pct_alt to min(1.0, max(0, alt:radar / (body:atm:height * 0.85))).
    lock target_pitch to -90 * pct_alt^0.5 + 90.
    lock throttle to 1. // Honestly, just lock throttle to 1
    lock steering to heading(90, target_pitch).
    mission["next"]().
  }

  function ascent {
    parameter mission.
    if available_twr < .01 {
      stage.
      wait 1.
    }
    if apoapsis > TARGET_ALTITUDE {
      lock throttle to 0.
      lock steering to prograde.
      wait until alt:radar > body:atm:height.
      mission["next"]().
    }
  }

  function circularize {
    parameter mission.

    local circ_fitness is circular_fitness@:bind(time:seconds + eta:apoapsis).
    // Find good circularization dV
    local dV is list(0).
    set dV to hillclimb["seek"](dV, circ_fitness@, 100).
    set dV to hillclimb["seek"](dV, circ_fitness@, 10).
    set dV to hillclimb["seek"](dV, circ_fitness@, 1).

    // Execute maneuver
    add node(time:seconds + eta:apoapsis, 0, 0, dV[0]). wait 0.1.
    maneuver["exec"]().
    panels on. lock throttle to 0.
    wait 1. stage. wait 1.
    mission["next"]().
  }

  function perform_transfer {
    parameter mission.
    local mnv is transfer["seek"](Mun, 175000).
    add mnv. wait 0.01.
    maneuver["exec"](true).
    mission["next"]().
  }

  function perform_capture {
    parameter mission.
    if body = Mun {
      wait 30. // Sometimes SOI can change back-and-forth
      local capture_fitness is circular_fitness@:bind(time:seconds + eta:periapsis).
      local dV is list(0).
      set dV to hillclimb["seek"](dV, capture_fitness@, 100).
      set dV to hillclimb["seek"](dV, capture_fitness@, 10).
      set dV to hillclimb["seek"](dV, capture_fitness@, 1).

      add node(time:seconds + eta:periapsis, 0, 0, dV[0]). wait 0.1.
      maneuver["exec"](true).
      mission["next"]().
    }
  }

  function enable_antennae {
    parameter mission.
    toggle AG4. // Set for the fairings
    wait 0.5.
    local p is ship:partstitled("Comms DTS-M1")[0].
    local m is p:getmodule("ModuleRTAntenna").
    m:doevent("Activate").
    m:setfield("target", "Kerbin").
    panels on.
    mission["next"]().
  }

  function idle {
    parameter mission.
    lock steering to body("Kerbol"):position - ship:position.
    local p is ship:partstitled("SCAN RADAR Altimetry Sensor")[0].
    local m is p:getmodule("SCANSat").
    m:doevent("start radar scan").

    mission["next"].
  }

  function available_twr {
    local g is body:mu / (ship:altitude + body:radius)^2.
    return ship:maxthrust / g / ship:mass.
  }

  function circular_fitness {
    parameter mT, data.
    local maneuver is node(mT, 0, 0, data[0]).
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
