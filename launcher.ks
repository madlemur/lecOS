{
  local launcher is lex(
    "version", "0.1.0",
    "countdown", countdown@:bind(-1),
    "start_countdown", countdown@,
    "launch", launch@,
    "ascent_complete", ascent_complete@,
    "transfer_complete", transfer_complete@,
    "circularize", circularize@,
    "circularized", circularized@
  ).

  local HALF_LAUNCH is 145.

  function countdown {
    parameter count, data.
    if count < 0 {
      local i is data["count"] - 1.
      if time:seconds > data["last_count"] + 1.0 {
        set data["last_count"] to time:seconds.
        if i >= 0
          __["hudMsg"]( "T minus " + i + "s" , 1, 1, 25, white, true).
        set data["count"] to i.
        return i.
      }
      return data["count"].
    }
    set data["last_count"] to time:seconds.
    set data["count"] to count.
    __["hudMsg"]( "T minus " + count + "s" , 1, 1, 25, white, true).
    return count.
  }

  function launch {
    parameter data.
    parameter dest_compass. // not exactly right when not 90.
    parameter first_dest_ap. // first destination apoapsis.
    parameter second_dest_ap is -1. // second destination apoapsis.
    parameter second_dest_long is -1. // second destination longitude.

    if second_dest_ap < 0 { set second_dest_ap to first_dest_ap. }

    if first_dest_ap < (1.05 * body:atm:height) {
      __["pOut"]("Initial destination orbit must be above " + (1.05 * body:atm:height) + "m!", true).
      lock throttle to 0.
      return false.
    }

    set data["launch_params"] to lex (
      "dest_compass", dest_compass,
      "first_dest_ap", first_dest_ap,
      "second_dest_ap", second_dest_ap,
      "second_dest_long", second_dest_long
    ).
    set data["ascending"] to false.
    set data["transferring"] to false.

    // For all atmo launches with fins it helps to teach it that the fins help
    // torque, which it fails to realize:
    lock steering to heading(data["launch_params"]["dest_compass"], 90).
    lock throttle to 1.

    return true.
  }

  function ascent_complete {
    parameter data.
    if ship:apoapsis > data["launch_params"]["first_dest_ap"] {
      lock throttle to (data["launch_params"]["first_dest_ap"] - ship:apoapsis) / 2000.
    }
    if data["ascending"] {
      if ship:altitude > body:atm:height {
        lock throttle to 0.
        lock steering to prograde.
      }
    } else if ship:airspeed > 75 {
      __["pOut"]("Ascending to " + data["launch_params"]["first_dest_ap"], true).
      lock steering to heading(data["launch_params"]["dest_compass"], 90 - 90*(altitude/body:atm:height * 0.85)^(0.75)).
      __["pOut"]("Steering locked to gravity turn", true).
      set data["ascending"] to true.
    }
    if ship:apoapsis > data["launch_params"]["first_dest_ap"] * 0.95 and altitude > ship:apoapsis * 0.90 {
      return true.
    }
    return false.
  }

  function transfer_complete {
    parameter data.
    if not data["transferring"] {
      lock steering to prograde.
      if (data["launch_params"]["second_dest_long"] < 0 or abs(ship:longitude - data["launch_params"]["second_dest_long"]) < 1) and
        abs(steeringmanager:yawerror) < 2 and
        abs(steeringmanager:pitcherror) < 2 and
        abs(steeringmanager:rollerror) < 2 {
          __["pOut"]("Now starting second destination burn.", true).
          lock throttle to 0.01 + (data["launch_params"]["second_dest_ap"] - ship:apoapsis) / 5000.
          __["pOut"]("Now waiting for apoapsis to reach " + data["launch_params"]["second_dest_ap"], true).
          set data["transferring"] to true.
      }
    }

    if data["transferring"] and ship:apoapsis >= data["launch_params"]["second_dest_ap"] {
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

    return __["mAngle"](result).
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

  FUNCTION changeHALF_LAUNCH
  {
    PARAMETER h.
    IF h > 0 { SET HALF_LAUNCH TO h. }
  }

  FUNCTION latIncOk
  {
    PARAMETER lat,i.
    RETURN (i > 0 AND ABS(lat) < 90 AND MIN(i,180-i) >= ABS(lat)).
  }

  FUNCTION etaToOrbitPlane
  {
    PARAMETER is_AN, planet, orb_lan, i, ship_lat, ship_lng.

    LOCAL eta IS -1.
    IF latIncOk(ship_lat,i) {
      LOCAL rel_lng IS ARCSIN(TAN(ship_lat)/TAN(i)).
      IF NOT is_AN { SET rel_lng TO 180 - rel_lng. }
      LOCAL g_lan IS __["mAngle"](orb_lan + rel_lng - planet:ROTATIONANGLE).
      LOCAL node_angle IS __["mAngle"](g_lan - ship_lng).
      SET eta TO (node_angle / 360) * planet:ROTATIONPERIOD.
    }
    RETURN eta.
  }

  FUNCTION azimuth
  {
    PARAMETER i.
    IF latIncOk(LATITUDE,i) { RETURN __["mAngle"](ARCSIN(COS(i) / COS(LATITUDE))). }
    RETURN -1.
  }

  FUNCTION planetSurfaceSpeedAtLat
  {
    PARAMETER planet, lat.

    LOCAL v_rot IS 0.
    LOCAL circum IS 2 * CONSTANT:PI * planet:RADIUS.
    LOCAL period IS planet:ROTATIONPERIOD.
    IF period > 0 { SET v_rot TO COS(lat) * circum / period. }
    RETURN v_rot.
  }

  FUNCTION launchAzimuth
  {
    PARAMETER planet, az, ap.

    LOCAL v_orbit IS SQRT(planet:MU/(planet:RADIUS + ap)).
    LOCAL v_rot IS planetSurfaceSpeedAtLat(planet,LATITUDE).
    LOCAL v_orbit_x IS v_orbit * SIN(az).
    LOCAL v_orbit_y IS v_orbit * COS(az).
    LOCAL raz IS mAngle(90 - ARCTAN2(v_orbit_y, v_orbit_x - v_rot)).
    __["pOut"]("Input azimuth: " + ROUND(az,2)).
    __["pOut"]("Output azimuth: " + ROUND(raz,2)).
    RETURN raz.
  }

  FUNCTION noPassLaunchDetails
  {
    PARAMETER ap,i,lan.

    LOCAL az IS 90.
    LOCAL lat IS MIN(i, 180-i).
    IF i > 90 { SET az TO 270. }

    IF i = 0 OR i = 180 { RETURN LIST(az,0). }

    LOCAL eta IS 0.
    IF LATITUDE > 0 { SET eta TO etaToOrbitPlane(TRUE,BODY,lan,i,lat,LONGITUDE). }
    ELSE { SET eta TO etaToOrbitPlane(FALSE,BODY,lan,i,-lat,LONGITUDE). }
    LOCAL launch_time IS TIME:SECONDS + eta - HALF_LAUNCH.
    RETURN LIST(az,launch_time).
  }

  FUNCTION launchDetails
  {
    PARAMETER ap,i,lan,az.

    LOCAL eta IS 0.
    SET az TO launchAzimuth(BODY,az,ap).
    LOCAL eta_to_AN IS etaToOrbitPlane(TRUE,BODY,lan,i,LATITUDE,LONGITUDE).
    LOCAL eta_to_DN IS etaToOrbitPlane(FALSE,BODY,lan,i,LATITUDE,LONGITUDE).

    IF eta_to_DN < 0 AND eta_to_AN < 0 { RETURN noPassLaunchDetails(ap,i,lan). }
    ELSE IF (eta_to_DN < eta_to_AN OR eta_to_AN < HALF_LAUNCH) AND eta_to_DN >= HALF_LAUNCH {
      SET eta TO eta_to_DN.
      SET az TO __["mAngle"](180 - az).
    } ELSE IF eta_to_AN >= HALF_LAUNCH { SET eta TO eta_to_AN. }
    ELSE { SET eta TO eta_to_AN + BODY:ROTATIONPERIOD. }
    LOCAL launch_time IS TIME:SECONDS + eta - HALF_LAUNCH.
    RETURN LIST(az,launch_time).
  }

  FUNCTION calcLaunchDetails
  {
    PARAMETER ap,i,lan.

    LOCAL az IS azimuth(i).
    IF az < 0 { RETURN noPassLaunchDetails(ap,i,lan). }
    ELSE { RETURN launchDetails(ap,i,lan,az). }
  }

  FUNCTION warpToLaunch
  {
    PARAMETER launch_time.
    IF launch_time - TIME:SECONDS > 5 {
      __["pOut"]("Waiting for orbit plane to pass overhead.").
      WAIT 5.
      __["doWarp"](launch_time).
    }
  }
  export(launcher).
}
