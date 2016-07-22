
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
    mission:add("SRBs", stage:solidfuel > 1).
    set ship:name to ship:name + " " + myIndex.

    set ship:control:pilotmainthrottle to 0.
    lock throttle to 1.
    lock steering to heading(90, 90).
    wait 5.
    mission["next"]().
  }

  function launch {
    parameter mission.

    stage.
    set mission["SRBs"] TO stage:solidfuel > 1.
    wait 5.
    lock pct_alt to min(1.0, max(0, alt:radar / (body:atm:height * 0.85))).
    lock target_pitch to -90 * pct_alt^0.75 + 90.
    lock throttle to 1. // Honestly, just lock throttle to 1
    lock steering to heading(90, target_pitch).
    mission["next"]().
  }

  function ascent {
    parameter mission.

    if available_twr < .01 or (mission["SRBs"] and stage:solidfuel < 0.1) {
      stage.
      set mission["SRBs"] TO stage:solidfuel > 1.
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
    if(eta:apoapsis < 10) {
      navigate["circularize"]().
      mission["next"]().
    }
  }

  function enable_antennae {
    parameter mission.

    toggle AG4. // Set for the fairings
    wait 0.5.
    //local p to ship:partstitled("Communotron DTS-M1")[0].
    //local m to p:getmodule("ModuleRTAntenna").
    //m:doevent("activate").
    //m:setfield("target", "mission-control").
    set p to ship:partstitled("Communotron 16")[0].
    set m to p:getmodule("ModuleRTAntenna").
    m:doevent("activate").
    panels on.
    mission["next"]().
  }

  function raise_apoapsis {
    parameter mission.

    if mission:haskey("control") AND mission["control"] <> ship:name {
      local nd is navigate["hohmann"](360/CONSTELLATION_SIZE, vessel(mission["control"])).
      until nd:eta > 0 {
        print "Waiting for a transfer window.".
        warpto(time:seconds + navigate["synodic_period"]()).
        set nd to navigate["hohmann"](360/CONSTELLATION_SIZE, vessel(mission["control"])).
      }
      add nd.
    } else {
      add navigate["change_apo"](FINAL_ALTITUDE).
    }
    wait 0.1.
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
  }

  function available_twr {
    local g is body:mu / (ship:altitude + body:radius)^2.
    return ship:maxthrust / g / ship:mass.
  }

  function remove_any_nodes {
    until not hasnode {
      remove nextnode. wait 0.01.
    }
  }
}
