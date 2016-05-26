@LAZYGLOBAL OFF.
run lib_nav2.
// get burn time Free Fall Edition
// Rocket Equation against gravitation solved for t requires the Lambert W function.
// so we use a iterative solution.
function get_burn_t_ff {
	parameter r_start,r_ground.
	local dv is sqrt((2*BODY:MU*(r_start - r_ground))/(r_start * r_ground)).
	local m0 IS SHIP:MASS.
	local g_ground to BODY:MU/r_ground^2.
	local g_start to BODY:MU/r_start^2.
	local e to constant:e.
	local exp to 2.69.
	local g_mean to ((g_start^exp+g_ground^exp)/2)^(1/exp).
	local t_burn is 0.
	local dv_old is 0.
	local dv_new is 0.
	local dv_change is dv.
	local dv_total is 0.
	
	local eng_stats to get_engine_stats().
	local ch_rate is eng_stats[2].
	local v_e is eng_stats[3].
	
	until dv_change < 0.001 {
 
		set dv_total to dv_total + dv_change.
		set t_burn to SHIP:MASS*(1 - e^(-dv_total/v_e))/ch_rate.
		set dv_new to g_mean * t_burn.
		set dv_change to abs(dv_new - dv_old).
		set dv_old to dv_new.
	
	}
	print "burn_time FF: " + round (t_burn,2).
	return t_burn+0.06.
}

// 
// Returns the altitude above sea level, when the burn has to start. 
// returns a few meter extra to soften the landing.
function get_burn_height {
	parameter r_from,r_to.

	local grav_i is BODY:MU/r_to^2.
	local grav_o to BODY:MU/r_from^2.
	local exp to 2.69.
	local grav_mean to ((grav_i^exp + (grav_o^exp))/2)^(1/exp).

	local eng_stats to get_engine_stats().
	local ch_rate to  eng_stats[2].
	local v_e to  eng_stats[3].
	local M to SHIP:MASS.

	local r_burn_old is r_to.
	local r_burn_new is r_to.
	local r_burn_delta is 99.
	local r_burn to r_burn_new.

	local lock grav_b to BODY:MU/(r_burn^2).
	local lock grav_mean_b to (((grav_i^exp) + (grav_b^exp))/2)^(1/exp).

	local lock v_burn to sqrt((2*BODY:MU*(r_from - r_burn))/(r_from * r_burn)).
	local t to get_burn_t_ff(r_from,r_burn).

// These are all equivalent 	
//	local lock stopping_dist to v_burn*t + (grav_mean_b*t^2)/2 - (t*v_e - t*v_e * (ln(M/(M-t*ch_rate))/(M/(M-t*ch_rate)-1))). 
//	local lock stopping_dist to v_burn*t + (0.5* grav_mean_b * (t^2)) - ((v_e * M/ch_rate) * ((1 - ch_rate * t/M) * ln(1 - ch_rate*t/M) + (ch_rate*t/M))). 
	local lock stopping_dist to v_burn*t + (grav_mean_b*t^2)/2 - (v_e*(t - M/ch_rate) *ln(M/(M-t*ch_rate)) + v_e*t) .
	
	until abs ( r_burn_delta ) < 0.1 {

		set t to get_burn_t_ff(r_from,r_burn).
		set r_burn_new to r_to + stopping_dist.
		set r_burn_delta to r_burn_new-r_burn_old .
		set r_burn to (r_burn_old + (r_burn_delta*0.8)).
		set r_burn_old to r_burn.
	}

	print "Burning Altitude:       " + round((r_burn-BODY:RADIUS),1).
	print "Free Fall velocity:     " + round(v_burn,1).
	// add safety here; reduce 15 to 5 to stop at the surface (the trigger will not fire).
	return (15+r_burn -BODY:RADIUS).
}



// You want to call this function
function land_at_position{
	parameter lat,lng.
	local coordinates to latlng(lat,lng).
	stop_at(coordinates).
	do_suecide_burn(coordinates).
	local d_target to round((SHIP:GEOPOSITION:POSITION - coordinates:POSITION):MAG,1).
	print "We landed "+d_target +" m from our target".
}



