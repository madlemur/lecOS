
{
  local TARGET_ALTITUDE is 115000.

  global flying_eye_maintenance_mission is lex(
    "sequence", list(
      "get_close", rendezvous@
    ),
    "events", lex()
  ).

  function match_inclination {
    parameter mission.
    add navigate["target_incl"](target). wait 0.1.
    mission["next"]().
  }

  function hohmann_transfer {
    parameter mission.
    add navigate["hohmann"](0, target). wait 0.1.
    mission["next"]().
  }

  function match_velocity {
    parameter mission.
    add navigate["target_vel"](target). wait 0.1.
    mission["next"]().
  }

  function exec_rendezvous {
    parameter mission.
    rendezvous["rendezvous"](target).
    mission["next"]().
  }

  function preflight {
    parameter mission.
    global missthrottle is 1.
    set target to vessel("Flying Eye").
    set ship:control:pilotmainthrottle to 0.
    lock throttle to missthrottle.
    lock steering to heading(90, 90).
    wait 5.
    mission["next"]().
  }

  function launch {
    parameter mission.

    stage. wait 5.
    //lock pct_alt to min(1.0, max(0, alt:radar / (body:atm:height * 0.85))).
    //lock target_pitch to -90 * pct_alt^0.5 + 90.
    set missthrottle to 1.
    lock steering to heading(90, 87).
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
    if ship:VELOCITY:surface:mag > 75 {
      set mission["throttle"] to MIN(1, available_twr/1.5).
    }
    if not mission:haskey("gravturn") AND 90 - vang(ship:up:vector, ship:srfprograde:forevector) < 87.2 {
      set mission["gravturn"] to true.
      lock steering to heading(90, 90 - vang(ship:up:vector, ship:srfprograde:forevector)).
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
