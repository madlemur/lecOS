
{
  local TARGET_ALTITUDE is 100000.
  local FINAL_ALTITUDE is 550000.
  local CONSTELLATION_SIZE is 4.

  global comsat_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "circularize", circularize@,
      "enable_antennae", enable_antennae@,
      "raise_apoapsis", raise_apoapsis@,
      "exec_raise", exec_node@,
      "coast_to_apo", coast_to_apo@,
      "circularize_final", circularize@,
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
    if mission["control"] <> ship:name {
      set FINAL_ALTITUDE to vessel(mission["control"]):altitude.
    }
    set ship:control:pilotmainthrottle to 0.
    if launcher["launch"](90, TARGET_ALTITUDE, FINAL_ALTITUDE) {
      launcher["start_countdown"](5).
      mission["next"]().
    } else {
      output("Unable to launch, mission terminated.", true).
      mission["terminate"]().
    }
  }

  function launch {
    parameter mission.
    if launcher["countdown"]() <= 0 {
      mission["add_event"]("staging", event_lib["staging"]).
      mission["next"]().
    }
    wait 0.
  }

  function ascent {
    parameter mission.

    if launcher["ascent_complete"]() {
      mission["next"]().
    }
    wait 0.
  }

  function circularize {
    parameter mission.
    if mission:haskey("circ") {
      if launcher["circularized"]() {
        mission:remove("circ").
        mission["next"]().
      }
    } else {
      launcher["circularize"]().
      RCS ON.
      steeringmanager:resetpids().
      set mission["circ"] to true.
    }
    wait 0.
  }

  function enable_antennae {
    parameter mission.

    toggle AG4. // Set for the fairings
    wait 2.
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
    maneuver["exec"](true).
    lock throttle to 0.
    wait 1.
    mission["next"]().
  }

  function coast_to_apo {
    parameter mission.
    lock steering to prograde.
    if(eta:apoapsis < 10) {
      mission["next"]().
    }
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
    add maneuver. wait 0.
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
    add maneuver. wait 0.
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
    add maneuver. wait 0.
    set fitness to -maneuver:orbit:eccentricity.
    remove_any_nodes().
    return fitness.
  }

  function remove_any_nodes {
    until not hasnode {
      remove nextnode. wait 0.
    }
  }
}
