@LAZYGLOBAL OFF.

function stop_at_nc{
	parameter spot.

	local spot_lng to mod(360+Body:ROTATIONANGLE+spot:LNG,360).
	local ship_ref to mod(obt:lan+obt:argumentofperiapsis+obt:trueanomaly,360).

	// this is our time for one surface period
	local srf_period to ((1/SHIP:ORBIT:PERIOD) - (1/Body:ROTATIONPERIOD))^(-1).

	local time_2_spot to mod((720 + spot_lng - ship_ref),360) * srf_period/360 .
	print "time_2_spot : " + round (time_2_spot,2).

	// we travel to target and wait a half orbit and the offset is the difference of one orbit.
	local node_eta to time_2_spot + SHIP:ORBIT:PERIOD/2 + (srf_period - SHIP:ORBIT:PERIOD).

	local target_alt to spot:TERRAINHEIGHT/1000 + 0.615.

	set_altitude(node_eta,target_alt).
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
