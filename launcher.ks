@LAZYGLOBAL OFF.
__["pOut"]("LEC LAUNCHER v%VERSION_NUMBER%").
{
  local launcher is lex(
    "countdown", cdn@:bind(-1),
    "start_countdown", cdn@,
    "launch_init", l_i@,
    "launch", launch@,
    "ascent_complete", ascent_complete@,
    "circularize", cz@,
    "circularized", czd@,
    "calcLaunchDetails", calcld@
  ).

  local H_L is 145.
  LOCAL L_V is UP:VECTOR.

  local steer is import("steering.ks").

  function cdn
  {
    parameter c.
    local ttl is FLOOR(__["diffTime"]("launch")).
    if c < 0 {
      local i is launcher["count"] + c.
      if -ttl < i {
        if ttl <= 0 { __["hudMsg"]( "T " + ttl + "s" , 1, 1, 25, white, true). }
        SET launcher["count"] to -ttl.
      }
      return launcher["count"].
    } else {
        SET launcher["count"] to min(c, -ttl).
        if -ttl >= c { __["hudMsg"]( "T " + c + "s" , 1, 1, 25, white, true). }
        return c.
    }
  }

  function l_i
  {
    parameter ap, az, inc, p_a, c_a.
    SET launcher["target_altitude"] to ap.
    SET launcher["target_inclination"] to inc.
    SET launcher["pitch_alt"] to p_a.
    SET launcher["curve_alt"] to c_a.
    SET launcher["launch_an"] to (az < 90 OR az > 270 OR ((az = 90 OR az = 270) AND LATITUDE < 0)).
  }

  function launch
  {
    parameter ap, az.

    // Set up launch parameters
    if ap < (1.05 * body:atm:height) {
      __["pOut"]("Destination orbit must be above " + (1.05 * body:atm:height) + "m!", true).
      lock throttle to 0.
      return false.
    }

    SET launcher["ascending"] to false.
    SET launcher["transferring"] to false.

    steer["steerTo"]({ RETURN L_V. }).
    lock throttle to 1.

    __["pOut"]("Ascending to " + ap, true).

    return true.
  }

  function ascent_complete
  {
    local target_apo is launcher["target_altitude"].
    local inc is launcher["target_inclination"]. // orbit inclination
    local az_corr is 90.

    if ship:apoapsis > target_apo {
      lock throttle to (target_apo - ship:apoapsis) / 2000.
    }
    if launcher["ascending"] {
        if latIncOk(ship:latitude, inc) {
            set az_corr to launchBearing(inc, target_apo).
        } ELSE {
            if inc < 90 { set az_corr to 90. }
            else { set az_corr to 270. }
        }
        // update our steering
        local pAlt is launcher["pitch_alt"].
        local cAlt is launcher["curve_alt"].
        __["hudMsg"]("AZ " + az_corr + " for INC "  + inc).
        set L_V to heading(az_corr, launchPitch(pAlt,cAlt)):FOREVECTOR.
    } else if ship:airspeed > 75 {
      __["pOut"]("Steering locked to gravity turn", true).
      SET launcher["ascending"] to true.
    }
    if ship:apoapsis > target_apo * 0.95 and altitude > ship:apoapsis * 0.90 {
      return true.
    }
    return false.
  }

  function ef
  {
    parameter ves.

    return vcrs(ves:up:vector, ves:north:vector).
  }
  // Return eta:apoapsis but with times behind you
  // rendered as negative numbers in the past:
  function eta_ap_with_neg
  {
    local ret_val is eta:apoapsis.
    if ret_val > ship:obt:period / 2 {
      set ret_val to ret_val - ship:obt:period.
    }
    return ret_val.
  }

  function cov
  {
    local vo is ship:velocity:orbit.
    local east is ef(ship).

    local trig_x is vdot(ship:north:vector, vo).
    local trig_y is vdot(east, vo).

    local result is arctan2(trig_y, trig_x).

    return __["mAngle"](result).
  }

  function cz
  {
    lock throttle to circ_thrott().
    lock steering to heading(cov(), -(eta_ap_with_neg()/3)).
  }

  function circ_thrott
  {
  	if abs(steeringmanager:yawerror) < 2 and
  		 abs(steeringmanager:pitcherror) < 2 and
  		 abs(steeringmanager:rollerror) < 2 {
  			 return 0.02 + (30*ship:obt:eccentricity).
  	} else {
  		return 0.
  	}
  }

  function czd
  {
    if (ship:obt:trueanomaly < 90 or ship:obt:trueanomaly > 270) {
      unlock steering.
      unlock throttle.
      return true.
    }
    return false.
  }

  FUNCTION changeH_L
  {
    PARAMETER h.
    IF h > 0 { SET H_L TO h. }
  }

  FUNCTION latIncOk
  {
    PARAMETER lat,i.
    RETURN (i > 0 AND ABS(lat) < 90 AND MIN(i,180-i) >= ABS(lat)).
  }

  FUNCTION etaop
  {
    PARAMETER is_AN, planet, orb_lan, i, ship_lat, ship_lng.

    LOCAL etan IS -1.
    IF latIncOk(ship_lat,i) {
      LOCAL rel_lng IS ARCSIN(TAN(ship_lat)/TAN(i)).
      IF NOT is_AN { SET rel_lng TO 180 - rel_lng. }
      LOCAL g_lan IS __["mAngle"](orb_lan + rel_lng - planet:ROTATIONANGLE).
      LOCAL node_angle IS __["mAngle"](g_lan - ship_lng).
      SET etan TO (node_angle / 360) * planet:ROTATIONPERIOD.
    }
    RETURN etan.
  }

  FUNCTION azm
  {
    PARAMETER i, lat is ship:latitude.
    RETURN __["mAngle"](ARCSIN(COS(i) / COS(lat))).
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
      PARAMETER pAlt, cAlt.
      IF ALT:RADAR < pAlt { RETURN 90. }
      RETURN MIN(90,MAX(0, MAX(90 * (1 - SQRT(ALTITUDE/cAlt)),45-VERTICALSPEED))).
  }

  FUNCTION launchBearing
  {
      PARAMETER inc, ap.
      LOCAL lat IS SHIP:LATITUDE.
      LOCAL vo IS SHIP:VELOCITY:ORBIT.
      LOCAL lvo IS sqrt( body:MU / ( ap + body:radius)).
      IF latIncOk(lat,inc) {
        LOCAL az IS azm(inc).
        IF NOT launcher["launch_an"] { SET az TO __["mAngle"](180 - az). }
        IF vo:MAG >= lvo { RETURN az. }
        LOCAL x IS (lvo * SIN(az)) - VDOT(vo,HEADING(90,0):VECTOR).
        LOCAL y IS (lvo * COS(az)) - VDOT(vo,HEADING(0,0):VECTOR).
        RETURN __["mAngle"](90 - ARCTAN2(y, x)).
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

  FUNCTION npld
  {
    PARAMETER ap,i,lan.

    LOCAL az IS 90.
    LOCAL lat IS MIN(i, 180-i).
    IF i > 90 { SET az TO 270. }

    IF i = 0 OR i = 180 { RETURN LIST(az,0). }

    LOCAL eta IS 0.
    IF LATITUDE > 0 { SET eta TO etaop(TRUE,BODY,lan,i,lat,LONGITUDE). }
    ELSE { SET eta TO etaop(FALSE,BODY,lan,i,-lat,LONGITUDE). }
    LOCAL launch_time IS TIME:SECONDS + eta - H_L.
    RETURN LIST(az,launch_time).
  }

  FUNCTION ld
  {
    PARAMETER ap,i,lan,az.

    LOCAL etap IS 0.
    LOCAL laz IS launchAzimuth(az,ap).
    LOCAL eta_to_AN IS etaop(TRUE,BODY,lan,i,LATITUDE,LONGITUDE).
    LOCAL eta_to_DN IS etaop(FALSE,BODY,lan,i,LATITUDE,LONGITUDE).

    IF eta_to_DN < 0 AND eta_to_AN < 0 {
      RETURN npld(ap,i,lan).
    } ELSE IF (eta_to_DN < eta_to_AN OR eta_to_AN < H_L) AND eta_to_DN >= H_L {
      SET etap TO eta_to_DN.
      SET laz TO __["mAngle"](180 - laz).
    } ELSE IF eta_to_AN >= H_L {
      SET etap TO eta_to_AN.
    } ELSE {
      SET etap TO eta_to_AN + BODY:ROTATIONPERIOD.
    }
    LOCAL launch_time IS TIME:SECONDS + etap - H_L.
    RETURN LIST(laz,launch_time).
  }

  FUNCTION calcld
  {
    PARAMETER ap,i,lan.

    LOCAL az IS -1.
    if latIncOk(ship:latitude, i) { set az to azm(i). }
    IF az < 0 { RETURN npld(ap,i,lan). }
    ELSE { RETURN ld(ap,i,lan,az). }
  }

  export(launcher).
}
