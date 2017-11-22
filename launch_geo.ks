{
  local launch_geo is lex (
    "HALF_LAUNCH", 145,
    "changeHALF_LAUNCH", changeHALF_LAUNCH@,
    "calcLaunchDetails", calcLaunchDetails@,
    "azimuth", azimuth@
  ).

  FUNCTION mAngle
  {
    PARAMETER a.
    UNTIL a >= 0 { SET a TO a + 360. }
    RETURN MOD(a,360).
  }

  FUNCTION changeHALF_LAUNCH
  {
    PARAMETER h.
    IF h > 0 { SET launch_geo["HALF_LAUNCH"] TO h. }
  }

  function latIncOk
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
      LOCAL g_lan IS mAngle(orb_lan + rel_lng - planet:ROTATIONANGLE).
      LOCAL node_angle IS mAngle(g_lan - ship_lng).
      SET eta TO (node_angle / 360) * planet:ROTATIONPERIOD.
    }
    RETURN eta.
  }

  FUNCTION azimuth
  {

    parameter	inc. // target inclination
    IF latIncOk(LATITUDE,inc) {
    	// find orbital velocity for a circular orbit at the current altitude.
    	local V_orb is sqrt( body:mu / ( ship:altitude + body:radius)).

    	// project desired orbit onto surface heading
    	local az_orb is arcsin ( cos(inc) / cos(ship:latitude)).
    	if (inc < 0) {
    		set az_orb to 180 - az_orb.
    	}

    	// create desired orbit velocity vector
    	local V_star is heading(az_orb, 0)*v(0, 0, V_orb).

    	// find horizontal component of current orbital velocity vector
    	local V_ship_h is ship:velocity:orbit - vdot(ship:velocity:orbit, up:vector)*up:vector.

    	// calculate difference between desired orbital vector and current (this is the direction we go)
    	local V_corr is V_star - V_ship_h.

    	// project the velocity correction vector onto north and east directions
    	local vel_n is vdot(V_corr, ship:north:vector).
    	local vel_e is vdot(V_corr, heading(90,0):vector).

    	// calculate compass heading
    	local az_corr is arctan2(vel_e, vel_n).
    	return az_corr.
    }
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
    output("Input azimuth: " + ROUND(az,2)).
    output("Output azimuth: " + ROUND(raz,2)).
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
    LOCAL launch_time IS TIME:SECONDS + eta - launch_geo["HALF_LAUNCH"].
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
    ELSE IF (eta_to_DN < eta_to_AN OR eta_to_AN < launch_geo["HALF_LAUNCH"]) AND eta_to_DN >= launch_geo["HALF_LAUNCH"] {
      SET eta TO eta_to_DN.
      SET az TO mAngle(180 - az).
    } ELSE IF eta_to_AN >= launch_geo["HALF_LAUNCH"] { SET eta TO eta_to_AN. }
    ELSE { SET eta TO eta_to_AN + BODY:ROTATIONPERIOD. }
    LOCAL launch_time IS TIME:SECONDS + eta - launch_geo["HALF_LAUNCH"].
    RETURN LIST(az,launch_time).
  }

  FUNCTION calcLaunchDetails
  {
    PARAMETER ap,i,lan.

    LOCAL az IS azimuth(i).
    IF az < 0 { RETURN noPassLaunchDetails(ap,i,lan). }
    ELSE { RETURN launchDetails(ap,i,lan,az). }
  }
  export(launch_geo).
}
