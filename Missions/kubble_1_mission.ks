
{
  local TARGET_ALTITUDE is 95000.
  local TARGET_HEADING is 35.

  global kubble_1_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", do_ascent@,
      "enable_antennae", enable_antennae@,
//      "circularize", circularize@,
//      "transfer", do_transfer@,
      "final_circ", circularize@,
      "complete", complete@
    ),
    "events", lex()
  ).

  function preflight {
    parameter mission.

    set ship:control:pilotmainthrottle to 0.
    lock throttle to 1.
    lock steering to heading(90, 90).
    launcher["start_countdown"](1).
    mission["next"]().
  }

  function launch {
    parameter mission.
    if launcher["countdown"]() = 0 {
      stage. wait 5.
      mission["add_event"]("staging", event_lib["staging"]).
      launcher["launch"](TARGET_HEADING, TARGET_ALTITUDE).
      mission["next"]().
    }
  }

  function do_ascent {
    parameter mission.
    if launcher["ascent_complete"]()
      mission["next"]().
  }

  function circularize {
    parameter mission.

    if mission["has_data"]("circularizing") {
      if navigate["circularized"]() {
        mission["remove_data"]("circularizing").
        mission["next"]().
      }
    } else {
      navigate["circularize"]().
      mission["add_data"]("circularizing", true).
    }

  }

  function do_transfer {
    parameter mission.
    if launcher["transfer_complete"]()
      mission["next"]().
  }

  function enable_antennae {
    parameter mission.

    toggle AG4. // Set for the fairings
    wait 1.0.
    panels on.
    mission["next"]().
  }

  function complete {
    parameter mission.
    mission["remove_event"]("staging").
    unlock throttle.
    unlock steering.
    shutdown.
  }

}
