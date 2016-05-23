
{
  local TARGET_ALTITUDE is 100000.
  local FINAL_ALTITUDE is 750000.
  local CONSTELLATION_SIZE is 4.

  global comsat_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "circularize", circularize@,
      "enable_antennae", enable_antennae@,
      "raise_apoapsis", raise_apoapsis@,
      "circularize_final", circularize@,
      "idle", idle@
    ),
    "events", lex()
  ).

  function preflight {
    parameter mission.

    // Set comsat name!
    local myVer is 1.
    list targets in shipList.
    for currShip in shipList {
      if currShip:name = "Comsat 1" {
        set myVer to max(myVer, 2).
      } else if currShip:name = "Comsat 2" {
        set myVer to max(myVer, 3).
      } else if currShip:name = "Comsat 3" {
        set myVer to max(myVer, 4).
      } else if currShip:name = "Comsat 4" {
        shutdown.
      }
    }

    set ship:name to "Comsat " + myVer.

    if myVer > 1 {
      mission:add("control", "Comsat " + (myVer - 1)).
    }

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

    toggle AG4. // Set for the fairings
    wait 0.5.
    local p to ship:partstitled("Communotron DTS-M1")[0].
    local m to p:getmodule("ModuleRTAntenna").
    m:doevent("activate").
    m:setfield("target", "mission-control").
    set p to ship:partstitled("Communotron 16")[0].
    set m to p:getmodule("ModuleRTAntenna").
    m:doevent("activate").
    panels on.
    mission["next"]().
  }

  function raise_apoapsis {
    parameter mission.

    local apo_fitness is apoapsis_fitness@:bind(time:seconds + 120).
    local dV is list(0).
    set dV to hillclimb["seek"](dV, apo_fitness@, 100).
    set dV to hillclimb["seek"](dV, apo_fitness@, 10).
    set dV to hillclimb["seek"](dV, apo_fitness@, 1).

    local mT is list(time:seconds + 120).
    if mission["control"] <> ship:name {
      local time_fitness is cluster_fitness@:bind(mission["control"], dV[0]).
      set mT to hillclimb["seek"](mT, time_fitness@, 1000).
      set mT to hillclimb["seek"](mT, time_fitness@, 100).
      set mT to hillclimb["seek"](mT, time_fitness@, 10).
      set mT to hillclimb["seek"](mT, time_fitness@, 1).
    }

    set apo_fitness to apoapsis_fitness@:bind(mT[0]).
    set dV to hillclimb["seek"](dV, apo_fitness@, 0.1).
    set dV to hillclimb["seek"](dV, apo_fitness@, 0.01).

    add node(mT[0], 0, 0, dV[0]). wait 0.1.
    maneuver["exec"]().
    wait 1.
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

  function apoapsis_fitness {
    parameter mT, data.
    local maneuver is node(mT, 0, 0, data[0]).
    local fitness is 0.
    add maneuver. wait 0.01.
    set fitness to -(ABS(FINAL_ALTITUDE - maneuver:orbit:apoapsis)).
    remove_any_nodes().
    return fitness.
  }

  function cluster_fitness {
    parameter control, dV, data.
    local INFINITY is 2^64 - 1.
    if data[0] < (time:seconds + 90) {
      return -INFINITY.
    }
    local maneuver is node(data[0], 0, 0, dV).
    local fitness is 0.
    add maneuver. wait 0.01.
    local intercept is data[0] + (maneuver:orbit:period / 2).
    if(control = ship) {
      set fitness to -(ABS(FINAL_ALTITUDE - maneuver:orbit:apoapsis)).
    } else {
      local shipPosV is (positionat(ship, intercept) - ship:body:position).
      local controlPosV is (positionat(vessel(control), intercept) - ship:body:position).
      set fitness to -ABS(360/CONSTELLATION_SIZE - (vang(shipPosV, controlPosV) * vcrs(shipPosV, controlPosV):normalized:y)).
    }
    remove_any_nodes().
    return fitness.
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
