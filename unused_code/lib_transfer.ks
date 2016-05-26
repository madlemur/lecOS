@LAZYGLOBAL OFF.

function hm_return {
	local target_periapsis is 37000.
	// we want a hohmann transfer down to kerbin.
	local r1 to (BODY:OBT:SEMIMAJORAXIS - 1.5*SHIP:OBT:SEMIMAJORAXIS).
	local r2 to (BODY:BODY:RADIUS + target_periapsis ).

	local dv_hx_kerbin is BODY:OBT:VELOCITY:ORBIT:MAG * (sqrt((2*r2)/(r1 + r2)) -1).
	local transfer_time to constant:pi * sqrt((((r1 + r2)^3)/(8*BODY:BODY:MU))).

	local r1 is SHIP:OBT:SEMIMAJORAXIS.
	local r2 is BODY:SOIRADIUS.
	local v2 is dv_hx_kerbin.
	local mu to BODY:MU.

	local ejection_vel is sqrt((r1*(r2*v2^2 - 2 * mu) + 2*r2*mu ) / (r1*r2) ).
	local delta_v to  abs(SHIP:OBT:VELOCITY:ORBIT:MAG-ejection_vel).

	local vel_vector is SHIP:VELOCITY:ORBIT:VEC.
	set vel_vector:MAG to (vel_vector:MAG + delta_v).
	local ship_pos_orbit_vector is SHIP:Position - BODY:Position.
	local angular_momentum_h is (vcrs(vel_vector,ship_pos_orbit_vector)):MAG.
	local spec_energy is ((vel_vector:MAG^2)/2) - (BODY:MU/SHIP:OBT:SEMIMAJORAXIS).
	local ecc is sqrt(1 + ((2*spec_energy*angular_momentum_h^2)/BODY:MU^2)).

	local launch_angle is arcsin(1/ecc).

	// This are the directions relative to the reference
	// prograde direction
	local body_orbit_direction is BODY:ORBIT:VELOCITY:ORBIT:DIRECTION:YAW.
	local ship_orbit_direction is SHIP:ORBIT:VELOCITY:ORBIT:DIRECTION:YAW.

	// launch point:
	local launch_point_dir is (body_orbit_direction - 180 + launch_angle).
	local node_eta is mod((360+ ship_orbit_direction - launch_point_dir),360)/360 * SHIP:OBT:PERIOD.

	local my_node to NODE(time:seconds + node_eta, 0, 0, delta_v).
	ADD my_node.

	// Fine tuning of dV.
	local lock current_peri to ORBITAT(SHIP,time+transfer_time):PERIAPSIS.

	until abs (current_peri - target_periapsis) < 300 {
		if current_peri < target_periapsis {
			set my_node:PROGRADE to my_node:PROGRADE - 0.05.
		} else {
			set my_node:PROGRADE to my_node:PROGRADE + 0.05.
		}
	}
}


// Hohmann Transfer to a Moon
function hm_trans {
	declare local parameter target,target_periapsis,pro_retro.
	set target_periapsis to target_periapsis*1000.

	local my_radius to SHIP:OBT:SEMIMAJORAXIS.
	// wen want to get into to soi but not into the planet target
	local tgt_radius to (target:OBT:SEMIMAJORAXIS - target:RADIUS   - target_periapsis -(target:SOIRADIUS/10) ).

	// Hohmann Transfer Time
	local transfer_time to constant():pi * sqrt((((my_radius + tgt_radius)^3)/(8*target:BODY:MU))).
	local phase_angle to (180*(1-(sqrt(((my_radius + tgt_radius)/(2*tgt_radius))^3)))).
	local actual_angle to mod(360 + target:LONGITUDE - SHIP:LONGITUDE,360) .
	local d_angle to (mod(360 + actual_angle - phase_angle,360)).

	local ship_ang to  360/SHIP:OBT:PERIOD.
	local tgt_ang to  360/TARGET:OBT:PERIOD.
	local d_ang to ship_ang - tgt_ang.
	local d_time to d_angle/d_ang.

	local my_dV to sqrt (target:BODY:MU/my_radius) * (sqrt((2* tgt_radius)/(my_radius + tgt_radius)) - 1).

	local my_node TO NODE(time:seconds+d_time, 0, 0, my_dV).
	ADD my_node.

	local tgt_incl to 0.
	// fine tune the orbit
	if (pro_retro:STARTSWITH("pro")) {
		set tgt_incl to -1. 
	} else {
		set tgt_incl to 90. 
	}
	local lock current_peri to ORBITAT(SHIP,time+transfer_time):PERIAPSIS.
	local lock current_inclination to ORBITAT(SHIP,time+transfer_time):INCLINATION.
	// We go higher, so we can set the new orbits with small retrograde burns at pe 
	set target_periapsis to target_periapsis+1000. 
	until (abs(current_peri - target_periapsis) < 1000)  AND (current_inclination > tgt_incl) {

		if current_inclination < 90 {
			if current_peri < target_periapsis  {
				set my_node:PROGRADE to my_node:PROGRADE - 0.0004.
			} else {
				set my_node:PROGRADE to my_node:PROGRADE + 0.0004.
			}
		} else {
			if current_peri > target_periapsis  {
				set my_node:PROGRADE to my_node:PROGRADE - 0.0004.
			} else {
				set my_node:PROGRADE to my_node:PROGRADE + 0.0004.
			}
		}		
	}	

}