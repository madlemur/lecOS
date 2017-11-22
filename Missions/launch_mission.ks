// Launch mission
// This mission will take a craft into a circular orbit
// By default, it goes to a 100km equatorial orbit
// Can lauch to a certain heading, altitude, and even
// launch to an initial parking altitude before transferring
// to the final altitude.
{
  output("Loading launch mission", true).
  local launcher is lex().
  local event_lib is lex().

  local curr_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "enable_antennae", enable_antennae@,
      "circularize", circularize@,
      "transfer", transfer@,
      "final_circ", circularize@,
      "end_launch", end_launch@
    ),
    "events", lex(),
    "mission_data", lex(),
    "dependency", list(
      "launcher.v0.1.0.ks",
      "event_lib.v0.1.0.ks"
    )
  ).

  local launch_mission is {
    set launcher to import("launcher.v0.1.0.ks").
    set event_lib to import("event_lib.v0.1.0.ks").
    parameter TARGET_ALTITUDE is 100000.
    parameter TARGET_INCLINATION is 0.
    parameter FINAL_ALTITUDE is -1.
    parameter LONG_ASCENDING is -1.
    set curr_mission["target_altitude"] to TARGET_ALTITUDE.
    set curr_mission["target_inclination"] to TARGET_INCLINATION.
    set curr_mission["final_altitude"] to FINAL_ALTITUDE.
    set curr_mission["long_ascending"] to LONG_ASCENDING.
    return curr_mission.
  }.

  function preflight {
    parameter mission.
    if ship:status <> "PRELAUNCH" mission["switch_to"]("end_launch").
    set ship:control:pilotmainthrottle to 0.
    output("Launch parameters: " + curr_mission["target_inclination"] + ":" + curr_mission["target_altitude"] + ":" + curr_mission["final_altitude"], true).
    if launcher["launch"](curr_mission["target_altitude"], curr_mission["final_altitude"], curr_mission["target_inclination"], curr_mission["long_ascending"]) {
      launcher["start_countdown"](5).
      mission["next"]().
    } else {
      output("Unable to launch, mission terminated.", true).
      mission["terminate"]().
    }

  }

  function end_launch {
    parameter mission.
    mission["next"]().
  }

  function launch {
    parameter mission.
    if launcher["countdown"]() <= 0 {
      mission["add_event"]("staging", event_lib["staging"]).
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
    if launcher["circularize"]() {
      mission["next"]().
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

  export(launch_mission@).
}
