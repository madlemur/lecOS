{

  local curr_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "circularize", circularize@,
      "transfer", transfer@,
      "final_circ", circularize@,
      "orbit", orbit@,
      "descend", descend@,
      "land", land@
    ),
    "events", lex()
  ).

  global prober_mission is {
    parameter TARGET_ALTITUDE is 100000.
    parameter TARGET_HEADING is 90.
    parameter FINAL_ALTITUDE is 250000.
    set curr_mission["target_altitude"] to TARGET_ALTITUDE.
    set curr_mission["target_heading"] to TARGET_HEADING.
    set curr_mission["final_altitude"] to FINAL_ALTITUDE.
    return curr_mission.
  }.

  function orbit {
    parameter mission.
    wait ship:orbit:period.
    mission["next"]().
  }

  function descend {
    parameter mission.
    lock steering to srfretrograde.
    wait 20.
    lock throttle to .5.
    until periapsis < 5000 {
      wait 0.01.
    }
    lock throttle to 0.
    mission["next"]().
  }

  function land {
    parameter mission.
    mission["next"]().
  }

  function preflight {
    parameter mission.

    set ship:control:pilotmainthrottle to 0.
    output("Launch parameters: " + curr_mission["target_heading"] + ":" + curr_mission["target_altitude"] + ":" + curr_mission["final_altitude"], true).
    if launcher["launch"](curr_mission["target_heading"], curr_mission["target_altitude"], curr_mission["final_altitude"]) {
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
      mission["add_event"]("antenna", enable_antennae@).
      mission["next"]().
    }
  }

  function ascent {
    parameter mission.
    if launcher["ascent_complete"]() {
        mission["next"]().
    }
  }

  function circularize {
    parameter mission.
    if curr_mission:haskey("circ") {
      if launcher["circularized"]() {
        curr_mission:remove("circ").
        mission["next"]().
      }
    } else {
      launcher["circularize"]().
      set curr_mission["circ"] to true.
    }
  }

  function transfer {
    parameter mission.
    if launcher["transfer_complete"]() {
      mission["next"]().
    }
  }

  function enable_antennae {
    parameter mission.
    if altitude > body:atm:height {
      local p to ship:partstitled("Kommunotronski 16")[0].
      local m to p:getmodule("ModuleRTAntenna").
      m:doevent("activate").
      AG4 ON.
      wait 2.
      panels on.
      rcs on.
      mission["remove_event"]("antenna").
    }
  }
}
