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
