@LAZYGLOBAL OFF.
pout("LEC ORBIT v%VERSION_NUMBER%").
{
    local self is lexicon(
        "matchOrbit", matchOrbit@
    ).
    local maneuver is import("lib/maneuver.ks", false).

    function Change_LAN_Inc {

    	parameter DesiredOrbit.
    	local body_pos is ship:body:position.
    	local INC_ship is ship:orbit:inclination.
    	local Rad is -body_pos.
    	local SMA_ship is ship:orbit:semimajoraxis.
    	local LAN_des is DesiredOrbit["LAN"].
        local LAN_rot is ANGLEAXIS(-LAN_des, ship:up:vector).
    	local LAN_VEC is (solarprimevector * SMA_ship) * LAN_rot.
    	local Inc_Rotate is ANGLEAXIS(-1 * DesiredOrbit["INC"], LAN_VEC).
    	local Inc_Normal is Inc_Rotate * (V(0,-1,0):direction).
    	local Inc_Normal is SMA_ship * Inc_Normal:vector.

    	local AngVel_ship is SMA_ship * VCRS(Rad,ship:velocity:orbit):normalized.

    	local LAN_relative_vec is SMA_ship*VCRS(AngVel_ship,Inc_Normal):normalized.

    	local LAN_relative_theta is FindTheta_Vec(LAN_relative_vec).
    	local LAN_eta is ETA_to_theta(LAN_relative_theta).
    	//local LAN_node to NODE( time:seconds + LAN_eta,0,0,0).
    	//add LAN_node.

    	local delta_inc is VANG(AngVel_ship,Inc_Normal).
    	local Vel_at_LAN is velocityat(ship,time:seconds + LAN_eta):orbit.
    	local temp_dir is Vel_at_LAN:direction.
    	local rotate_dir is ANGLEAXIS(delta_inc,LAN_relative_vec).
    	local vel_rotated is rotate_dir*temp_dir.
    	local New_Vel_at_LAN is (Vel_at_LAN:mag)*vel_rotated:vector.

    	local LAN_node is SetNode_BurnVector(time:seconds + LAN_eta,New_Vel_at_LAN).
        if LAN_node:burnvector:mag > 0.5 {
    	    add LAN_node.
    	}

    }

    function Change_AoP_PerApo {

    	parameter DesiredOrbit.
    	local body_pos is ship:body:position.
    	local INC_ship is ship:orbit:inclination.
    	local Rad is -body_pos.
    	local SMA_ship is ship:orbit:semimajoraxis.
    	local LAN_ship is ship:orbit:LAN.
    	local LAN_VEC is  solarprimevector * (SMA_ship) * ANGLEAXIS(-LAN_ship, ship:up:vector).
    	local AngVel_ship is SMA_ship*VCRS(Rad,ship:velocity:orbit):normalized.
    	local AOP_ship is ship:orbit:argumentofperiapsis.
    	local AoP_Rotate is ANGLEAXIS(DesiredOrbit["AOP"],AngVel_ship).
    	//local AoP_Rotate to ANGLEAXIS(AOP_ship,AngVel_ship).  // Used for debugging
    	local AoP_VEC is AoP_Rotate*(LAN_VEC:direction).
    	local AoP_VEC is SMA_ship*AoP_VEC:vector.

    	local AoP_theta is FindTheta_Vec(AoP_VEC).
    	local AoP_eta is ETA_to_theta(AoP_theta).
    	local AoP_timeat is time:seconds + AoP_eta.

    	Apoapsis_Set_TimeAt(AoP_timeat,DesiredOrbit).
        if NOT (orbit:transition = MANEUVER) {
    	    local New_Apo_time is time:seconds + eta:apoapsis.
    	    Periapsis_Set_TimeAt(New_Apo_time,DesiredOrbit).
    	}
    }

    function FindTheta_Vec {

    	parameter test_vector is -ship:body:position.

    	local body_pos is ship:body:position.
    	local Rad is -body_pos.
    	local AngVel_ship is VCRS(Rad,ship:velocity:orbit):normalized.
    	local theta_test is VANG(test_vector,Rad).
    	local cross_test is VCRS(Rad,test_vector):normalized.

    	local check_vec is cross_test + AngVel_ship.
    	local theta_ship is ship:orbit:trueanomaly.
    	local theta is theta_ship.

    	if check_vec:mag > 1 {
    		set theta to theta_ship + theta_test.
    	} else {
    		set theta to theta_ship - theta_test.
    	}

        set theta to mod(theta + 360, 360).

    	return theta.
    }

    function ETA_to_theta {

    	parameter theta_test.

    	local T_orbit is ship:orbit:period.
    	local theta_ship is ship:orbit:trueanomaly.
    	local ec is ship:orbit:eccentricity.
    	local GM is ship:body:mu.
    	local a is ship:orbit:semimajoraxis.

    	local EA_ship is 2*ARCTAN((TAN(theta_ship/2))/sqrt((1+ec)/(1-ec))).
    	local MA_ship is EA_ship*constant:pi/180 - ec*SIN(EA_ship).
    	local EA_test is 2*ARCTAN((TAN(theta_test/2))/sqrt((1+ec)/(1-ec))).
    	local MA_test is EA_test*constant:pi/180 - ec*SIN(EA_test).
    	local n is sqrt(GM/(a)^3).
    	local eta_to_testpoint is (MA_test - MA_ship)/n.
    	if eta_to_testpoint < 0 {
    		set eta_to_testpoint to T_orbit + eta_to_testpoint.
    	}

    //	print "ETA to " + round(theta_test,2) + " degrees True Anomaly is " + round(eta_to_testpoint,2) + " seconds".
    //	wait 2.
    	return eta_to_testpoint.
    }

    function Apoapsis_Set_TimeAt {
    	parameter AoP_timeat, DesiredOrbit.

    	local body_pos is ship:body:position.
    	local body_radius is ship:body:radius.
    	local Rad is -body_pos.
    	local SMA_ship is ship:orbit:semimajoraxis.
    	local AngVel_ship is SMA_ship*VCRS(Rad,ship:velocity:orbit):normalized.
    	local R_ap is body_radius + DesiredOrbit["APO"].
    	local R_aop_vec is positionat(ship,AoP_timeat) - body_pos.
    	local R_aop is R_aop_vec:mag.
    	local R_ap_vec is -1*R_ap*R_aop_vec:normalized.

    	local SMA_new is (R_ap + R_aop)/2.
    	local V_aop_speed is vis_via_speed(R_aop-body_radius,SMA_new).
    	local temp_vec is VCRS(AngVel_ship,R_aop_vec):normalized.
    	local V_aop_new_vec is V_aop_speed*temp_vec.

    	local APO_node is SetNode_BurnVector(AoP_timeat,V_aop_new_vec).
        if V_aop_new_vec:mag > 0.1 {
    	    add APO_node.
        }
    }

    function Periapsis_Set_TimeAt {
    	parameter New_Apo_time, DesiredOrbit.

    	local body_pos is ship:body:position.
    	local Rad is -body_pos.
    	local body_radius is ship:body:radius.
    	local R_per_new is DesiredOrbit["PER"] + body_radius.
    	local R_ap_new is positionat(ship,New_Apo_time) + Rad.
    	local SMA_new is (R_ap_new:mag + R_per_new)/2.
    	local V_ap_new_speed is vis_via_speed(R_ap_new:mag-body_radius,SMA_new).
    	local V_ap_current_speed is velocityat(ship,New_Apo_time):orbit:mag.

    	local delta_v_node is V_ap_new_speed - V_ap_current_speed.
    	local PER_node is node(New_Apo_time,0,0,delta_v_node).
        if delta_v_node:mag > 0.1 {
    	    add PER_node.
    	}
    }

    function vis_via_speed {
    	parameter Rad, a is ship:orbit:semimajoraxis.
    	local R_val is ship:body:radius + Rad.
    	return sqrt(ship:body:mu*(2/R_val - 1/a)).
    }

    function SetNode_BurnVector {
    	parameter timeat,V_New.

    	local V_timeat is velocityat(ship,timeat):orbit.

    	local node_normal_vec is vcrs(ship:body:position,ship:velocity:orbit):normalized.
    	local node_prograde_vec is V_timeat:normalized.
    	local node_radial_vec is VCRS(node_normal_vec,node_prograde_vec).

    	local burn_vector is (V_New - V_timeat).
    	local burn_prograde is VDOT(node_prograde_vec,burn_vector).
    	local burn_normal is VDOT(node_normal_vec,burn_vector).
    	local burn_radial is VDOT(node_radial_vec,burn_vector).

    	return NODE(timeat,burn_radial,burn_normal,burn_prograde).
    }


    function matchOrbit {
        parameter DesiredOrbit is lexicon("LAN",ship:orbit:LAN,"INC",ship:orbit:inclination,"AOP",ship:orbit:argumentofperiapsis,"PER",ship:orbit:periapsis,"APO",ship:orbit:apoapsis).
        if orbit:transition = MANEUVER { return false. }
        local LAN_ship is ship:orbit:LAN.
        local INC_ship is ship:orbit:inclination.
        local AOP_ship is ship:orbit:argumentofperiapsis.
        local PER_ship is ship:orbit:periapsis.
        local APO_ship is ship:orbit:apoapsis.
        local default_DesiredOrbit is lexicon("LAN",LAN_ship,"INC",INC_ship,"AOP",AOP_ship,"PER",PER_ship,"APO",APO_ship).
        for key in default_DesiredOrbit:keys {
            if not DesiredOrbit:haskey(key) { set DesiredOrbit[key] to default_DesiredOrbit[key]. }
        }
        pout(DesiredOrbit).
        local tolerance_angle is 0.01.
        local LAN_diff is abs(DesiredOrbit["LAN"] - LAN_ship).
        local INC_diff is abs(DesiredOrbit["INC"] - INC_ship).

        if  LAN_diff < tolerance_angle AND INC_diff < tolerance_angle {

        	pout("No Change to Inclination or LAN").

        } else {

        	if LAN_diff > tolerance_angle {
        		pout("LAN is above tolerance with a difference of " + round(LAN_diff,3) + " degrees").
        	}
        	if INC_diff > tolerance_angle {
        		pout("INC is above tolerance with a difference of " + round(INC_diff,3) + " degrees").
        	}
        	pout("Running Change_LAN_Inc").
        	Change_LAN_Inc(DesiredOrbit).
          if orbit:transition = MANEUVER { maneuver["orientCraft"](). return false. }
        }

        local AOP_diff is abs(AOP_ship - DesiredOrbit["AOP"]).
        local APO_diff is abs(APO_ship - DesiredOrbit["APO"]).
        local PER_diff is abs(PER_ship - DesiredOrbit["PER"]).

        local AOP_diff_percent is 100*(1 - AOP_diff/DesiredOrbit["AOP"]).
        local APO_diff_percent is 100*(APO_diff/DesiredOrbit["APO"]).
        local PER_diff_percent is 100*(PER_diff/DesiredOrbit["PER"]).

        local tolerance_percent is 0.05.

        if AOP_diff_percent < tolerance_percent AND APO_diff_percent < tolerance_percent AND PER_diff_percent < tolerance_percent {

        	pout("No Change to Argument of Periapsis, Apoapsis, or Periapsis").

        } else {

        	if AOP_diff_percent > tolerance_percent {
        		pout("AoP is above tolerance with a difference of " + round(AOP_diff,3) + "%").
        	}
        	if APO_diff_percent > tolerance_percent {
        		pout("Apoapsis is above tolerance with a difference of " + round(APO_diff_percent,3) + "%").
        	}
        	if PER_diff_percent > tolerance_percent {
        		pout("Periapsis is above tolerance with a difference of " + round(PER_diff_percent,3) + "%").
        	}

        	pout("Running Change_AoP_PerApo").
        	Change_AoP_PerApo(DesiredOrbit).
        	if orbit:transition = MANEUVER { maneuver["orientCraft"](). return false. }
        }
        return true.
    }
    export(self).
}
