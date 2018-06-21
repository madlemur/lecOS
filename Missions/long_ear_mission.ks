
{
  local TARGET_ALTITUDE is 100000.
  local FINAL_ALTITUDE is 475000.
  local TARGET_HEADING is 7.

  global long_ear_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", do_ascent@,
      "enable_antennae", enable_antennae@,
//      "circularize", circularize@,
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
    local p to ship:partstitled("Communotron 16")[0].
    local m to p:getmodule("ModuleRTAntenna").
    m:doevent("activate").
    set p to ship:partstitled("Reflectron KR-14")[0].
    set m to p:getmodule("ModuleRTAntenna").
    m:setfield("target", "Duna").
    m:doevent("activate").
    panels on.
    local p is ship:partstitled("SCAN RADAR Altimetry Sensor")[0].
    local m is p:getmodule("SCANSat").
    m:doevent("start radar scan").
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
