
{
  local TARGET_ALTITUDE is 100000.
  local FINAL_ALTITUDE is 750000.
  local CONSTELLATION_SIZE is 1.

  global long_comsat_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "circularize", circularize@,
      "exec_parking", exec_node@,
      "enable_antennae", enable_antennae@,
      "raise_apoapsis", raise_apoapsis@,
      "exec_raise", exec_node@,
      "circularize_final", circularize@,
      "exec_final", exec_node@,
      "idle", idle@
    ),
    "events", lex()
  ).

  function findNameIndex {
    local baseName is ship:name.
    local myVer is 1.
    list targets in shipList.
    for currShip in shipList {
      print "Looking at " + currShip:name.
      from {local ndx is myVer.} until ndx >= CONSTELLATION_SIZE step {set ndx to ndx + 1.} do {
        print "is it " + baseName + " " + ndx + "?".
        if (baseName + " " + ndx = currShip:name) {
          print "Yes it is!".
          if (ndx >= CONSTELLATION_SIZE) {
            return false.
          }
          set myVer to ndx + 1.
          break.
        }
      }
    }
    return myVer.
  }

  function preflight {
    parameter mission.

    // Set comsat name!
    local myIndex is findNameIndex().
    if(not myIndex) {
      shutdown.
    }
    mission:add("control", ship:name + " " + max((myIndex - 1), 1)).
    set ship:name to ship:name + " " + myIndex.

    set ship:control:pilotmainthrottle to 0.
    lock throttle to 1.
    lock steering to heading(0, 90).
    wait 5.
    mission["next"]().
  }

  function launch {
    parameter mission.

    stage. wait 5.
    lock pct_alt to min(1.0, max(0, alt:radar / (body:atm:height * 0.85))).
    lock target_pitch to -90 * pct_alt^0.5 + 90.
    lock throttle to 1. // Honestly, just lock throttle to 1
    lock steering to heading(0, target_pitch).
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

    local mT is list(time:seconds + ship:orbit:period).
    if mission["control"] <> ship:name {
      local time_fitness is cluster_fitness@:bind(mission["control"], dV[0]).
      set mT to hillclimb["seek"](mT, time_fitness@, 500).
      set mT to hillclimb["seek"](mT, time_fitness@, 100).
      set mT to hillclimb["seek"](mT, time_fitness@, 10).
      set mT to hillclimb["seek"](mT, time_fitness@, 1).
    }

    set apo_fitness to apoapsis_fitness@:bind(mT[0]).
    set dV to hillclimb["seek"](dV, apo_fitness@, 0.1).
    set dV to hillclimb["seek"](dV, apo_fitness@, 0.01).

    add node(mT[0], 0, 0, dV[0]). wait 0.1.
    mission["next"]().
  }

  function exec_node {
    parameter mission.
    maneuver["exec"]().
    lock throttle to 0.
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
    if data[0] < (time:seconds + 10) {
      return -INFINITY.
    }
    local maneuver is node(data[0], 0, 0, dV).
    local fitness is 0.
    add maneuver. wait 0.01.
    local intercept is data[0] + (maneuver:orbit:period / 2).
    local shipPosV is (positionat(ship, intercept) - ship:body:position).
    local controlPosV is (positionat(vessel(control), intercept) - ship:body:position).
    set fitness to -ABS(360/CONSTELLATION_SIZE - (vang(shipPosV, controlPosV) * vcrs(shipPosV, controlPosV):normalized:y)).

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