function stop_at{
	parameter spot.

	local node_lng to mod(360+Body:ROTATIONANGLE+spot:LNG,360).
	
	set_inc_lan_i(spot:LAT,node_lng-90,false).
	local my_node to NEXTNODE.
	// change node_eta to adjust for rotation:
	local t_wait_burn to my_node:ETA + OBT:PERIOD/4.
	
	local rot_angle to t_wait_burn*360/Body:ROTATIONPERIOD.
	remove my_node.
	set_inc_lan_i(spot:LAT,node_lng-90+rot_angle,false).
	run_node().

	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).
	local ship_2_node to mod((720 + node_lng+rot_angle - ship_ref),360).
	local node_eta to ship_2_node*OBT:PERIOD/360.
	local my_node to NODE(time:seconds + node_eta,0,0,-SHIP:VELOCITY:SURFACE:MAG).
	ADD my_node.
	
	run_stopping_node(spot). 
}


function run_stopping_node{
	parameter target_spot.
	SAS off.
	local nd to NEXTNODE.
	//print out node's basic parameters - ETA and deltaV
	print "Node in: " + round(nd:eta) + ", DeltaV: " + round(nd:deltav:mag).

	//now we just need to divide deltav:mag by our ship's max acceleration
	local burn_duration to get_burn_t(nd:deltav:mag).

	warpfor (nd:eta - (burn_duration + 60)).

	local lock down_vector to vdot (UP:VECTOR,SHIP:VELOCITY:SURFACE)*UP:VECTOR.
	local lock burn_vector  to (-1* (SHIP:VELOCITY:SURFACE - down_vector)).
	
	local lock np to lookdirup(burn_vector, ship:facing:topvector).
	lock steering to np.
	print "waiting for the ship to turn".
	//now we need to wait until the burn vector and ship's facing are aligned
	wait until abs(np:pitch - facing:pitch) < 0.3 and abs(np:yaw - facing:yaw) < 0.3.

	//the ship is facing the right direction, let's wait for our burn time
	warpfor (nd:eta - (burn_duration)).

	local eng_stats to get_engine_stats().
	local ch_rate to  eng_stats[2].
	local v_e to  eng_stats[3].
	local M to SHIP:MASS.
	local v_burn to SHIP:VELOCITY:SURFACE:MAG.

	local t to get_burn_t(v_burn).
	local stop_distance to v_burn*t - (v_e*(t - M/ch_rate) *ln(M/(M-t*ch_rate)) + v_e*t) .

	// wait until its time to start
	wait until (SHIP:POSITION - target_spot:ALTITUDEPOSITION(SHIP:ALTITUDE)):MAG <= (stop_distance + 40).

	local tset to 1.
	lock throttle to tset.

	local done to false.
	local max_acc is 0.
	
	until done
	{
		//recalculate current max_acceleration, as it changes while we burn through fuel
		set max_acc to ship:maxthrust/ship:mass.

		//throttle is 100% until there is less than 1 second of time left to burn
		//when there is less than 1 second - decrease the throttle linearly
		set tset to min(SHIP:GROUNDSPEED/max_acc, 1).
		//we have very little left to burn
		if (SHIP:GROUNDSPEED) < 1 {

			unlock steering.
			wait 1.
			lock throttle to 0.
			print "End burn, remain speed  " + round(burn_vector:MAG,1) + "m/s".
			set done to True.
		}
	}
	//we no longer need the maneuver node
	lOCK STEERING to SHIP:RETROGRADE.
	RCS off.
	wait 3.
	remove nd.
	print "Vessel Stopped".

	
	//set throttle to 0 just in case.
	set SHIP:CONTROL:PILOTMAINTHROTTLE to 0.
	unlock throttle.
}

