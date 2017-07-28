{
  global launcher is lex(
    "version", "0.1.0",
    "countdown", countdown@:bind(-1),
    "start_countdown", countdown@,
    "launch", launch@,
    "ascent_complete", ascent_complete@,
    "transfer_complete", transfer_complete@,
    "circularize", circularize@,
    "circularized", circularized@,
    // Data points
    "count", -1,
    "last_count", 0,
    "transferring", false,
    "ascending", false
  ).

  function countdown {
    parameter count.
    if count < 0 {
      local i is launcher["count"] - 1.
      if time:seconds > launcher["last_count"] + 1.0 {
        set launcher["last_count"] to time:seconds.
        if i >= 0
          hudtext( "T minus " + i + "s" , 1, 1, 25, white, true).
        set launcher["count"] to i.
        return i.
      }
      return launcher["count"].
    }
    set launcher["last_count"] to time:seconds.
    set launcher["count"] to count.
    hudtext( "T minus " + count + "s" , 1, 1, 25, white, true).
    return count.
  }

  function launch {
    parameter dest_compass. // not exactly right when not 90.
    parameter first_dest_ap. // first destination apoapsis.
    parameter second_dest_ap is -1. // second destination apoapsis.
    parameter second_dest_long is -1. // second destination longitude.

    if second_dest_ap < 0 { set second_dest_ap to first_dest_ap. }

    if first_dest_ap < (1.05 * body:atm:height) {
      output("Initial destination orbit must be above " + (1.05 * body:atm:height)/1000 + "km!", true).
      lock throttle to 0.
      return false.
    }

    set launcher["launch_params"] to lex (
      "dest_compass", dest_compass,
      "first_dest_ap", first_dest_ap,
      "second_dest_ap", second_dest_ap,
      "second_dest_long", second_dest_long
    ).
    set launcher["ascending"] to false.
    set launcher["transferring"] to false.

    // For all atmo launches with fins it helps to teach it that the fins help
    // torque, which it fails to realize:
    set pitch to 0.
    lock steering to heading(launcher["launch_params"]["dest_compass"], 90 + pitch).
    set tmoid to 1.
    lock throttle to tmoid.

    return true.
  }

  function ascent_complete {
    if ship:apoapsis >= launcher["launch_params"]["first_dest_ap"] * 0.98 {
      lock throttle to max(0, (launcher["launch_params"]["first_dest_ap"] - ship:apoapsis) / 5000).
      if eta:apoapsis < 10 {
        lock throttle to 0.
        return true.
      }
    }
    if launcher["ascending"] {
      set salt to ship:altitude.
      set tta to eta:apoapsis.
      set pitch to -sqrt(0.1705 * salt) + 5.
      set teta to (-1 * pitch) + tgain * (pitch + 90).
      set pitch to max(-90, pitch).
      set tmoid to max(-1/(1+5^(min(teta - tta, 27.5632997166971552428868)))+1, 0.15).
    } else if ship:airspeed > 75 {
      output("Ascending to " + launcher["launch_params"]["first_dest_ap"], true).
      lock twr to available_twr().
      lock tgain to 0.1 - (0.1005 / max(twr, 0.00001)).
      output("Steering locked to gravity turn", true).
      set launcher["ascending"] to true.
    }
    return false.
  }

  function transfer_complete {
    if not launcher["transferring"] {
      lock steering to prograde.
      if (launcher["launch_params"]["second_dest_long"] < 0 or abs(ship:longitude - launcher["launch_params"]["second_dest_long"]) < 1) {
          output("Now starting second destination burn.", true).
          lock throttle to max((launcher["launch_params"]["second_dest_ap"] - ship:apoapsis), 0) / 2000.
          output("Now waiting for apoapsis to reach " + launcher["launch_params"]["second_dest_ap"], true).
          set launcher["transferring"] to true.
      }
    }

    if launcher["transferring"] and ship:apoapsis >= launcher["launch_params"]["second_dest_ap"] {
      lock throttle to 0.
      return eta:apoapsis < 10.
    }

    return false.
  }

  function east_for {
    parameter ves.

    return vcrs(ves:up:vector, ves:north:vector).
  }
  // Return eta:apoapsis but with times behind you
  // rendered as negative numbers in the past:
  function eta_ap_with_neg {
    local ret_val is eta:apoapsis.
    if ret_val > ship:obt:period / 2 {
      set ret_val to ret_val - ship:obt:period.
    }
    return ret_val.
  }

  function compass_of_vel {
    local pointing is ship:velocity:orbit.
    local east is east_for(ship).

    local trig_x is vdot(ship:north:vector, pointing).
    local trig_y is vdot(east, pointing).

    local result is arctan2(trig_y, trig_x).

    if result < 0 {
      return 360 + result.
    } else {
      return result.
    }
  }

  function circularize {
    lock throttle to circ_thrott().
    lock steering to heading(compass_of_vel(), -(eta_ap_with_neg()/3)).
	}

	function circ_thrott {
		if abs(steeringmanager:yawerror) < 2 and
			 abs(steeringmanager:pitcherror) < 2 and
			 abs(steeringmanager:rollerror) < 2 {
				 return 0.02 + (30*ship:obt:eccentricity).
		} else {
			return 0.
		}
	}

	function circularized {
    if (ship:obt:trueanomaly < 90 or ship:obt:trueanomaly > 270) {
      unlock steering.
      unlock throttle.
      return true.
    }
    return false.
  }
  function available_twr {
  	local g is body:mu / (ship:altitude + body:radius)^2.
  	return ship:maxthrust / (body:mu / (ship:altitude + body:radius)^2) / ship:mass.
  }
}
