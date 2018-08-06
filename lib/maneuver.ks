@LAZYGLOBAL OFF.
pout("LEC MANEUVER v%VERSION_NUMBER%").
{
  local self is lex (
      "orientCraft", orientCraft@,
      "isOriented", isOriented@,
      "nodeComplete", nodeComplete@
  ).
  local t is 0.
  local targetV is 0.
  local targetP is 0.
  local burnMag is 0.
  local staging is import("lib/staging.ks", false).
  local times is import("lib/time.ks", false).
  local timeout is 10.

  // Steering and throttle values
  local steervec is 0.
  local thrott is 0.

  local node_bestFacing is 1.   // ~1 degree error (2 degree cone)
  local node_okFacing   is 5.   // ~5 degrees error (10 degree cone)

  function orientCraft {
      parameter mnvNode is 0.
      if orbit:transition = MANEUVER { set mnvNode to nextnode. } else { return false. }
      set steervec to LOOKDIRUP(mnvNode:burnvector,facing:topvector).
      lock steering to steervec.
      lock throttle to thrott.
      return true.
    }

  function isOriented {
    parameter mnvNode is 0.
    if orbit:transition = MANEUVER { set mnvNode to nextnode. } else { return true. }
    local BurnTime is staging["burnTimeForDv"](mnvNode:deltav:mag)/2.
    if utilIsShipFacing(mnvNode:burnvector,node_bestFacing,0.5) or // Good aim.
        ((mnvNode:eta <= BurnTime and // Fair aim, and
          utilIsShipFacing(mnvNode:burnvector,node_okFacing,5)) or // we're running late!
        ship:angularvel:mag < 0.001 or // This fat tub isn't turning on it's own, so sure, we're facing as good as it's gonna get.
        mnvNode:eta/BurnTime < 0.25) { // The time has come, just go for it, and hope it works out...
            return true.
        }
    return false.
  }

  function nodeComplete {
    parameter mnvNode is 0.
    parameter useWarp is true.
    if orbit:transition = MANEUVER { set mnvNode to nextnode. } else { return true. }
    local DeltaV is mnvNode:deltav:mag.
    local BurnTime is staging["burnTimeForDv"](DeltaV)/2.
    local LowBurn is staging["burnTimeForDv"](0.5).
    local Simmer is LowBurn/2.
    set steervec to LOOKDIRUP(mnvNode:burnvector,facing:topvector).
    if not isOriented(mnvNode) {
        set thrott to 0.
        return false.
    }
    if useWarp and (mnvNode:eta > (BurnTime + 15)) {
      wait 1.
        __["warpUntil"](time:seconds + mnvNode:eta - BurnTime - 10).
    }
    if BurnTime < mnvNode:eta {
        set thrott to 0.
        return false.
    }
    set thrott to max(LowBurn, min(1,BurnTime*2)).
    if DeltaV <= .1 {
        lock throttle to 0.
        unlock all.
        remove mnvNode.
        return true.
    }
    if DeltaV < 0.5 {
    	set thrott to max(Simmer, BurnTime).
        return false.
    }
  }

  function setCircAt {
      parameter t is time:seconds + 30.
      local ovel is velocityat(ship, t):orbit.
      local vecHorizontal is vxcl(positionat(ship, t) - body:position, ovel).
      local altitudeAt is (positionat(ship, t) - body:position):mag.
      set vecHorizontal:mag to sqrt(body:MU/(body:radius + altitudeAt)).
      add nodeFromVector(vecHorizontal - ovel, t).
  }

  FUNCTION nodeFromVector {
      PARAMETER vec, n_time.// IS TIME:SECONDS.
      LOCAL s_pro IS VELOCITYAT(SHIP,n_time):ORBIT.
      // The following assumes you do not change sphere of influence between now and n_time
      LOCAL s_pos IS POSITIONAT(SHIP,n_time) - BODY:POSITION.
      LOCAL s_nrm IS VCRS(s_pro,s_pos).
      LOCAL s_rad IS VCRS(s_nrm,s_pro).

      LOCAL pro IS VDOT(vec,s_pro:NORMALIZED).
      LOCAL nrm IS VDOT(vec,s_nrm:NORMALIZED).
      LOCAL rad IS VDOT(vec,s_rad:NORMALIZED).

      RETURN NODE(n_time, rad, nrm, pro).
    }

  // Return eta:apoapsis but with times behind you
  // rendered as negative numbers in the past:
  function eta_ap_with_neg {
    local ret_val is eta:apoapsis.
    if ret_val > ship:obt:period / 2 {
      set ret_val to ret_val - ship:obt:period.
    }
    return ret_val.
  }

  function compass_of_vel {
      local pointing is ship:velocity:orbit.
      local trig_x is vdot(heading(90, 0):vector, pointing).
      local trig_y is vdot(heading(0, 0):vector, pointing).
      return mod(arctan2(trig_y, trig_x) + 360, 360).
  }

  function utilIsShipFacing {
    parameter FaceVec.
    parameter maxDeviationDegrees is 8.
    parameter maxAngularVelocity is 0.01.

    return vdot(FaceVec, ship:facing:forevector) >= cos(maxDeviationDegrees) and
           ship:angularvel:mag < maxAngularVelocity.
  }
  export(self).
}
