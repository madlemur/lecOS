//@LAZYGLOBAL OFF.
pout("LEC NAV_LANDING v%VERSION_NUMBER%").
{
    local self is lex(
        "setTarget", setTarget@,
        "getTarget", getTarget@,
        "hasTarget", hasTarget@,
        "setLandingNode", setLandingNode@,
        "spotLand", spotLand@
    ).

    local tgtLoc is 0.

    function hasTarget {
        return tgtLoc:isType("GeoCoordinates").
    }

    function getTarget {
        return tgtLoc.
    }

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
        local output is prev_output.
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
        local Ra to ship:body:position.
        local Vper to VDOT(VCRS(Ra,VCRS(V,Ra)):normalized,V).
        local AccelCent to (Vper^2)/Ra:mag.
        local MaxThrustAccUp to availablethrust/mass.
        local GravUp to (-1)*(ship:body:mu)/((Ra:mag)^2).
        local MaxAccUp to MaxThrustAccUp + GravUp + AccelCent.
        local FPAsurf to 90 - VANG(UP:vector,ship:velocity:surface).
        local Vmax to sqrt(MAX(0,2*(true_alt - buffer_terrain)*MaxAccUp - TouchDownSpeed^2)).
        return Vmax.
    }

    function Vmax_h {
        parameter  buffer_dist is 0.
        local Ra is ship:body:position.
        local V is ship:velocity:orbit.
        local MaxThrustAccHor is availablethrust/mass.
        local angle_diff_h is VANG(-Ra, tgtLoc:position - Ra).
        local dist_diff_h is (angle_diff_h/360)*2*(constant:pi)*Ra:mag.
        local Vmax is sqrt(MAX(0.001,2*(dist_diff_h - buffer_dist)*MaxThrustAccHor)).

        local dir_check_vel is VCRS(V,Ra).
        local dir_check_pos is VCRS(-Ra,tgtLoc:position-Ra).
        local dir_check is 1.
        if VDOT(dir_check_vel,dir_check_pos) > 0 {
            set dir_check to 1.
        } else {
            set dir_check to -1.
        }

        return dir_check*Vmax.
    }

    function Follow_throttle_func {
        local V is ship:velocity:surface.
        local V_ref is (V:mag)*(tgtLoc:position:normalized).
        local h is altitude - tgtLoc:terrainheight. // used to adjust the V_ref later
        local V_diff is V_ref - V.
        local throttle_sel is (V_diff*mass)/availablethrust.

        return throttle_sel.
    }

    function S_throttle_func {
        local Ra is ship:body:position.
        local V is ship:velocity:surface.
        local S is V:mag.
        local V_side is VCRS(V,Ra):normalized.
        local V_per is VCRS(Ra,V_side):normalized.
        local T_vec is VCRS(Ra,VCRS(tgtLoc:position,Ra)):normalized.
        local delta_v is -1*VDOT(V_side,(T_vec*S - V_per*S)).

        return delta_v.
    }

    local KP_V to .01.
    local KD_V to 0.005.
    local V_throttle_PID is 0.
    local V_throttle is 0.

    local KP_H to .01.
    local KD_H to 0.002.//0.02.
    local H_throttle_PID is 0.
    local H_throttle is 0.
    local H_throttle_test is 0.

    local telemetry_gui is 0.
    // local vth_g is 0.
    // local hth_g is 0.
    // local sth_g is 0.
    // local vxv_g is 0.
    // local vsv_g is 0.
    // local vxh_g is 0.
    // local vsh_g is 0.
    // local lon_g is 0.
    // local thr_g is 0.
    // local thh_g is 0.
    // local lof_g is 0.
    // local agd_g is 0.
    // local agf_g is 0.
    // local sdv_g is 0.
    // local gsp_g is 0.
    // local lsf_g is 0.
    // local flm_g is 0.
    // local tdm_g is 0.
    // local ste_g is 0.
    // local stt_g is 0.
    // local tht_g is 0.

    local steer_vec is 0.

    local touchdown_speed to -5.
    local alt_cutoff to 100.

    local throttle_hyst to false.
    local throttle_hyst_UL to 25.
    local throttle_hyst_LL to 1.

    local ang_hyst to false.
    local ang_hyst_UL to 50.
    local ang_hyst_LL to 10.

    local left_over_flag to false.
    local Follow_Mode to false.
    local TouchDown_Mode to false.

    // local LandingVector is 0.
    // local LandingPositionVector is 0.
    // local SurfaceVelocity is 0.

    function spotLand {
        // Script to do a spot landing
        local max_acc is maxthrust/mass.
        local peri_v is velocityat(ship,time:seconds + eta:periapsis):orbit:mag.
        local delta_time is peri_v/max_acc.

        __["warpUntil"](time:seconds + eta:periapsis - 2*delta_time).


        local Ra to ship:body:position.
        local V_surf to ship:velocity:surface.
        local gv to ship:body:mu/(Ra:mag^2).
        local Velocity_h_norm to VCRS(VCRS(Ra,tgtLoc:position),Ra):normalized.
        local Speed_h to VDOT(Velocity_h_norm,ship:velocity:surface).
        local speed_diff_h to Speed_h-tgtLoc:altitudevelocity(altitude):orbit:mag.
        local true_alt to altitude - ship:geoposition:terrainheight.

        local V_vec to UP:vector.
        local H_vec to VCRS(R,VCRS(V_surf,Ra)):normalized.
        local S_vec to -1*VCRS(V_surf,Ra):normalized.


        if NOT V_throttle_PID:isType("PIDLOOP") {
            set V_throttle_PID to PIDLOOP(KP_V,0,KD_V,0,1).
            set V_throttle_PID:setpoint to Vmax_v().
        }

        if NOT H_throttle_PID:isType("PIDLOOP") {
            set H_throttle_PID to PIDLOOP(KP_H,0,KD_H,-1,1).
            set H_throttle_PID:setpoint to Vmax_h().
        }

        local KS is 1/5. // Time constant
        local S_throttle to S_throttle_func().

        local throttle_vec to V_vec*V_throttle_PID:update(time:seconds,-1*verticalspeed) + H_vec*H_throttle_PID:update(time:seconds,Speed_h) + S_vec*S_throttle.

        if not steer_vec:isType("direction") {
            set steer_vec to throttle_vec:direction.
            lock steering to steer_vec.
        }
        set steer_vec to throttle_vec:direction.

        local land_surf is VANG(tgtLoc:position,ship:velocity:surface).

        if not telemetry_gui:isType("GUI") {
            set telemetry_gui to gui(400).
            local tel_box is telemetry_gui:addvbox().
            local th_box is tel_box:addvbox().

            local vth_g to th_box:addLabel("V_throttle = 0%").
            local hth_g to th_box:addlabel("H_throttle = 0%").
            local sth_g to th_box:addlabel("S_throttle = 0%").

            local tm_box is tel_box:addvbox().
            local vxv_g to tm_box:addLabel("Vmax_v = 0.00").
        	local vsv_g to tm_box:addLabel("Vspeed = 0.00").
        	local vxh_g to tm_box:addLabel("Vmax_h = 0.00").
        	local vsh_g to tm_box:addLabel("Vspeed = 0.00").
        	local lon_g to tm_box:addLabel("Longitude = 0.00").
        	local thr_g to tm_box:addLabel("Throttle = 0%").
        	local thh_g to tm_box:addLabel("throttle_hyst = false").
        	local lof_g to tm_box:addLabel("left_over_flag = false").
        	local agd_g to tm_box:addLabel("ang_diff = 0.00").
        	local agf_g to tm_box:addLabel("ang_hyst = false").
        	local sdv_g to tm_box:addLabel("S_deltaV = 0.00").
        	local gsp_g to tm_box:addLabel("groundspeed = 0.00").
        	local lsf_g to tm_box:addLabel("land_surf = 0.00").
        	local flm_g to tm_box:addLabel("Follow_Mode = false").
        	local tdm_g to tm_box:addLabel("TouchDown_Mode = false").
        	local ste_g to tm_box:addLabel("S_throttle_enable = false").
        	local stt_g to tm_box:addLabel("S_throttle_test = 0.00").
        	local tht_g to tm_box:addLabel("throttle_hyst_test = 0.00").

            telemetry_gui:show().

            local LandingVector to VECDRAW((alt:radar)*(tgtLoc:position - Ra):normalized,tgtLoc:position,GREEN,"Landing Position",1.0,TRUE,.5).
            set LandingVector:vectorupdater to { return (altitude-tgtLoc:terrainheight)*(tgtLoc:position - Ra):normalized. }.
            set LandingVector:startupdater to { return tgtLoc:position. }.

            local LandingPositionVector to VECDRAW(V(0,0,0),tgtLoc:position,RED,"Landing Vector",1.0,TRUE,.5).
            set LandingPositionVector:vectorupdater to { return tgtLoc:position. }.
            set LandingPositionVector:startupdater to { return V(0,0,0). }.

            local SurfaceVelocity to VECDRAW(V(0,0,0),ship:velocity:surface,BLUE,"Surface Velocity",1.0,TRUE,.5).
            set SurfaceVelocity:vectorupdater to { return ship:velocity:surface. }.
            set SurfaceVelocity:startupdater to { return V(0,0,0). }.

        }

    	set V_throttle_PID:setpoint to Vmax_v().
    	set H_throttle_PID:setpoint to Vmax_h().
    	if verticalspeed > touchdown_speed AND true_alt < alt_cutoff AND not(TouchDown_Mode){
    		set TouchDown_Mode to True.
    	}

    	if TouchDown_Mode{
    		set V_throttle to (1-(touchdown_speed-verticalspeed)/touchdown_speed)*mass*gv/availablethrust.
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
    	set Follow_Mode_Ang to VANG(tgtLoc:position,ship:velocity:surface).
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
    			set steer_vec to LOOKDIRUP(throttle_vec,facing:topvector).
    		} else {
    			lock throttle to 0.
    			set steer_vec to LOOKDIRUP(throttle_vec,facing:topvector).
    		}
    	} else {
    		lock throttle to 0.
    		set steer_vec to LOOKDIRUP(srfretrograde:vector,facing:topvector).
    	}

        set vth_g:text to "V_throttle = " + round(100*(VDOT(V_vec,throttle_vec)),0) + "%".
        set hth_g:text to "H_throttle = " + round(100*(VDOT(H_vec,throttle_vec)),0) + "%".
        set sth_g:text to "S_throttle = " + round(100*(VDOT(S_vec,throttle_vec)),0) + "%".
    	set vxv_g:text to "Vmax_v = " + round(Vmax_v,2).
    	set vsv_g:text to "Vspeed = " + round(verticalspeed,2).
    	set vxh_g:text to "Vmax_h = " + round(Vmax_h,2).
    	set vsh_g:text to "Vspeed_h = " + round(Speed_h,2).
    	set lon_g:text to "Longitude = " + round(ship:geoposition:lng,2).
    	set thr_g:text to "Throttle = " + round(100*throttle_vec:mag,0) + "%".
    	set thh_g:text to "throttle_hyst = " + throttle_hyst.
    	set lof_g:text to "left_over_flag = " + left_over_flag.
    	set agd_g:text to "ang_diff = " + round(ang_diff,1).
    	set agf_g:text to "ang_hyst = " + ang_hyst.
    	set sdv_g:text to "S_deltaV = " + round(S_deltaV,2).
    	set gsp_g:text to "groundspeed = " + round(groundspeed,2).
    	set lsf_g:text to "land_surf = " + round(land_surf,2).
    	set flm_g:text to "Follow_Mode = " + Follow_Mode.
    	set tdm_g:text to "TouchDown_Mode = " + TouchDown_Mode.
    	set ste_g:text to "S_throttle_enable = " + S_throttle_enable.
    	set stt_g:text to "S_throttle_test = " + round(S_throttle_test,2).
    	set tht_g:text to "throttle_hyst_test = " + round(throttle_hyst_test,2).

        if ship:status = "LANDED" {
            lock throttle to 0.
            SAS ON.
            wait 5.
            telemetry_gui:hide().
            CLEARVECDRAWS().
            return true.
        }

        return false.

    }

    export(self).
}
