// Maneuver Library v1.0.0
// Kevin Gisi
// http://youtube.com/gisikw
// RUN lib_warp.
LOCAL _p IS "maneuver".

SET burnoutCheck TO "reset".
FUNCTION MNV_BURNOUT {
  PARAMETER autoStage.

  IF burnoutCheck = "reset" {
    SET burnoutCheck TO MAXTHRUST.
    RETURN FALSE.
  }

  IF burnoutCheck - MAXTHRUST > 10 {
    IF autoStage {
      LOCAL currentThrottle IS THROTTLE.
      LOCK THROTTLE TO 0.
      WAIT 1. STAGE. WAIT 1.
      LOCK THROTTLE TO currentThrottle.
    }
    SET burnoutCheck TO "reset".
    RETURN TRUE.
  }

  RETURN FALSE.
}

// Time to complete a maneuver
FUNCTION MNV_TIME {
  PARAMETER dV.

  LOCAL engine_stats IS MNV_ENGINE_STATS().

  LOCAL f IS engine_stats["Thrust"] * 1000.  // Engine Thrust (kg * m/s²)
  LOCAL m IS SHIP:MASS * 1000.        // Starting mass (kg)
  LOCAL e IS CONSTANT:E.            // Base of natural log
  LOCAL p IS engine_stats["ISP"].         // Engine ISP (s)
  LOCAL g IS 9.82.                    // Gravitational acceleration constant (m/s²)

  RETURN g * m * p * (1 - e^(-dV/(g*p))) / f.
}

FUNCTION MNV_BURN_TIME {
  PARAMETER dV.

  LOCAL e IS CONSTANT:E.
  LOCAL eng_stats IS MNV_ENGINE_STATS().
  LOCAL mass_rate IS eng_stats["MassRate"].
  LOCAL v_e IS eng_stats["ExitVel"].

  // Rocket equation solved for t.
  LOCAL burn_t IS  SHIP:MASS*(1 - e^(-dV/v_e))/mass_rate.

  RETURN burn_t.
}

FUNCTION MNV_ENGINE_STATS {
  LOCAL g IS 9.82.	// Engines use this.

  LOCAL all_thrust IS 0.
  LOCAL old_isp_devider IS 0.
  LOCAL all_engines IS LIST().

  LIST ENGINES IN all_engines.
  FOR eng IN all_engines {
    IF eng:IGNITION AND NOT eng:FLAMEOUT {
      SET all_thrust TO (all_thrust + eng:AVAILABLETHRUST).
      SET old_isp_devider TO (old_isp_devider + (eng:AVAILABLETHRUST / eng:VISP)).
    }
  }

  LOCAL mean_isp IS (all_thrust / old_isp_devider).
  LOCAL ch_rate IS all_thrust/(g*mean_isp).
  LOCAL exit_velocity IS all_thrust/ch_rate.

  LOCAL stat_block IS lexicon().
	stat_block:ADD("Thrust", all_thrust).
	stat_block:ADD("ISP", mean_isp).
	stat_block:ADD("MassRate", ch_rate).
	stat_block:ADD("ExitVel", exit_velocity).

	RETURN stat_block.
}

// Delta v requirements for Hohmann Transfer
FUNCTION MNV_HOHMANN_DV {
  PARAMETER desiredAltitude.

  LOCAL u  IS SHIP:OBT:BODY:MU.
  LOCAL r1 IS SHIP:OBT:SEMIMAJORAXIS.
  LOCAL r2 IS desiredAltitude + SHIP:OBT:BODY:RADIUS.

  // v1
  LOCAL v1 IS SQRT(u / r1) * (SQRT((2 * r2) / (r1 + r2)) - 1).

  // v2
  LOCAL v2 IS SQRT(u / r2) * (1 - SQRT((2 * r1) / (r1 + r2))).

  RETURN LIST(v1, v2).
}

