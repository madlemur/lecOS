@LAZYGLOBAL OFF.
pout("LEC LAUNCH v%VERSION_NUMBER%").
{
  local self is lex(
    "setLaunchParameters", setLaunchParameters@,
    "calcLaunchDetails", calcLaunchDetails@,
    "getPitch", getPitch@,
    "getBearing", getBearing@,
    "getThrottle", getThrottle@,
    "circularized", circularized@,
    "circ_thrott", circ_thrott@,
    "circ_heading", compass_of_vel@,
    "circ_pitch", circ_pitch@,
    "circ_deltav", circ_deltav@
  ).
  local p_alt is 250.
  local c_alt is BODY:ATM:HEIGHT * 0.9.
  local c_del is { IF ALTITUDE < p_alt RETURN 90. RETURN MIN(90,MAX(-3, MAX(90 * (1 - SQRT(ship:apoapsis/LCH_APO)),45-VERTICALSPEED))). }.
  local LCH_I IS 0.
  local LCH_ORBIT_VEL is 0.
  local LCH_AN is 0.
  local LCH_APO is 0.
  local HALF_LAUNCH is 145.
  local timeout is 9000.
  local staging is import("lib/staging.ks", false).
  local times is import("lib/time.ks", false).

  function setLaunchParameters {
    // Altitude at which the pitchover begins
    PARAMETER p_a IS 250.
    // Altitude at which the pitchover ends
    PARAMETER c_a IS BODY:ATM:HEIGHT * 0.9.
    // The function that gets from one to the other
    PARAMETER c_d IS { IF ALTITUDE < p_alt RETURN 90. RETURN MIN(90,MAX(-3, MAX(90 * (1 - SQRT(ship:apoapsis/LCH_APO)),45-VERTICALSPEED))). }.
    SET p_alt to p_a.
    SET c_alt to c_a.
    SET c_del to c_d.
  }

  function calcLaunchDetails {
    // The desireed orbital height
    PARAMETER l_alt.
    // orbit inclination
    PARAMETER l_inc IS 0.
    // longitude of ascending node
    PARAMETER l_lan IS __["mAngle"](SHIP:OBT:LAN).
    SET LCH_AN to l_lan.
    SET LCH_I to l_inc.
    SET LCH_ORBIT_VEL to SQRT(BODY:MU/(BODY:RADIUS + l_alt)).
    SET LCH_APO to l_alt.

    LOCAL az IS azimuth(l_inc).
    IF az < 0 { RETURN noPassLaunchDetails(l_alt,l_inc,l_lan). }
    ELSE { RETURN launchDetails(l_alt,l_inc,l_lan,az). }

  }

  FUNCTION azimuth {
    PARAMETER i.
    IF latIncOk(LATITUDE,i) { RETURN __["mAngle"](ARCSIN(COS(i) / COS(LATITUDE))). }
    RETURN -1.
  }

  FUNCTION launchAzimuth {
    PARAMETER planet, az, ap.

    LOCAL v_orbit IS SQRT(planet:MU/(planet:RADIUS + ap)).
    LOCAL v_rot IS planetSurfaceSpeedAtLat(planet,LATITUDE).
    LOCAL v_orbit_x IS v_orbit * SIN(az).
    LOCAL v_orbit_y IS v_orbit * COS(az).
    LOCAL raz IS __["mAngle"](90 - ARCTAN2(v_orbit_y, v_orbit_x - v_rot)).
    pOut("Input azimuth: " + ROUND(az,2)).
    pOut("Output azimuth: " + ROUND(raz,2)).
    RETURN raz.
  }

  FUNCTION planetSurfaceSpeedAtLat {
    PARAMETER planet, lat.

    LOCAL v_rot IS 0.
    LOCAL circum IS 2 * CONSTANT:PI * planet:RADIUS.
    LOCAL period IS planet:ROTATIONPERIOD.
    IF period > 0 { SET v_rot TO COS(lat) * circum / period. }
    RETURN v_rot.
  }

  FUNCTION noPassLaunchDetails {
    PARAMETER ap,i,lan.

    LOCAL az IS 90.
    LOCAL lat IS MIN(i, 180-i).
    IF i > 90 { SET az TO 270. }

    IF i = 0 OR i = 180 { RETURN LIST(az,0). }

    LOCAL peta IS 0.
    IF LATITUDE > 0 { SET peta TO etaToOrbitalPlane(TRUE,BODY,lan,i,lat,LONGITUDE). }
    ELSE { SET peta TO etaToOrbitalPlane(FALSE,BODY,lan,i,-lat,LONGITUDE). }
    LOCAL launch_time IS TIME:SECONDS + peta - HALF_LAUNCH.
    RETURN LIST(az,launch_time).
  }

  FUNCTION launchDetails {
    PARAMETER ap,i,lan,az.

    LOCAL peta IS 0.
    SET az TO launchAzimuth(BODY,az,ap).
    LOCAL etan IS etaToOrbitalPlane(TRUE,BODY,lan,i,LATITUDE,LONGITUDE).
    LOCAL etdn IS etaToOrbitalPlane(FALSE,BODY,lan,i,LATITUDE,LONGITUDE).

    IF etdn < 0 AND etan < 0 { RETURN noPassLaunchDetails(ap,i,lan). }
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

  FUNCTION etaToOrbitalPlane {
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
    if maxthrust > 0 and ship:velocity:orbit:mag < LCH_ORBIT_VEL return 1.05 - min(1, max(0, (ship:velocity:orbit:mag/LCH_ORBIT_VEL)^4)).
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
        parameter deltav.
        if not times["hasTime"]("circ") and eta:apoapsis < (staging["burnTimeForDv"](deltav:mag)/2) {
          pout("eta: " + eta:apoapsis).
          pout("burn: " + staging["burnTimeForDv"](deltav:mag)).
          pout("deltav: " + deltav:mag).
          times["setTime"]("circ").
        }
        if times["hasTime"]("circ") {
          if maxthrust < 0.05 or vang(ship:facing:vector,deltav) > 2 { return 0. } //Throttle to 0 if not pointing the right way
	        else { return max(0,min(1,deltav:mag/10)). } //lower throttle gradually as remaining deltaV gets lower
        }
        return 0.
    }

    function circ_deltav {
        local ovel is velocityat(ship, TIME:SECONDS + eta:apoapsis):orbit.
	      local vecHorizontal is vxcl(positionat(ship, TIME:SECONDS + eta:apoapsis) + ship:position - body:position, ovel).
	      set vecHorizontal:mag to sqrt(body:MU/(body:Radius + altitude)).
        clearvecdraws().
        local ovelvec is VECDRAW(V(0,0,0), ovel, RGB(1,1,0), "Orbital Vel", 1.0, TRUE, 0.2).
        local hvelvec is VECDRAW(V(0,0,0), vecHorizontal, RGB(0,1,0), "Horizontal Vel", 1.0, TRUE, 0.2).
        local dvelvec is VECDRAW(V(0,0,0), vecHorizontal - ovel, RGB(0,0,1), "Delta V", 1.0, TRUE, 0.2).

	    return vecHorizontal - ovel. //deltaV as a vector
    }

    function circularized {
        local dv is circ_deltav().
        if dv:mag < 0.02 {
            pout("Circularization complete. ecc=" + ship:obt:ECCENTRICITY).
            unlock steering.
            unlock throttle.
            set timeout to 9000.
            clearvecdraws().
            return true.
        }
        if (times["hasTime"]("circ") AND times["diffTime"]("circ") > timeout) {
            pout("Circularize timed out.").
            unlock steering.
            unlock throttle.
            set timeout to 9000.
            clearvecdraws().
            return true.
        }
        if (dv:mag < 0.05 AND times["hasTime"]("circ") AND times["diffTime"]("circ") > 3) {
            times["setTime"]("circ").
            set timeout to 3.
        }
        return false.
    }

  export(self).
}
