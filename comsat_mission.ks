
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
      from {local ndx is myVer.} until ndx >= CONSTELLATION_SIZE step {set ndx to ndx + 1.} do {
        if (baseName + " " + ndx = currShip:name) {
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
    set dV to hillclimb["seek"](dV, circ_fitness@, 0.2).

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

    // Get a ballpark figure for dV needed to reach apoapsis
    // We are depending on a nearly circular orbit, but we're basing our guess
    // on a point between apoapsis and periapsis to get the midpoint of any
    // eccentricity.
    local apo_fitness is apoapsis_fitness@:bind(time:seconds + MIN(eta:apoapsis, eta:periapsis) + ship:orbit:period/4).
    local dV is list(0).
    set dV to hillclimb["seek"](dV, apo_fitness@, 100).
    set dV to hillclimb["seek"](dV, apo_fitness@, 10).
    set dV to hillclimb["seek"](dV, apo_fitness@, 1).

    // Begin looking on the "far side" of the orbit, so we have room to properly
    // hillclimb regardless of where the solution is. (Assuming a solution is
    // within the current orbit somewhere)
    local mT is list(time:seconds + ship:orbit:period/2).
    if mission["control"] <> ship:name {
      local time_slice = ship:orbit:period/10.
      local time_fitness is cluster_fitness@:bind(mission["control"], dV[0]).
      until time_slice < 1 do {
        set mT to hillclimb["seek"](mT, time_fitness@, time_slice).
        set time_slice to time_slice / 10.
      }
    }

    // Fine tune the dV calculation (hoping it doesn't throw off the cluster timing
    // too badly)
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
    // Point at Kerbol (assuming your solar panels are placed for that orientation)
    // Change this to optimize power generation for your design.
    lock steering to body("Kerbol"):position - ship:position.
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
    // Give ourselves at least 10 seconds to complete hillclimb and orientation
    if data[0] < (time:seconds + 10) {
      return -INFINITY.
    }
    local maneuver is node(data[0], 0, 0, dV).
    local fitness is 0.
    add maneuver. wait 0.01.
    // apoapsis will be on the far side of the orbit
    local intercept is data[0] + (maneuver:orbit:period / 2).
    // Determine where the ships will be
    local shipPosV is (positionat(ship, intercept) - ship:body:position).
    local controlPosV is (positionat(vessel(control), intercept) - ship:body:position).
    // Base the fitness on how close the angle between the ships will match the
    // angle between the constellation points. (90 for 4 sats, 120 for 3 sats, etc.)
    set fitness to -ABS(360/CONSTELLATION_SIZE - (vang(shipPosV, controlPosV) * vcrs(shipPosV, controlPosV):normalized:y)).

    remove_any_nodes().
    return fitness.
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