// Execute the next node
FUNCTION MNV_EXEC_NODE {
  PARAMETER autoWarp.
  SAS off.
	local nd to NEXTNODE.
	//print out node's basic parameters - ETA and deltaV
	uiBanner(_p, "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag)).

	//now we just need to divide deltav:mag by our ship's max acceleration
	local burn_duration to MNV_BURN_TIME(nd:deltav:mag).
	uiBanner(_p, "Estimated burn duration: " + round(burn_duration) + "s").

	if autoWarp { warpto (TIME:SECONDS + nd:eta - (burn_duration/2 + 60)). }

	// we want to lock the vector, so we get better accuracy
	local lock np to lookdirup(nd:deltav, ship:facing:topvector). //points to node, keeping roll the same.
	lock steering to np.
	uiBanner(_p, "waiting for the ship to turn").
	//now we need to wait until the burn vector and ship's facing are aligned
	wait until abs(np:pitch - facing:pitch) < 0.05 and abs(np:yaw - facing:yaw) < 0.05.

	//the ship is facing the right direction, let's wait for our burn time
	if autowarp { warpto(TIME:SECONDS + nd:eta - (burn_duration/2 + 10)). }

	wait until nd:eta <= (burn_duration/2).

	local tset to 0.
	lock throttle to tset.

	local done to False.
	//initial deltav
	local dv0 to nd:deltav.
	local max_acc is 0.

	until done
	{
		//recalculate current max_acceleration, as it changes while we burn through fuel
		set max_acc to ship:maxthrust/ship:mass.

		//throttle is 100% until there is less than 1 second of time left to burn
		//when there is less than 1 second - decrease the throttle linearly
		set tset to min(nd:deltav:mag/max_acc, 1).
		if vdot(dv0, nd:deltav) < 0 {
			uiBanner(_p,"End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1)).
			lock throttle to 0.
			break.
		}
		//we have very little left to burn, less then 0.1m/s
		if nd:deltav:mag < 0.1 {
			uiBanner(_p,"Finalizing burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1)).
			//we burn slowly until our node vector starts to drift significantly from initial vector
			//this usually means we are on point
			wait until vdot(dv0, nd:deltav) < 0.1.

			lock throttle to 0.
			uiBanner(_p, "End burn, remain dv " + round(nd:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, nd:deltav),1)).
			set done to True.
		}
	}
	//we no longer need the maneuver node
	remove nd.
	uiBanner(_p, "Runnode Finished").
	//turn into the sun
	lOCK STEERING to MNV_STEERING_DIR(SUN:NORTH).
	wait 7.

	//set throttle to 0 just in case.
	set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
	unlock throttle.
}

function MNV_SET_ALT {
	parameter node_eta,target_alt.
	set target_alt to target_alt*1000.
	local v_burn to VELOCITYAT(SHIP,time:seconds + node_eta).
	local r_burn to (POSITIONAT(SHIP,time:seconds + node_eta) - BODY:POSITION):MAG.
	local semi_major_axis_new to (r_burn + target_alt + BODY:RADIUS)/2.
	// Vis-viva with new sma
	local v_target to sqrt(BODY:MU * (2/r_burn - 1/semi_major_axis_new)).
	local node_dv to v_target - v_burn:ORBIT:MAG.
	local my_node to NODE(time:seconds + node_eta,0,0,node_dv).
	add my_node.
}

function MNV_STEERING_DIR {
   parameter dir.

    return LOOKDIRUP(dir:VECTOR, FACING:TOPVECTOR).
}

function MNV_CIRC {
	local th to 0.
	lock throttle to th.
	local dV is ship:facing:vector:normalized. //temporary
	lock steering to LookUpDir(dV, facing:topvector).
	ag1 off. //ag1 to abort

	local timeout is time:seconds + 9000.
	when dV:mag < 0.5 then set timeout to time:seconds + 3.

	until ag1 or dV:mag < 0.02 or time:seconds > timeout {
		local vecNormal to vcrs(up:vector,velocity:orbit).
		local vecHorizontal to -1 * vcrs(up:vector, vecNormal).
		set vecHorizontal:mag to sqrt(body:MU/(body:Radius + altitude)).
		set dV to vecHorizontal - velocity:orbit. //deltaV as a vector

		//throttle control
		if vang(ship:facing:vector,dV) > 1 {
			set th to 0. //Throttle to 0 if not pointing the right way
		} else {
			set th to max(0,min(1,dV:mag/10)).  //lower throttle gradually as remaining deltaV gets lower
		}
		wait 0.
	}
	set th to 0.
}
