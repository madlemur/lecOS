
{
  output("Loading rendezvous mission", true).

  local curr_mission is lex(
    "sequence", list(
      "rdv_preflight", preflight@,
      "match_inclination", match_inclination@,
      "exec_inclination", exec_node@,
      "hohmann_transfer", hohmann_transfer@,
      "exec_transfer", exec_node@,
      "match_velocity", match_velocity@,
      "exec_velocity", exec_node@,
      "rendezvous", exec_rendezvous@
    ),
    "events", lex(),
    "dependency", list (
      "navigate.v0.2.0.ks",
      "maneuver.v0.2.0.ks",
      "rendezvous.v0.1.0.ks"
    )
  ).

  global rendezvous_mission is {
    return curr_mission.
  }.

  function preflight {
    parameter mission.
    if hastarget {
      mission:add_data("target", target, true).
      mission["next"]().
    } else {
      hudtext( "Please select a target for rendezvous" , 1, 2, 25, yellow, true).
      wait 1.
    }
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
