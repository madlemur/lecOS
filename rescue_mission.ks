
{
  local TARGET_ALTITUDE is 125000.

  global rescue_mission is lex(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@,
      "circularize", circularize@,
      "exec_parking", exec_node@,
      "match_inclination", match_inclination@,
      "exec_inclination", exec_node@,
      "hohmann_transfer", hohmann_transfer@,
      "exec_transfer", exec_node@,
      "match_velocity", match_velocity@,
      "exec_velocity", exec_node@,
      "rendezvous", exec_rendezvous@,
      "idle", idle@
    ),
    "events", lex()
  ).

  function match_inclination {
    parameter mission.
    add navigate["target_incl"](target).
    mission["next"]().
  }

  function hohmann_transfer {
    parameter mission.
    add navigate["hohmann"](0, target).
    mission["next"]().
  }

  function match_velocity {
    parameter mission.
    add navigate["target_vel"](target).
    mission["next"]().
  }

  function exec_rendezvous {
    parameter mission.
    rendezvous["rendezvous"](target).
    mission["next"]().
  }

  function preflight {
    parameter mission.

    set ship:control:pilotmainthrottle to 0.
    lock throttle to 1.
    lock steering to heading(90, 90).
    wait 5.
    mission["next"]().
  }

  function launch {
    parameter mission.

    stage. wait 5.
    lock pct_alt to min(1.0, max(0, alt:radar / (body:atm:height * 0.85))).
    lock target_pitch to -90 * pct_alt^0.5 + 90.
    lock throttle to 1. // Honestly, just lock throttle to 1
    lock steering to heading(90, target_pitch).
    mission["next"]().
  }

  function ascent {
    parameter mission.

    if available_twr < .01 {
      stage.
      wait 1.
    }
    if apoapsis > TARGET_ALTITUDE {

      lock throttle to 0.
      lock steering to prograde.
      wait until alt:radar > body:atm:height.
      mission["next"]().
    }
  }

  function circularize {
    parameter mission.

    add navigate["change_peri"](ship:orbit:apoapsis). wait 0.1.
    mission["next"]().
  }

  function exec_node {
    parameter mission.
    maneuver["exec"]().
    lock throttle to 0.
    wait 1.
    mission["next"]().
  }

  function idle {
    parameter mission.
  }

  function available_twr {
    local g is body:mu / (ship:altitude + body:radius)^2.
    return ship:maxthrust / g / ship:mass.
  }

  function remove_any_nodes {
    until not hasnode {
      remove nextnode. wait 0.01.
    }
  }
}