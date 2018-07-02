@LAZYGLOBAL OFF.
PRINT("LEC RENDEZVOUS v%VERSION_NUMBER%").
{
    local self is lex(
      "setTarget", setTarget@,
      "matchPlaneManeuver", matchPlaneManeuver@,
      "nextTransferManeuver", nextTransferManeuver@,
      "matchVelocityManeuver", matchVelocityManeuver@
    ).
    local tgt is false.
    local tgt_off is 0.

    function setTarget {
        PARAMETER t.
        PARAMETER offset is 0. // degrees ahead of target in orbit
        set tgt to t.
        set tgt_off to offset.
    }

    function matchPlaneManeuver {
        PARAMETER err is 0.05.
        if err = 0 set err to 0.001.
        if abs(ship:orbit:inclination - tgt:orbit:inclination) < err return list(0,0,0,0).

        // Match inclinations with target by planning a burn at the ascending or
        // descending node, whichever comes first.
        //
        // stolen from http://pastebin.com/fq3nqj2p
        // as linked-to by http://www.reddit.com/r/kos/comments/2zehw6/help_calculating_time_to_andn/


        local t0 is time:seconds.
        local ship_orbit_normal is vcrs(ship:velocity:orbit,positionat(ship,t0)-ship:body:position).
        local target_orbit_normal is vcrs(tgt:velocity:orbit,tgt:position-ship:body:position).
        local lineofnodes is vcrs(ship_orbit_normal,target_orbit_normal).
        local angle_to_node is vang(positionat(ship,t0)-ship:body:position,lineofnodes).
        local angle_to_node2 is vang(positionat(ship,t0+5)-ship:body:position,lineofnodes).
        local angle_to_opposite_node is vang(positionat(ship,t0)-ship:body:position,-1*lineofnodes).
        local relative_inclination is vang(ship_orbit_normal,target_orbit_normal).
        local angle_to_node_delta is angle_to_node2-angle_to_node.

        local ship_orbital_angular_vel is 360 / ship:obt:period.
        local time_to_node is angle_to_node / ship_orbital_angular_vel.
        local time_to_opposite_node is angle_to_opposite_node / ship_orbital_angular_vel.

        // the nearest node might be in the past, in which case we want the opposite
        // node. test this by looking at our angular velocity w/r/t the node. There's
        // probably a more straightforward way to do this...
        local t is 0.
        if angle_to_node_delta < 0 {
        	set t to (time + time_to_node):seconds.
        } else {
        	set t to (time + time_to_opposite_node):seconds.
        }

        local v is velocityat(ship, t):orbit.
        local vt is velocityat(tgt, t):orbit.
        local diff is vt - v.
        local nDv is v:mag * sin(relative_inclination).
        local pDV is v:mag * (cos(relative_inclination) - 1 ).
        local dv is 2 * v:mag * sin(relative_inclination / 2).

        // Now we have almost all the variables to burn. We just don't know which way to burn yet
        // If the target ship (or body) is ahead of our ship less than 180 degrees at the node (that we dont know if is ascending or descending) and it's position vector dot product our normal orbit vector is positive, that means that we must burn normal to reach that plane. If the dot product is negative it means we need to burn anti-normal to reach that plane.
        // Also if the target ship is ahead more than 180 degress (or behind) the situation is inverse. Setting the normal delta v to a negative value takes care of it.

        set tFuturePos to positionat(tgt,t).
        set sFutureVel to velocityat(ship,t):orbit.

        if vdot(sFutureVel,tFuturePos) < 0 set nDv to -nDv.
        if vdot(ship_orbit_normal,tFuturePos) < 0 set nDv to -nDv.

        return list(t, 0, ndv, pDv).

    }

    function nextTransferManeuver {
        PARAMETER maxorb=10.
        local currTA is SHIP:ORBIT:TRUEANOMALY.
        local currEcc is SHIP:ORBIT:ECCENTRICITY.
        if currEcc > 0.01 {
            pout("Current orbit too eccentric, circularize first.").
            return false.
        }
        if SHIP:ORBIT:APOAPSIS > TGT:ORBIT:PERIAPSIS {
            pout("Current orbit must be wholly within the target orbit, lower the orbital altitude.").
            return false.
        }
        local currEA is 2 * arctan( sqrt((1-currEcc)/(1+currEcc)) * tan(currTA/2)).
        local currRAD is SQRT(SHIP:ORBIT:SEMIMAJORAXIS * SHIP:ORBIT:SEMIMINORAXIS).

        local tgtTA is TGT:ORBIT:TRUEANOMALY.
        local tgtEcc is TGT:ORBIT:ECCENTRICITY.
        local tgtSM is TGT:ORBIT:SEMIMAJORAXIS.
        local tgtEA is 2 * arctan( sqrt((1-tgtEcc)/(1+tgtEcc)) * tan(tgtTA/2)).
        local alpha is { parameter k. return arccos(((2 - 2*tgtEcc^2)/(k*(2-k)))-1). }.
        local beta is { parameter k. return arccos(tgtEcc/k - 1/k*tgtEcc + 1/tgtEcc). }.
        local intSM is { parameter k. local a is alpha(k). return ((tgtSM^2 * k^2 * cos(a) + tgtSM^2 * k^2 - 2 * currRAD^2)/(2*tgtSM*k*cos(a) + 2*tgtSM*k - 4*currRAD)). }.
        local theta is { parameter k. local ism is intSM(k). return arccos((ism * currSM * k - 2 * currSM * currRAD + currRAD^2)/(ism * currSM * k - ism * k * currRAD)). }.
        local intLongPeri is { parameter k. parameter prePeri is false. if prePeri {return return beta(k) - theta(k). } else { return -(beta(k) -theta(k)). } }.
        local intEcc is { parameter k. return 1 - currRAD/intSM(k). }.
        local intEA is { parameter k. parameter prePeri is false. local ecc is intEcc(k). local f is 0. if prePeri { set f to 180 + theta(k). } else { set f to 180 - theta(k). } return arccos((ecc + cos(f))/(1+ecc*cos(f))). }.
        local arrival is { parameter k. parameter prePeri is false. return (((intSM(k)^(3/2)) * ( (intEA(k, prePeri) - intEcc(k) * sin(intEA(k, prePeri)))/180)). }.
        local departure is { parameter k. parameter prePeri is false. return ((__["mAngle"](intLongPeri(k, prePeri) - currTA)/360 * SHIP:ORBIT:PERIOD). }.
        local intV is { parameter k. return sqrt( BODY:MU * ((2/(k*tgtSM)) - 1/intSM(k))). }.
        local intVi is { parameter k. return sqrt(BODY:MU/currRAD). }.
        local tgtV is { parameter k. return sqrt( BODY:MU * ((2/(k*tgtSM)) - 1/tgtSM)). }.
        local intDv is { parameter k. return intVi(k) - 360 * sqrt( (2/currRAD) - (1/currRAD)). }.
        local tgtTAint is {
            parameter k.
            parameter prePeri is false.
            local t is arrival(k, prePeri).
            local b is sqrt(body:mu/tgtSM^3) * t.
            local c is 6 - 6 * tgtEcc.
            local d is -6 * b.
            local delta_root is sqrt(d^2 + (4*c^3)/27).
            local x is ((-d -delta_root)/2)^(1/3) + ((-d + delta_root)/2)^(1/3).

            local p is a/6.
            local q1 is (tgtEcc*x)/2.
            local s is -x * (tgtEcc + 1).
            local v_in1 is (-(b^3)/(27*a^3))+((b*c)/(6*a^2))-(d/(2*a)).
            local v_in2 is v_in1^2 + ((c/(3*a)) - (b^2/9*a^2))^3.
            return (v_in1 + sqrt(v_in2))^(1/3) + (v_in1 - sqrt(v_in2))^(1/3) - b/(3*a).
        }
        local fitness is {
            parameter k.
            parameter prePeri is false.
            local intA is theta(k).
            local tgtA is tgtTAint(k, prePeri).
            return ABS(intA - tgtA).
        }

        local upperB is 1 + tgtEcc.
        local lowerB is 1 - tgtEcc.
        local minDeparture is 60.

        // compute next transfer maneuver to target orbit
        return list(10,0,0,0).
    }

    function matchVelocityManeuver {
        PARAMETER err is 1.
        if abs(ship:velocity:MAG - tgt:velocity:MAG) < err return list(0,0,0,0).
        /////////////////////////////////////////////////////////////////////////////
        // Match velocities at closest approach.
        /////////////////////////////////////////////////////////////////////////////
        // Bring the ship to a stop when it meets up with the target. The accuracy
        // of this program is limited; it'll get you into roughly the same orbit
        // as the target, but fine-tuning will be required if you want to
        // rendezvous.
        /////////////////////////////////////////////////////////////////////////////

        // Figure out some basics
        local T is utilClosestApproach(ship, tgt).
        local Vship is velocityat(ship, T):orbit.
        local Vtgt is velocityat(tgt, T):orbit.
        local Pship is positionat(ship, T) - body:position.
        local dv is Vtgt - Vship.

        // project dv onto the radial/normal/prograde direction vectors to convert it
        // from (X,Y,Z) into burn parameters. Estimate orbital directions by looking
        // at position and velocity of ship at T.
        local r is Pship:normalized.
        local p is Vship:normalized.
        local n is vcrs(r, p):normalized.
        local sr is vdot(dv, r).
        local sn is vdot(dv, n).
        local sp is vdot(dv, p).

        // figure out the ship's braking time
        local accel is ship:availablethrust / ship:mass.
        local dt is dv:mag / accel.

        // Time the burn so that we end thrusting just as we reach the point of closest
        // approach. Assumes the burn program will perform half of its burn before
        // T, half afterward
        return list(T-(dt/2), sr, sn, sp).
    }

    // Determine the time of ship1's closest approach to ship2.
    function utilClosestApproach {
      parameter ship1.
      parameter ship2.

      local Tmin is time:seconds.
      local Tmax is Tmin + 2 * max(ship1:orbit:period, ship2:orbit:period).
      local Rbest is (ship1:position - ship2:position):mag.
      local Tbest is 0.

      until Tmax - Tmin < 5 {
        local dt2 is (Tmax - Tmin) / 2.
        local Rl is utilCloseApproach(ship1, ship2, Tmin, Tmin + dt2).
        local Rh is utilCloseApproach(ship1, ship2, Tmin + dt2, Tmax).
        if Rl < Rh {
          set Tmax to Tmin + dt2.
        } else {
          set Tmin to Tmin + dt2.
        }
      }

      return (Tmax+Tmin) / 2.
    }

    export(self).
}
