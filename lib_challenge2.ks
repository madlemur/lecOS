@LAZYGLOBAL OFF.

function stop_at_nc{
	parameter spot.

	local spot_lng to mod(360+Body:ROTATIONANGLE+spot:LNG,360).
	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).

	// this is our time for one surface period
	local srf_period to ((1/SHIP:ORBIT:PERIOD) - (1/Body:ROTATIONPERIOD))^(-1).

	local time_2_spot to mod((720 + spot_lng - ship_ref),360) * srf_period/360 .
	print "time_2_spot : " + round (time_2_spot,2).

	// we travel to target and wait a halve orbit and the offset is the difference of one orbit.
	local node_eta to time_2_spot + SHIP:ORBIT:PERIOD/2 + (srf_period - SHIP:ORBIT:PERIOD).

	local target_alt to spot:TERRAINHEIGHT/1000 + 0.615.

	set_altitude(node_eta,target_alt).
}

//Code by baloan (kos wiki mtkv4)
function warpfor {
	declare local parameter dt.
	local t1 to time:seconds + dt.
	if dt < 0 {
		print "T+" + round(missiontime) + " Warning: wait time " + round(dt) + " is in the past.".
	}
	local oldwp to 0.
	local oldwarp to warp.
	until time:seconds >= t1 {
		local rt to t1 - time:seconds.       // remaining time
		local wp to 0.
		if rt > 5      { set wp to 1. }
		if rt > 10     { set wp to 2. }
		if rt > 50     { set wp to 3. }
		if rt > 100    { set wp to 4. }
		if rt > 1000   { set wp to 5. }
		if rt > 10000  { set wp to 6. }
		if rt > 100000 { set wp to 7. }
		if wp <> oldwp OR warp <> wp {
			set warp to wp.
			wait 0.1.
			set oldwp to wp.
			set oldwarp to warp.
		}
    wait 0.1.
	}
}

// Node runner function. executes the next node. (from kos-doc toturial)
function run_node{
	SAS off.
	local nd to NEXTNODE.
	//print out node's basic parameters - ETA and deltaV
	print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

	//now we just need to divide deltav:mag by our ship's max acceleration
	local burn_duration to get_burn_t(nd:deltav:mag).
	print "Estimated burn duration: " + round(burn_duration) + "s".
	warpfor (nd:eta - (burn_duration/2 + 60)).

	// we want to lock the vector, so we get better accuracy
	local lock np to lookdirup(nd:deltav, ship:facing:topvector). //points to node, keeping roll the same.
	lock steering to np.
	print "waiting for the ship to turn".
	//now we need to wait until the burn vector and ship's facing are aligned
	wait until abs(np:pitch - facing:pitch) < 0.1 and abs(np:yaw - facing:yaw) < 0.1.

	//the ship is facing the right direction, let's wait for our burn time
	warpfor (nd:eta - (burn_duration/2 + 10)).

	wait until nd:eta <= (burn_duration/2).

	local tset to 0.
	lock throttle to tset.

	local done to False.
	//initial deltav
	local dv0 to nd:deltav.
	local max_acc is 0.

	print "using time based burn.".
	lock max_acc to ship:maxthrust/ship:mass.
	lock tset to min(nd:deltav:mag/max_acc, 1).
	until done {
		if (nd:deltav:MAG < 1) {
			local my_dir to lookdirup(nd:deltav, ship:facing:topvector).
			lock steering to my_dir.

			wait until nd:deltav:MAG < 0.2.
			set my_dir to lookdirup(nd:deltav, ship:facing:topvector).
			set tset to min(nd:deltav:mag/max_acc, 1).
			print "one second left burning".
			wait 0.93.
			set tset to 0.
			set done to true.
		}

	}

	//we no longer need the maneuver node
	remove nd.
	print "Runnode Finished".

	//set throttle to 0 just in case.
	set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
	unlock throttle.
}

// changes the altitude of the orbits opposite
// only usable at PE, AP or circular orbits.
function set_altitude {
	declare local parameter node_eta,target_alt.
	print "setting Altitude of " + round(target_alt,2) + " km".
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



// Takes the dV and returns the expected burn time without staging.
function get_burn_t {
	declare local parameter dV.

	local e is CONSTANT:E.
	local eng_stats is get_engine_stats().
	local mass_rate is eng_stats[2].
	local v_e is eng_stats[3].

	// Rocket equation solved for t.
	local burn_t is  SHIP:MASS*(1 - e^(-dV/v_e))/mass_rate.

	return burn_t.
}


// returns commulative thrust, mean isp, the mass change and the mean_exit_velocity of all engines of this stage.
function get_engine_stats {

	local g is 9.82.	// Engines use this.

	local all_thrust is 0.
	local old_isp_devider is 0.
	local all_engines is LIST().

  	list ENGINES in all_engines.
	for eng in all_engines {
		if eng:IGNITION AND NOT eng:FLAMEOUT {
			set all_thrust to (all_thrust + eng:AVAILABLETHRUST).
			set old_isp_devider to (old_isp_devider + (eng:AVAILABLETHRUST / eng:VISP)).
		}
	}

	local mean_isp is (all_thrust / old_isp_devider).
	local ch_rate is all_thrust/(g*mean_isp).
	local exit_velocity is all_thrust/ch_rate.

	return list(all_thrust , mean_isp , ch_rate , exit_velocity).
}
