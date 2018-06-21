
{
  local TARGET_ALTITUDE is 100000.
  local FINAL_ALTITUDE is 1000000.
  local TARGET_HEADING is 90.

  global mun_watcher_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", do_ascent@,
      "enable_antennae", enable_antennae@,
      "circularize", circularize@,
      "transfer", do_transfer@,
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
    launcher["start_countdown"](5).
    mission["next"]().
  }

  function launch {
    parameter mission.
    if launcher["countdown"]() = 0 {
      stage. wait 5.
      mission["add_event"]("staging", event_lib["staging"]).
      launcher["launch"](TARGET_HEADING, TARGET_ALTITUDE, FINAL_ALTITUDE).
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
    if launcher["circularize"]() {
      mission["next"]().
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
    set p to ship:partstitled("Reflectron KR-7")[0].
    set m to p:getmodule("ModuleRTAntenna").
    m:setfield("target", "Kerbin").
    m:doevent("activate").
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
