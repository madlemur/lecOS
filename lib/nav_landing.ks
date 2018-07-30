@LAZYGLOBAL OFF.
pout("LEC NAV_LANDING v%VERSION_NUMBER%").
{
    local self is lex(
        "setTarget", setTarget@,
        "setLandingNode", setLandingNode@,
        "spotLand", spotLand@
    ).

    local tgtLoc is 0.

    function setTarget {
        PARAMETER tgt is TARGET.
        if tgt:isType("Orbital") or tgt:isType("Waypoint") {
            set tgtLoc to tgt:geoposition.
        } else if tgt:isType("Part") {
            set tgtLoc to tgt:ship:geoposition.
        } else if tgt:isType("List") {
            set tgtLoc to latlng(tgt[0], tgt[1]).
        } else if tgt:isType("GeoCoordinates") {
            set tgtLoc to tgt.
        } else {
            return false.
        }
        return tgtLoc.
    }

    function ETA_to_theta {

    	parameter theta_test.

    	local orbit_test is ship:orbit.
    	local mnv_time is 0.

    	if HASNODE {
    		set orbit_test to nextnode:orbit.
    		set mnv_time to nextnode:eta.
    	}

    	local T_orbit is orbit_test:period.
    	local theta_ship is orbit_test:trueanomaly.
    	local ecc is orbit_test:eccentricity.
    	local GM is ship:body:mu.
    	local a is orbit_test:semimajoraxis.
    	//clearscreen.

    	local EA_ship is 2*ARCTAN((TAN(theta_ship/2))/sqrt((1+ecc)/(1-ecc))).
    	local MA_ship is EA_ship*constant:pi/180 - e*SIN(EA_ship).
    	local EA_test is 2*ARCTAN((TAN(theta_test/2))/sqrt((1+ecc)/(1-ecc))).
    	local MA_test is EA_test*constant:pi/180 - ecc*SIN(EA_test).
    	local n is sqrt(GM/(a)^3).
    	local eta_to_testpoint is (MA_test - MA_ship)/n.
    	if eta_to_testpoint < 0 {
    		set eta_to_testpoint to T_orbit + eta_to_testpoint.
    	}

    //	print "ETA to " + round(theta_test,2) + " degrees True Anomaly is " + round(eta_to_testpoint,2) + " seconds".
    //	wait 2.
    	return eta_to_testpoint.
    }

    function Vec_To_Node {
    	parameter des_vec, mnv_time.

    	local vel_vec is velocityat(ship,time:seconds + mnv_time):orbit.

    	local norm_vec is vcrs(ship:body:position,ship:velocity:orbit):normalized.
    	local prog_vec is vel_vec:normalized.
    	local radi_vec is VCRS(norm_vec,prog_vec).

    	local burn_vec is des_vec - vel_vec.

    	local norm_comp is VDOT(norm_vec,burn_vec).
    	local prog_comp is VDOT(prog_vec,burn_vec).
    	local radi_comp is VDOT(radi_vec,burn_vec).

    	local mynode is NODE(time:seconds + mnv_time,radi_comp,norm_comp,prog_comp).
    	add mynode.
    }

    function Des_Peri_RadialBurn {
    	parameter des_peri.

    	local sma is ship:orbit:Semimajoraxis.
    	local u is ship:body:mu.
    	local V0 is ship:velocity:orbit:mag.
    	local R is ship:body:position:mag.
    	local Rp is des_peri + ship:body:radius.
    	local Ra is 2*sma - Rp.
    	local e is (Ra - Rp)/(Ra + Rp).
    	local A is sqrt(sma*u*(1-e^2)).
    	local B is V0*R.
    	local rad_des is ARCCOS(A/B).

    	return rad_des.
    }

    function Set_Landing_Orbit_vec {
    	parameter des_inc, des_peri, mnv_time.

    	local vel_vec is velocityat(ship,time:seconds + mnv_time):orbit.
    	local pos_vec is positionat(ship,time:seconds + mnv_time).
    	local body_vec is pos_vec - ship:body:position.

    	local angle_rotate_inc is ANGLEAXIS(des_inc,-body_vec).
    	local new_vel_vec is vel_vec*angle_rotate_inc.
    	local new_norm is VCRS(body_vec,new_vel_vec).
    	local rad_des is Des_Peri_RadialBurn(landing_peri).

    	local angle_rotate_rad is ANGLEAXIS(rad_des,new_norm).
    	set new_vel_vec to new_vel_vec*angle_rotate_rad.

    	return new_vel_vec.
    }

    function setLandingNode {
        parameter landing_peri is 20000.
        parameter time_test is 30.
        if not tgtLoc:isType("GeoCoordinates") {
            pout("Target not set for landing.").
            return false.
        }
        if ship:orbit:eccentricity > 0.001 {
            pout("Orbit is too eccentric, please circularize.").
            return false.
        }
        if abs(ship:orbit:inclination) > 0.001 {
            pout("Orbit is too inclined, please equitorialize.").
            return false.
        }
        local landing_vec to Set_Landing_Orbit_vec(tgtLoc:LAT,landing_peri,time_test).

        Vec_To_Node(landing_vec,time_test).

        local peri_time is ETA_to_theta(0).
        local peri_pos is positionat(ship,time:seconds + peri_time).
        local long_offset is 360*(peri_time)/ship:body:rotationperiod.
        local peri_ltlng_pre is ship:body:GEOPOSITIONOF(peri_pos).
        local peri_ltlng is LATLNG(peri_ltlng_pre:LAT, peri_ltlng_pre:LNG + long_offset).
        local long_diff is target_ltlng:LNG - peri_ltlng:LNG.

        local period_diff is 1/ship:orbit:period - 1/ship:body:rotationperiod.
        local long_fix is (long_diff/360)/period_diff.

        set time_test to time_test + long_fix.
        remove nextnode.
        set landing_vec to Set_Landing_Orbit_vec(target_ltlng:LAT,landing_peri,time_test).
        Vec_To_Node(landing_vec,time_test).
        return true.
    }
    function Hysteresis {
        declare parameter input,prev_output, right_hand_limit, left_hand_limit,right_hand_output is true.
        set output to prev_output.
        if prev_output = right_hand_output {
            if input <= left_hand_limit {
                set output to not(right_hand_output).
            }
        } else {
            if input >= right_hand_limit {
                set output to right_hand_output.
            }
        }
        return output.
    }

    function Vmax_v {
        declare parameter buffer_terrain is 0, TouchDownSpeed is 5.
        local true_alt to altitude - ship:geoposition:terrainheight.
        local V to ship:velocity:orbit.
        local R to ship:body:position.
        local Vper to VDOT(VCRS(R,VCRS(V,R)):normalized,V).
        local AccelCent to (Vper^2)/R:mag.
        local MaxThrustAccUp to availablethrust/mass.
        local GravUp to (-1)*(ship:body:mu)/((R:mag)^2).
        local MaxAccUp to MaxThrustAccUp + GravUp + AccelCent.
        local FPAsurf to 90 - VANG(UP:vector,ship:velocity:surface).
        local Vmax to sqrt(MAX(0,2*(true_alt - buffer_terrain)*MaxAccUp - TouchDownSpeed^2)).
        return Vmax.
    }

    function Vmax_h {
        parameter  buffer_dist is 0.
        local R is ship:body:position.
        local V is ship:velocity:orbit.
        local MaxThrustAccHor is availablethrust/mass.
        local angle_diff_h is VANG(-R, landing_pos:position - R).
        local dist_diff_h is (angle_diff_h/360)*2*(constant:pi)*R:mag.
        local Vmax is sqrt(MAX(0.001,2*(dist_diff_h - buffer_dist)*MaxThrustAccHor)).

        local dir_check_vel is VCRS(V,R).
        local dir_check_pos is VCRS(-R,landing_pos:position-R).
        local dir_check is 1.
        if VDOT(dir_check_vel,dir_check_pos) > 0 {
            set dir_check to 1.
        } else {
            set dir_check to -1.
        }

        return dir_check*Vmax.
    }

    function Follow_throttle_func {
        local R is ship:body:position.
        local V is ship:velocity:surface.
        local V_ref is (V:mag)*(landing_pos:position:normalized).
        local h is altitude - landing_pos:terrainheight. // used to adjust the V_ref later
        local V_diff is V_ref - V.
        local throttle_sel is (V_diff*mass)/availablethrust.

        return throttle_sel.
    }

    function S_throttle_func {
        parameter t_0 is 1.
        local R is ship:body:position.
        local V is ship:velocity:surface.
        local S is V:mag.
        local V_side is VCRS(V,R):normalized.
        local V_per is VCRS(R,V_side):normalized.
        local T_vec is VCRS(R,VCRS(landing_pos:position,R)):normalized.
        local delta_v is -1*VDOT(V_side,(T_vec*S - V_per*S)).

        return delta_v.
    }

    function spotLand {
        // Script to do a spot landing
        local max_acc is maxthrust/mass.
        local peri_v is velocityat(ship,time:seconds + eta:periapsis):orbit:mag.
        local delta_time is peri_v/max_acc.

        __["warpUntil"](time:seconds + eta:periapsis - 2*delta_time).


        lock R to ship:body:position.
        lock V_surf to ship:velocity:surface.
        lock g to ship:body:mu/(R:mag^2).
        lock Velocity_h_norm to VCRS(VCRS(R,landing_pos:position),R):normalized.
        lock Speed_h to VDOT(Velocity_h_norm,ship:velocity:surface).
        lock speed_diff_h to Speed_h-landing_pos:altitudevelocity(altitude):orbit:mag.
        lock true_alt to altitude - ship:geoposition:terrainheight.

        lock V_vec to UP:vector.
        lock H_vec to VCRS(R,VCRS(V_surf,R)):normalized.
        lock S_vec to -1*VCRS(V_surf,R):normalized.

        set KP_V to .01.
        set KD_V to 0.005.
        set V_throttle_PID to PIDLOOP(KP_V,0,KD_V,0,1).
        set V_throttle_PID:setpoint to Vmax_v().

        set KP_H to .01.
        set KD_H to 0.002.//0.02.
        set H_throttle_PID to PIDLOOP(KP_H,0,KD_H,-1,1).
        set H_throttle_PID:setpoint to Vmax_h().

        set KS to 1/5. // Time constant
        set S_throttle to S_throttle_func(2).

        set throttle_vec to V_vec*V_throttle_PID:update(time:seconds,-1*verticalspeed) + H_vec*H_throttle_PID:update(time:seconds,Speed_h) + S_vec*S_throttle.

        lock steering to throttle_vec:direction.

        lock land_surf to VANG(landing_pos:position,ship:velocity:surface).

        clearscreen.

        set touchdown_speed to -5.
        set alt_cutoff to 100.

        set throttle_hyst to false.
        set throttle_hyst_UL to 25.
        set throttle_hyst_LL to 1.

        set ang_hyst to false.
        set ang_hyst_UL to 50.
        set ang_hyst_LL to 10.

        set left_over_flag to false.
        set Follow_Mode to false.
        set TouchDown_Mode to false.

        set LandingVector to VECDRAW((alt:radar)*(landing_pos:position - R):normalized,landing_pos:position,GREEN,"Landing Position",1.0,TRUE,.5).
        set LandingVector:vectorupdater to { return (altitude-landing_pos:terrainheight)*(landing_pos:position - R):normalized.}.
        set LandingVector:startupdater to { return landing_pos:position.}.

        set LandingPositionVector to VECDRAW(V(0,0,0),landing_pos:position,RED,"Landing Vector",1.0,TRUE,.5).
        set LandingPositionVector:vectorupdater to { return landing_pos:position.}.
        set LandingPositionVector:startupdater to { return V(0,0,0).}.

        set SurfaceVelocity to VECDRAW(V(0,0,0),ship:velocity:surface,BLUE,"Surface Velocity",1.0,TRUE,.5).
        set SurfaceVelocity:vectorupdater to { return ship:velocity:surface.}.
        set SurfaceVelocity:startupdater to { return V(0,0,0).}.

        local telemetry is gui(200).

        local th_box is telemetry:addvbox().

        local vthrot is th_box:addhlayout().
        local hthrot is th_box:addhlayout().
        local sthrot is th_box:addhlayout().

        local vth1 is vthrot:addlabel().
        set vth1:text to "V_throttle = ".
        local vth2 is vthrot:addLabel().

        local hth1 is hthrot:addlabel().
        set hth1:text to "H_throttle = ".
        local hth2 is hthrot:addLabel().

        local sth1 is sthrot:addlabel().
        set sth1:text to "S_throttle = ".
        local sth2 is sthrot:addLabel().

        telemetry:show().

        until ship:status = "LANDED" {


        	set V_throttle_PID:setpoint to Vmax_v().
        	set H_throttle_PID:setpoint to Vmax_h().
        	if verticalspeed > touchdown_speed AND true_alt < alt_cutoff AND not(TouchDown_Mode){
        		set TouchDown_Mode to True.
        	}

        	if TouchDown_Mode{
        		set V_throttle to (1-(touchdown_speed-verticalspeed)/touchdown_speed)*mass*g/availablethrust.
        		GEAR ON.
        	} else {
        		set V_throttle to MIN(1,1-V_throttle_PID:update(time:seconds,-1*verticalspeed)).
        		GEAR OFF.
        	}

        	set H_throttle_test to MIN(1,1-H_throttle_PID:update(time:seconds,Speed_h)).
        	//set H_throttle_test to H_throttle_func().

        	set S_deltaV to S_throttle_func().
        	if throttle_hyst {
        		set S_throttle_enable to true.
        		set S_throttle_test to (S_deltaV*mass)/(availablethrust*1).
        	} else {
        		set S_throttle_enable to false.
        		set S_throttle_test to 0.
        	}

        	if (V_throttle^2 + H_throttle_test^2 + S_throttle_test^2) > 1 {
        		set left_over_flag to True.
        		set left_over to 1- V_throttle^2.
        		if H_throttle_test > sqrt(left_over) {
        			set H_throttle to MAX(0,MIN(H_throttle_test,sqrt(left_over))).
        			set S_throttle to 0.
        		} else {
        			set H_throttle to H_throttle_test.
        			set S_throttle to MAX(0,MIN(S_throttle_test,sqrt(left_over - H_throttle_test^2))).
        		}
        	} else {
        		set left_over_flag to False.
        		set S_throttle to S_throttle_test.
        		set H_throttle to H_throttle_test.
        	}
        	set Follow_Mode_Ang to VANG(landing_pos:position,ship:velocity:surface).
        	if Follow_Mode_Ang <15 {
        		set Follow_Mode to True.
        	}
        	if groundspeed < 10 AND not(Follow_Mode) {
        		set Follow_Mode to True.
        	}

        	if Follow_Mode {
        		set throttle_vec to V_vec*V_throttle + Follow_throttle_func().
        	} else {
        		set throttle_vec to V_vec*V_throttle - H_vec*H_throttle + S_vec*S_throttle.
        	}

        	set throttle_hyst_test to throttle_vec:mag.
        	set ang_diff to VANG(throttle_vec,ship:facing:vector).
        	set throttle_hyst to Hysteresis(100*throttle_hyst_test,throttle_hyst, throttle_hyst_UL, throttle_hyst_LL).
        	set ang_hyst to Hysteresis(ang_diff,ang_hyst,ang_hyst_UL,ang_hyst_LL,False).

        	if throttle_hyst {
        		if ang_hyst {
        			lock throttle to throttle_vec:mag.
        			lock steering to LOOKDIRUP(throttle_vec,facing:topvector).
        		} else {
        			lock throttle to 0.
        			lock steering to LOOKDIRUP(throttle_vec,facing:topvector).
        		}
        	} else {
        		lock throttle to 0.
        		lock steering to LOOKDIRUP(srfretrograde:vector,facing:topvector).
        	}

            set vth2:text to round(100*(VDOT(V_vec,throttle_vec)),0) + "%".
            set hth2:text to round(100*(VDOT(H_vec,throttle_vec)),0) + "%".
            set sth2:text to round(100*(VDOT(S_vec,throttle_vec)),0) + "%".
        	print "Vmax_v = " +round(Vmax_v,2) at(0,3).
        	print "Vspeed = " +round(verticalspeed,2) at(0,4).
        	print "Vmax_h = " +round(Vmax_h,2) at(0,5).
        	print "Vspeed_h = " +round(Speed_h,2) at(0,6).
        	print "Longitude = " +round(ship:geoposition:lng,2) at(0,7).
        	print "Throttle = " + round(100*throttle_vec:mag,0) + "%   " at(0,8).
        	print "throttle_hyst = " + throttle_hyst + "   " at(0,9).
        	print "left_over_flag = " + left_over_flag + "   " at(0,10).
        	print "ang_diff = " + round(ang_diff,1) + "   " at(0,11).
        	print "ang_hyst = " + ang_hyst + "   " at(0,12).
        	print "S_deltaV = " + round(S_deltaV,2) + "   " at(0,13).
        	print "groundspeed = " + round(groundspeed,2) + "   " at(0,14).
        	print "land_surf = " + round(land_surf,2) + "   " at(0,15).
        	print "Follow_Mode = " + Follow_Mode + "   " at(0,16).
        	print "TouchDown_Mode = " + TouchDown_Mode + "   " at(0,17).
        	print "S_throttle_enable = " + S_throttle_enable + "   " at(0,18).
        	print "S_throttle_test = " + round(S_throttle_test,2) + "   " at(0,19).
        	print "throttle_hyst_test = " + round(throttle_hyst_test,2) + "   " at(0,20).


        	wait 0.
        }
        lock throttle to 0.
        SAS ON.
        wait 5.
        telemetry:hide().
    }

    export(self).
}
