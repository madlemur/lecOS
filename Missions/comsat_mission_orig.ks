
{
  local TARGET_ALTITUDE is 100000.
  local FINAL_ALTITUDE is 550000.
  local CONSTELLATION_SIZE is 4.

  global comsat_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "enable_antennae", enable_antennae@,
      "transfer", transfer@,
      "circularize", circularize@,
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
    if launcher["launch"](90, TARGET_ALTITUDE, FINAL_ALTITUDE) {
      launcher["start_countdown"](5).
      mission["next"]().
    } else {
      output("Unable to launch, mission terminated.", true).
      mission["terminate"]().
    }
    wait 0.
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
      set mission["circ"] to true.
    }
    wait 0.
  }

  function enable_antennae {
    parameter mission.

    toggle AG4. // Set for the fairings
    wait 1.0.
    panels on.
    mission["next"]().
  }

    function transfer {
      parameter mission.
      if launcher["transfer_complete"]()
        mission["next"]().
      wait 0.
    }


  function idle {
    parameter mission.
    wait 0.
  }

  function available_twr {
    local g is body:mu / (ship:altitude + body:radius)^2.
    return ship:maxthrust / g / ship:mass.
  }

}
