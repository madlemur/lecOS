@LAZYGLOBAL OFF.
{
	// ------------------------
	// LaunchFactory - A function that returns a pseudo-class that will handle
	// launch functionality up to, but not including, circularization.
	// Each function is meant to be run once per frame per the mission_runner
	// pattern.
	LOCAL FUNCTION LaunchFactory {
		PARAMETER APO, INC IS 0, LAN IS FALSE.
		
		local LCH_I IS 0.
		local LCH_ORBIT_VEL is 0.
		local LCH_AN is 0.
		local LCH_APO is 0.
		local HALF_LAUNCH is 145.
		local LCH_AZ = 0.
		local LCH_TIME = TIME:SECONDS + 15.
		local countdown = 10.
		local timeout is 90.
		local th is 0.
		local st is ship:prograde:forevector.
		
		calcLaunchDetails(APO,INC,LAN).
		LOCK THROTTLE TO th.
		LOCK STEERING TO st.
		
		// Set up/override launch behavior
		function setAscentParameters {
			parameter pitchBegin is 250, pitchEnd is BODY:ATM:HEIGHT * 0.9, pitchCurve is false.
			  SET p_alt to pitchBegin.
			  SET c_alt to pitchEnd.
			  SET c_del to pitchCurve || 
			  	{ 
					IF ALTITUDE < p_alt 
						RETURN 90. 
					RETURN MIN(
						90,
						MAX(
							-VANG(prograde:vector,horizon())*1.5, 
							MAX(
								90 * (1 - SQRT(ship:obt:apoapsis/LCH_APO)),
								45-VERTICALSPEED
							)
						)
					). 
				}.
			}
		}
		
		// Countdown to liftoff
		function isCountingDown {
			if FLOOR(LCH_TIME - TIME:SECONDS) < countdown {
				SET countdown to countdown - 1.
				phud("T-minus " + countdown + " seconds").
			}
			return(countdown > 0).
		}
		
		// Check for completion (apoapsis >= target && curr alt > atmosphere height)
		function isAscentComplete {
		  	if ship:obt:apoapsis >= LCH_APO AND ship:altitude > BODY:ATM:HEIGHT {
				UNLOCK THROTTLE.
				UNLOCK STEERING.
			  	return true.
		  	} else {
				set th to getThrottle().
				set st to heading(getBearing(),getPitch()).
				return false.
		  	}
		}
		
		function horizon {
			local nrm is VCRS(BODY:POSITION:NORMALIZED,SHIP:VELOCITY:ORBIT:NORMALIZED). // Orbit normal
			local hrz is VCRS(nrm,-BODY:POSITION:NORMALIZED). // Basically, ship:velocity:orbit projected
			// at 90deg to both the radial (body:position) and normal vectors. Theoretically, the horizon.
			return hrz:NORMALIZED.
		}
		
		function calcLaunchDetails {
		  // The desireed orbital height
		  PARAMETER l_alt.
		  // orbit inclination
		  PARAMETER l_inc IS 0.
		  // longitude of ascending node
		  PARAMETER l_lan IS false.
		  SET LCH_AN to l_lan.
		  SET LCH_I to l_inc.
		  SET LCH_ORBIT_VEL to SQRT(BODY:MU/(BODY:RADIUS + l_alt)).
		  SET LCH_APO to l_alt.
	  
		  LOCAL az IS azimuth(l_inc).
		  local l_details is 0.
		  IF NOT l_lan { set l_details to LIST(az, TIME:SECONDS + 10). }
		  ELSE IF az < 0 { set l_details to noPassLaunchDetails(l_alt,l_inc,l_lan). }
		  ELSE { set l_details to launchDetails(l_alt,l_inc,l_lan,az). }
	  
		  SET LCH_AZ to l_details[0].
		  SET LCH_TIME to l_details[1].
		  SET countdown to 10.
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
		  SET laz TO launchAzimuth(BODY,az,ap).
		  LOCAL etan IS etaToOrbitalPlane(TRUE,BODY,lan,i,LATITUDE,LONGITUDE).
		  LOCAL etdn IS etaToOrbitalPlane(FALSE,BODY,lan,i,LATITUDE,LONGITUDE).
	  
		  IF etdn < 0 AND etan < 0 { RETURN noPassLaunchDetails(ap,i,lan). }
		  ELSE IF (etdn < etan OR etan < HALF_LAUNCH) AND etdn >= HALF_LAUNCH {
			SET peta TO etdn.
			SET laz TO __["mAngle"](180 - laz).
		  } ELSE IF etan >= HALF_LAUNCH { SET peta TO etan. }
		  ELSE { SET peta TO etan + BODY:ROTATIONPERIOD. }
		  LOCAL launch_time IS TIME:SECONDS + peta - HALF_LAUNCH.
		  RETURN LIST(laz,launch_time).
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
		  if maxthrust > 0 and ship:velocity:orbit:mag < LCH_ORBIT_VEL return 1 - min(1, max(0, (ship:velocity:orbit:mag/LCH_ORBIT_VEL)^4)).
		  return 0.
		}
	  
		FUNCTION changeHALF_LAUNCH
		{
		  PARAMETER h.
		  IF h > 0 { SET HALF_LAUNCH TO h. }
		}

	}

	export(LaunchFactory).
}