function do_suecide_burn{
	parameter target_spot.

	gear off.
	gear on.

	RCS on.
	// we can compote our virtual starting height from a degenerated elliptic Orbit with semimajoraxis = r_start/2 and the vis-viva equation 
	local v_now to SHIP:VELOCITY:SURFACE:MAG.
	local r_now to SHIP:ALTITUDE + BODY:RADIUS.
	local mu to BODY:MU.
	local r_from to ((2*mu*r_now)/((2*mu) - (r_now * v_now^2))).

	local r_to to BODY:RADIUS + target_spot:TERRAINHEIGHT. // ALT:RADAR only works within 5000m. We need more.
	local burn_heigt to get_burn_height(r_from,r_to).	
	local full_burn_time to get_burn_t_ff(r_from,(BODY:RADIUS+burn_heigt)).

	
	// check for fuel: STAGE:OXIDIZER + STAGE:LIQUIDFUEL * 0.05 
	local engine_stats to get_engine_stats.
	local burn_rate to engine_stats[2].
	local fuel_in_stage to (STAGE:OXIDIZER + STAGE:LIQUIDFUEL) * 0.005.
	local t_burn_stage to fuel_in_stage/burn_rate.
	if t_burn_stage < full_burn_time {
		print "Not enough fuel in stage. using leftovers from this".
		local grav_mean to sqrt(((BODY:MU/(r_from^2))^2 + (BODY:MU/(r_to^2))^2) /2) .
		local stopping_power to engine_stats[3]*ln(SHIP:MASS/(SHIP:MASS-fuel_in_stage)) - t_burn_stage*grav_mean.
		lock steering to (-1* (SHIP:VELOCITY:SURFACE) ).
		wait until SHIP:VELOCITY:SURFACE:MAG >= stopping_power.
		lock THROTTLE to 1.0.
		wait until SHIP:VELOCITY:SURFACE:MAG < 10.
		unlock steering.
		wait until STAGE:LIQUIDFUEL < 0.05.
		lock THROTTLE to 0.0.
		set r_from to SHIP:ALTITUDE+BODY:RADIUS.
		wait 0.01.
		stage.
		set burn_heigt to get_burn_height(r_from,r_to).
		set full_burn_time to get_burn_t_ff(r_from,(BODY:RADIUS+burn_heigt)).
	}

	// try to land exactly where we want to
	local lock dist to (SHIP:GEOPOSITION:POSITION - target_spot:POSITION)/(ship:maxthrust/ship:mass). 
	lock steering to (-1* (SHIP:VELOCITY:SURFACE + dist) ).
// use this for the challenge :-)
//	lock steering to (-1* (SHIP:VELOCITY:SURFACE) ).
	
	wait until SHIP:ALTITUDE < (burn_heigt+(SHIP:OBT:VELOCITY:SURFACE:MAG*10)).

	set r_to to BODY:RADIUS + SHIP:GEOPOSITION:TERRAINHEIGHT.
	set burn_heigt to get_burn_height(r_from,r_to).


	wait until SHIP:ALTITUDE < (burn_heigt+(SHIP:OBT:VELOCITY:SURFACE:MAG*3)).
	set r_to to BODY:RADIUS + SHIP:GEOPOSITION:TERRAINHEIGHT.
	set burn_heigt to get_burn_height(r_from,r_to).
	
	global do_trigger to true.
		// set up trigger; stop deaccelerating when we are below 4m/s
	when do_trigger AND  SHIP:OBT:VELOCITY:SURFACE:MAG < 4 AND NOT (SHIP:STATUS = "LANDED") then {
		local lock my_grav to BODY:MU/((BODY:RADIUS+ SHIP:ALTITUDE)^2).
		local my_thrust to (get_engine_stats())[0].
		local lock t_set to SHIP:MASS*my_grav/my_thrust.
		print "t_set:   " + round(t_set,2).
		lock THROTTLE to t_set.
		unlock steering.
		RCS on.
		SAS on.
	}

	// reduce the speed to zero
	when do_trigger AND ALT:RADAR < 100 then {
		lock steering to (-1*SHIP:VELOCITY:SURFACE ).
	}
		
	print "trigger setup complete, start burn in 3s".
	// start the burn.
	wait until SHIP:ALTITUDE < burn_heigt.
	lock THROTTLE to 1.0.

	wait until ((ALT:RADAR < 0.5) OR (SHIP:STATUS = "LANDED") OR (SHIP:OBT:VELOCITY:SURFACE:MAG < 1.0)).
	
	lock THROTTLE to 0.
	unlock steering.
	set do_trigger to false.
	SAS on.
	RCS on.
	wait until SHIP:STATUS = "LANDED".
	wait 10.
	SAS off.
	RCS off.
}


// unused Code
//local q is r_to/r_from.
//local time_to_impact is sqrt(r_from^3/(2*BODY:MU)) * (sqrt(q*(1-q)) + (Constant:DegToRad*arccos(sqrt(q)))).
//print "time_to_impact:  " + round(time_to_impact,1). 
//
