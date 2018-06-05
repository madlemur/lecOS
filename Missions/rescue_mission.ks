
{
  local TARGET_ALTITUDE is 95000.
  local TARGET_HEADING is 90.

  output("Loading rendezous mission", true).

  global rescue_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "circularize", circularize@,
      "match_inclination", match_inclination@,
      "exec_inclination", exec_node@,
      "hohmann_transfer", hohmann_transfer@,
      "exec_transfer", exec_node@,
      "match_velocity", match_velocity@,
      "exec_velocity", exec_node@,
      "rendezvous", exec_rendezvous@
    ),
    "events", lex()
  ).

  function preflight {
    parameter mission.
    if hastarget {
      mission:add_data("target", target, true).
      set ship:control:pilotmainthrottle to 0.
      lock throttle to 1.
      lock steering to heading(90, 90).
      launcher["start_countdown"](5).
      mission["next"]().
    }
  }

  function launch {
    parameter mission.
    if launcher["countdown"]() <= 0 {
      if launcher["launch"](TARGET_HEADING, TARGET_ALTITUDE) {
        mission["add_event"]("staging", event_lib["staging"]).
        mission["next"]().
      }
      output("Unable to launch, mission terminated.", true).
      mission["terminate"]().
    }
  }

  function ascent {
    parameter mission.
    if launcher["ascent_complete"]()
      mission["next"]().
  }

  function circularize {
    parameter mission.
    launcher["circularize"]().
    set mission["circularize"] to { if launcher["circularized"]() mission["next"](). }.
  }

  function match_inclination {
    parameter mission.
    add navigate["target_incl"](mission:get_data("target")).
    mission["next"]().
  }

  function exec_node {
    parameter mission.
    maneuver["exec"]().
    mission["next"]().
  }

  function hohmann_transfer {
    parameter mission.
    local hnode is navigate["hohmann"](mission:get_data("target"),0).
    if hnode:eta < 5 {
      output("Waiting half an orbit to find an intersection.", true).
      wait ship:orbit:period / 2.
    } else {
      add hnode.
      mission["next"]().
    }
  }

  function match_velocity {
    parameter mission.
    add navigate["target_vel"](mission:get_data("target")).
    mission["next"]().
  }

  function exec_rendezvous {
    parameter mission.
    rendezvous["rendezvous"](mission:get_data("target")).
    mission["next"]().
  }
}
