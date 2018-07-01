@LAZYGLOBAL OFF.
pout("LEC LAUNCH v%VERSION_NUMBER%").
{
  local self is lex(
    "setLaunchParameters", slp@,
    "calcLaunchDetails", cld@,
    "getPitch", getPitch@,
    "getBearing", getBearing@,
    "getThrottle", getThrottle@,
    "circularized", circularized@,
    "circ_thrott", circ_thrott@,
    "circ_heading", compass_of_vel@,
    "circ_pitch", circ_pitch@
  ).
  local p_alt is 250.
  local c_alt is BODY:ATM:HEIGHT * 0.9.
  local c_del is { IF ALTITUDE < p_alt RETURN 90. RETURN MIN(90,MAX(0, MAX(90 * (1 - SQRT(ALTITUDE/c_alt)),45-VERTICALSPEED))). }.
  local LCH_I IS 0.
  local LCH_ORBIT_VEL is 0.
  local LCH_AN is 0.
  local LCH_APO is 0.
  local HALF_LAUNCH is 145.

  function slp {
    // Altitude at which the pitchover begins
    PARAMETER p_a IS 250.
    // Altitude at which the pitchover ends
    PARAMETER c_a IS BODY:ATM:HEIGHT * 0.9.
    // The function that gets from one to the other
    PARAMETER c_d IS { IF ALTITUDE < p_alt RETURN 90. RETURN MIN(90,MAX(0, MAX(90 * (1 - SQRT(ALTITUDE/c_alt)),45-VERTICALSPEED))). }.
    SET p_alt to p_a.
    SET c_alt to c_a.
    SET c_del to c_d.
  }

  function cld {
    // The desireed orbital height
    PARAMETER l_alt.
    // orbit inclination
    PARAMETER l_inc IS 0.
    // longitude of ascending node
    PARAMETER l_lan IS SHIP:OBT:LAN.
    SET LCH_AN to l_lan.
    SET LCH_I to l_inc.
    SET LCH_ORBIT_VEL to SQRT(BODY:MU/(BODY:RADIUS + l_alt)).
    SET LCH_APO to l_alt.

    LOCAL az IS azm(l_inc).
    IF az < 0 { RETURN npld(l_alt,l_inc,l_lan). }
    ELSE { RETURN ld(l_alt,l_inc,l_lan,az). }

  }

  FUNCTION azm {
    PARAMETER i.
    IF latIncOk(LATITUDE,i) { RETURN __["mAngle"](ARCSIN(COS(i) / COS(LATITUDE))). }
    RETURN -1.
  }

  FUNCTION lazm {
    PARAMETER planet, az, ap.

    LOCAL v_orbit IS SQRT(planet:MU/(planet:RADIUS + ap)).
    LOCAL v_rot IS ssal(planet,LATITUDE).
    LOCAL v_orbit_x IS v_orbit * SIN(az).
    LOCAL v_orbit_y IS v_orbit * COS(az).
    LOCAL raz IS __["mAngle"](90 - ARCTAN2(v_orbit_y, v_orbit_x - v_rot)).
    pOut("Input azimuth: " + ROUND(az,2)).
    pOut("Output azimuth: " + ROUND(raz,2)).
    RETURN raz.
  }

  FUNCTION ssal {
    PARAMETER planet, lat.

    LOCAL v_rot IS 0.
    LOCAL circum IS 2 * CONSTANT:PI * planet:RADIUS.
    LOCAL period IS planet:ROTATIONPERIOD.
    IF period > 0 { SET v_rot TO COS(lat) * circum / period. }
    RETURN v_rot.
  }

  FUNCTION npld {
    PARAMETER ap,i,lan.

    LOCAL az IS 90.
    LOCAL lat IS MIN(i, 180-i).
    IF i > 90 { SET az TO 270. }

    IF i = 0 OR i = 180 { RETURN LIST(az,0). }

    LOCAL peta IS 0.
    IF LATITUDE > 0 { SET peta TO etop(TRUE,BODY,lan,i,lat,LONGITUDE). }
    ELSE { SET peta TO etop(FALSE,BODY,lan,i,-lat,LONGITUDE). }
    LOCAL launch_time IS TIME:SECONDS + peta - HALF_LAUNCH.
    RETURN LIST(az,launch_time).
  }

  FUNCTION ld {
    PARAMETER ap,i,lan,az.

    LOCAL peta IS 0.
    SET az TO lazm(BODY,az,ap).
    LOCAL etan IS etop(TRUE,BODY,lan,i,LATITUDE,LONGITUDE).
    LOCAL etdn IS etop(FALSE,BODY,lan,i,LATITUDE,LONGITUDE).

    IF etdn < 0 AND etan < 0 { RETURN npld(ap,i,lan). }
    ELSE IF (etdn < etan OR etan < HALF_LAUNCH) AND etdn >= HALF_LAUNCH {
      SET peta TO etdn.
      SET az TO __["mAngle"](180 - az).
    } ELSE IF etan >= HALF_LAUNCH { SET peta TO etan. }
    ELSE { SET peta TO etan + BODY:ROTATIONPERIOD. }
    LOCAL launch_time IS TIME:SECONDS + peta - HALF_LAUNCH.
    RETURN LIST(az,launch_time).
  }

  FUNCTION latIncOk {
    PARAMETER lat,i.
    RETURN (i > 0 AND ABS(lat) < 90 AND MIN(i,180-i) >= ABS(lat)).
  }

  FUNCTION etop {
    PARAMETER is_AN, planet, orb_lan, i, ship_lat, ship_lng.

    LOCAL peta IS -1.
    IF latIncOk(ship_lat,i) {
      LOCAL rel_lng IS ARCSIN(TAN(ship_lat)/TAN(i)).
      IF NOT is_AN { SET rel_lng TO 180 - rel_lng. }
      LOCAL g_lan IS __["mAngle"](orb_lan + rel_lng - planet:ROTATIONANGLE).
      LOCAL node_angle IS __["mAngle"](g_lan - ship_lng).
      SET peta TO (node_angle / 360) * planet:ROTATIONPERIOD.
    }
    RETURN peta.
  }

  function getBearing {
    LOCAL lat IS SHIP:LATITUDE.
    LOCAL vo IS SHIP:VELOCITY:ORBIT.
    IF (LCH_I > 0 AND ABS(lat) < 90 AND MIN(LCH_I,180 - LCH_I) >= ABS(lat)) {
      LOCAL az IS ARCSIN( COS(LCH_I) / COS(lat) ).
      IF NOT LCH_AN { SET az TO __["mAngle"](180 - az). }
      IF vo:MAG >= LCH_ORBIT_VEL { RETURN az. }
      LOCAL x IS (LCH_ORBIT_VEL * SIN(az)) - VDOT(vo,HEADING(90,0):VECTOR).
      LOCAL y IS (LCH_ORBIT_VEL * COS(az)) - VDOT(vo,HEADING(0,0):VECTOR).
      RETURN __["mAngle"](90 - ARCTAN2(y, x)).
    } ELSE {
      IF LCH_I < 90 { RETURN 90. }
      ELSE { RETURN 270. }
    }
  }
  function getPitch {
    return c_del().
  }
  function getThrottle {
    if ship:apoapsis < LCH_APO return 1.1 - min(1, max(0, (ship:apoapsis/LCH_APO)^3)).
    return 0.
  }
  LOCAL HALF_LAUNCH IS 145.

  FUNCTION changeHALF_LAUNCH
  {
    PARAMETER h.
    IF h > 0 { SET HALF_LAUNCH TO h. }
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
      local east is vcrs(ship:up:vector, ship:north:vector).

      local trig_x is vdot(ship:north:vector, pointing).
      local trig_y is vdot(east, pointing).

      local result is arctan2(trig_y, trig_x).

      return __["mAngle"](result).
    }

    function circ_pitch {
        return -(eta_ap_with_neg()/3).
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

  export(self).
}
