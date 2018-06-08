{
  local launcher is lex(
    "countdown", countdown@:bind(-1),
    "start_countdown", countdown@,
    "launch", launch@,
    "ascent_complete", ascent_complete@,
    "circularize", circularize@,
    "circularized", circularized@,
    "calcLaunchDetails", calcLaunchDetails@
  ).

  local HALF_LAUNCH is 145.
  local steer is import("steering.ks").
  LOCAL LAUNCH_VEC is UP:VECTOR.

  function countdown {
    parameter count, m.
    local ttl is FLOOR(__["diffTime"]("launch")).
    if count < 0 {
      local i is m["get_data"]("count") + count.
      if __["diffTime"]("launch") < i {
        if ttl >= 0 { __["hudMsg"]( "T minus " + ttl + "s" , 1, 1, 25, white, true). }
        m["add_data"]("count", ttl).
        return ttl.
      }
      return i - count.
    } else {
        m["add_data"]("count", min(count, ttl)).
        if ttl <= count { __["hudMsg"]( "T minus " + count + "s" , 1, 1, 25, white, true). }
        return count.
    }
  }

  function launch {
    parameter ap, az, m.

    // Set up launch parameters
    if ap < (1.05 * body:atm:height) {
      __["pOut"]("Destination orbit must be above " + (1.05 * body:atm:height) + "m!", true).
      lock throttle to 0.
      return false.
    }

    m["add_data"]("ascending", false, true).
    m["add_data"]("transferring", false, true).

    steer["steerTo"]({ RETURN LAUNCH_VEC }).
    lock throttle to 1.

    __["pOut"]("Ascending to " + ap, true).

    return true.
  }

  function ascent_complete {
    parameter m.
    local target_apo is m["get_data"]("target_altitude").
    local inc is m["get_data"]("target_inclination"). // orbit inclination

    if ship:apoapsis > target_apo {
      lock throttle to (target_apo - ship:apoapsis) / 2000.
    }
    if m["get_data"]("ascending") {
        if latIncOk(ship:latitude, inc) {
            set az_corr to launchBearing(inc, target_apo).
        } ELSE {
            if inc < 90 { set az_corr to 90. }
            else { set az_corr to 270. }
        }
        // update our steering
        local pAlt is m["get_data"]("pitch_alt").
        local cAlt is m["get_data"]("curve_alt").
        set LAUNCH_VEC to heading(az_corr, launchPitch(pAlt,cAlt)).
    } else if ship:airspeed > 75 {
      __["pOut"]("Steering locked to gravity turn", true).
      m["add_data"]("ascending", true, true).
    }
    if ship:apoapsis > target_apo * 0.95 and altitude > ship:apoapsis * 0.90 {
      return true.
    }
    return false.
  }

  function ef {
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

  function cov {
    local vo is ship:velocity:orbit.
    local east is ef(ship).

    local trig_x is vdot(ship:north:vector, vo).
    local trig_y is vdot(east, vo).

    local result is arctan2(trig_y, trig_x).

    return __["mAngle"](result).
  }

  function circularize {
    lock throttle to circ_thrott().
    lock steering to heading(cov(), -(eta_ap_with_neg()/3)).
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
    PARAMETER i, lat is ship:latitude.
    IF latIncOk(lat,i) { RETURN __["mAngle"](ARCSIN(COS(i) / COS(lat))). }
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

  FUNCTION launchPitch
  {
      PARAMETER pAtl, cAlt.
      IF ALT:RADAR < pAlt { RETURN 90. }
      RETURN MIN(90,MAX(0, MAX(90 * (1 - SQRT(ALTITUDE/cAlt)),45-VERTICALSPEED))).
  }

  FUNCTION launchBearing
  {
      PARAMETER inc, ap.
      LOCAL lat IS SHIP:LATITUDE.
      LOCAL vo IS SHIP:VELOCITY:ORBIT.
      LOCAL lvo IS sqrt( constant():G * body:mass / ( ap + body:radius)).
      IF (inc > 0 AND ABS(lat) < 90 AND MIN(inc,180 - inc) >= ABS(lat)) {
        LOCAL az IS ARCSIN( COS(inc) / COS(lat) ).
        IF NOT (az < 90 OR az > 270 OR ((az = 90 OR az = 270) AND LATITUDE < 0)) { SET az TO mAngle(180 - az). }
        IF vo:MAG >= lvo { RETURN az. }
        LOCAL x IS (lvo * SIN(az)) - VDOT(vo,HEADING(90,0):VECTOR).
        LOCAL y IS (lvo * COS(az)) - VDOT(vo,HEADING(0,0):VECTOR).
        RETURN mAngle(90 - ARCTAN2(y, x)).
      } ELSE {
        IF inc < 90 { RETURN 90. }
        ELSE { RETURN 270. }
      }
  }

  FUNCTION launchAzimuth
  {
    PARAMETER az, ap.

    LOCAL v_orbit IS SQRT(BODY:MU/(BODY:RADIUS + ap)).
    LOCAL v_rot to SHIP:GEOPOSITION:ALTITUDEVELOCITY(ALTITUDE):ORBIT:MAG.
    LOCAL v_orbit_x IS v_orbit * SIN(az).
    LOCAL v_orbit_y IS v_orbit * COS(az).
    LOCAL raz IS __["mAngle"](90 - ARCTAN2(v_orbit_y, v_orbit_x - v_rot)).
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
    SET az TO launchAzimuth(az,ap).
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
    IF launch_time - TIME:SECONDS > 50 {
      __["pOut"]("Waiting for orbit plane to pass overhead.").
      WAIT 5.
      __["doWarp"](launch_time).
    }
  }
  export(launcher).
}
