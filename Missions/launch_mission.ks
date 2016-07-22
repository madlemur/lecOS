// Launch mission
// This mission will take a craft into a circular orbit
// By default, it goes to a 100km equatorial orbit
// Can lauch to a certain heading, altitude, and even
// launch to an initial parking altitude before transferring
// to the final altitude.
{
  output("Loading launch mission", true).

  local curr_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "enable_antennae", enable_antennae@,
      "circularize", circularize@,
      "transfer", transfer@,
      "final_circ", circularize@
    ),
    "events", lex(),
    "dependency", list(
      "launcher.v0.1.0.ks",
      "event_lib.v0.1.0.ks"
    )
  ).

  global launch_mission is {
    parameter TARGET_ALTITUDE is 100000.
    parameter TARGET_HEADING is 90.
    parameter FINAL_ALTITUDE is -1.
    set curr_mission["target_altitude"] to TARGET_ALTITUDE.
    set curr_mission["target_heading"] to TARGET_HEADING.
    set curr_mission["final_altitude"] to FINAL_ALTITUDE.
    return curr_mission.
  }.

  function preflight {
    parameter mission.

    set ship:control:pilotmainthrottle to 0.
    lock throttle to 1.
    lock steering to heading(90, 90).
    launcher["start_countdown"](5).
    mission["next"]().
  }

  function launch {
    parameter mission.
    if launcher["countdown"]() <= 0 {
      output("Launch parameters: " + curr_mission["target_heading"] + ":" + curr_mission["target_altitude"] + ":" + curr_mission["final_altitude"], true).
      if launcher["launch"](curr_mission["target_heading"], curr_mission["target_altitude"], curr_mission["final_altitude"]) {
        mission["add_event"]("staging", event_lib["staging"]).
        mission["next"]().
      } else {
        output("Unable to launch, mission terminated.", true).
        mission["terminate"]().
      }
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
    if launcher["transfer_complete"]()
      mission["next"]().
  }

  function enable_antennae {
    parameter mission.

    mission["next"]().
  }

}
