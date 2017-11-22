// Launch mission
// This mission will take a craft into a circular orbit
// By default, it goes to a 100km equatorial orbit
// Can lauch to a certain heading, altitude, and even
// launch to an initial parking altitude before transferring
// to the final altitude.
{
  output("Loading Orbiter mission", true).

  local orbiter_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "circularize", circularize@
    ),
    "events", lex(
    ),
    "target_heading", 90,
    "target_altitude", 100000,
    "final_altitude", 100000
  ).

  function preflight {
    parameter mission.

    set ship:control:pilotmainthrottle to 0.
    output("Launch parameters: " + orbiter_mission["target_heading"] + ":" + orbiter_mission["target_altitude"] + ":" + orbiter_mission["final_altitude"], true).
    if launcher["launch"](orbiter_mission["target_heading"], orbiter_mission["target_altitude"], orbiter_mission["final_altitude"]) {
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
  }

  function ascent {
    parameter mission.
    if launcher["ascent_complete"]() {
        mission["next"]().
      }
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
  }

  // Since this is meant to be imported, export the mission lexicon
  export(orbiter_mission).
}
