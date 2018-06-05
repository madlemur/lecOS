
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
      "approach", approach@,
      "close", close@
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
      local approachQ is queue().
      approachQ:push(100).
      approachQ:push(5).
      approachQ:push(0).
      local closeQ is queue().
      closeQ:push(2000).
      closeQ:push(50).
      mission["add_data"]("approachQ", approachQ, true).
      mission["add_data"]("closeQ", closeQ, true).
      mission["next"]().
    } else {
      hudtext( "Please select a target for rendezvous" , 1, 2, 25, yellow, true).
      wait 1.
    }
  }

  function match_inclination {
    parameter mission.
    add navigate["target_incl"](target).
    mission["next"]().
  }

  function exec_node {
    parameter mission.
    maneuver["exec"]().
    mission["next"]().
  }

  function hohmann_transfer {
    parameter mission.
    local hnode is navigate["hohmann"](target,0).
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
    add navigate["target_vel"](target).
    mission["next"]().
  }

  function approach {
    parameter mission.
    local approachQ is mission["get_data"]("approachQ").
    if approachQ:empty mission["next"]().
    local approachVel is approachQ:peek().
    if rendezvous["approach"](target, approachVel) {
      approachQ:pop().
      mission["switch_to"]("close").
    }
  }

  function close {
    parameter mission.
    local closeQ is mission["get_data"]("closeQ").
    if closeQ:empty mission["next"]().
    local closeDist is closeQ:peek().
    if rendezvous["await_nearest"](target, closeDist) {
      closeQ:pop().
      mission["switch_to"]("approach").
    }
  }

}
