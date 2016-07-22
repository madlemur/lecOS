
{
  local TARGET_ALTITUDE is 115000.

  global crew_transfer_1_mission is lex(
    "sequence", list(
      "preflight", preflight@,                      // Set up target, etc.
      "launch", launch@,                            // Off the pad!
      "ascent", ascent@,                            // Gravity turn
      "circularize", circularize@,                  // Generate circularization node
      "transfer", xfer@,                            // Generate the transfer node
      "match_vel", match_velocity@,                 // Match target velocity node`
      "rendezvous", exec_rendezvous@,               // Execute rendezvous program
      "idle", idle@
    ),
    "events", lex()
  ).

  function preflight {
    parameter mission.
    global missthrottle is 1.
    set mission["throttle"] to missthrottle.
    set target to vessel("Docking Center 1").
    set ship:control:pilotmainthrottle to 0.
    lock throttle to missthrottle.
    lock steering to heading(90, 90).
    wait 5.
    mission["next"]().
  }

  function launch {
    parameter mission.

    stage. wait 5.
    lock pct_alt to min(1.0, max(0, alt:radar / (body:atm:height * 0.85))).
    lock target_pitch to -90 * pct_alt^0.5 + 90.
    set missthrottle to 1.
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
    if ship:VELOCITY:surface:mag > 75 AND available_twr > 0 {
      set mission["throttle"] to MIN(1, 1.95/available_twr).
    } else if ship:VELOCITY:surface:mag > 975 AND availble_twr > 0 {
      set mission["throttle"] to MIN(1, 1.15/available_twr).
    }
    set missthrottle to mission["throttle"].
  }

  function circularize {
    parameter mission.

    add navigate["change_peri"](ship:orbit:apoapsis). wait 0.1.
    maneuver["exec"]().
    lock throttle to 0.
    wait 1.
    mission["next"]().
  }

  function xfer {
    parameter mission.
    local tnode is transfer["seek"](target, 15000).
    add tnode. wait 0.1.
    maneuver["exec"]().
    lock throttle to 0.
    wait 1.
    mission["next"]().
  }

  function match_velocity {
    parameter mission.
    add navigate["target_vel"](target). wait 0.1.
    maneuver["exec"]().
    lock throttle to 0.
    wait 1.
    mission["next"]().
  }

  function exec_rendezvous {
    parameter mission.
    rendezvous["rendezvous"](target).
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
