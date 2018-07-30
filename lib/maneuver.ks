@LAZYGLOBAL OFF.
pout("LEC MANEUVER v%VERSION_NUMBER%").
{
  local self is lex (
      "orientCraft", orientCraft@,
      "isOriented", isOriented@,
      "nodeComplete", nodeComplete@,
      "circularized", circularized@,
      "circ_thrott", circ_thrott@,
      "circ_heading", compass_of_vel@,
      "circ_deltav", circ_deltav@
  ).
  local t is 0.
  local targetV is 0.
  local targetP is 0.
  local burnMag is 0.
  local staging is import("lib/staging.ks").
  local times is import("lib/time.ks").
  local timeout is 10.

  // Steering and throttle values
  local steervec is 0.
  local thrott is 0.

  local node_bestFacing is 1.   // ~1 degree error (2 degree cone)
  local node_okFacing   is 5.   // ~5 degrees error (10 degree cone)

  function orientCraft {
      parameter mnvNode is nextnode.
      set steervec to LOOKDIRUP(mnvNode:burnvector,facing:topvector).
      lock steering to steervec.
      lock throttle to thrott.
      return true.
    }

  function isOriented {
    parameter mnvNode is nextnode.
    if utilIsShipFacing(mnvNode:burnvector,node_bestFacing,0.5) or
        ((mnvNode:eta <= staging["burnTimeForDv"](mnvNode:deltav:mag) / 2) and
          utilIsShipFacing(mnvNode:burnvector,node_okFacing,5)) or
        ship:angularvel:mag < 0.001 {
            return true.
        }
    return false.
  }

  function nodeComplete {
    parameter mnvNode is nextnode.
    local DeltaV is mnvNode:deltav:mag.
    local BurnTime is staging["burnTimeForDv"](DeltaV)/2.
    set steervec to LOOKDIRUP(mnvNode:burnvector,facing:topvector).
    if VANG(ship:facing:vector,mnvNode:burnvector) > 1 {
        return false.
    }
    __["warpUntil"](time:seconds + mnvNode:eta - BurnTime - 10).
    if BurnTime < mnvNode:eta {
        return false.
    }
    set thrott to min(1,BurnTime*2).
    if DeltaV <= .01 {
        lock throttle to 0.
        unlock all.
        remove mnvNode.
        return true.
    }
    if DeltaV < 0.5 {
    	set thrott to BurnTime.
        return false.
    }
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

    function circ_thrott {
        parameter deltav.
        parameter at_apo is true.
        local eta_time is 0.
        if at_apo {
            set eta_time to eta:apoapsis.
        } else {
            set eta_time to eta:periapsis.
        }
        if not times["hasTime"]("circ") {
            times["setTime"]("circ", TIME:SECONDS + eta_time - staging["burnTimeForDv"](deltav:mag)/2).
            times["setTime"]("circ_to", TIME:SECONDS + eta_time + staging["burnTimeForDv"](deltav:mag)/2).
        }
        if times["diffTime"]("circ") > 0 {
          if vang(ship:facing:vector,deltav) > 2 { return 0. } //Throttle to 0 if not pointing the right way
           else { return max(0,min(1,deltav:mag/10)). } //lower throttle gradually as remaining deltaV gets lower
        }
        return 0.
    }

    function circ_deltav {
        parameter at_apo is true.
        local eta_time is 0.
        if at_apo {
            set eta_time to eta:apoapsis.
        } else {
            set eta_time to eta:periapsis.
        }
        local ovel is velocityat(ship, TIME:SECONDS + eta_time):orbit.
         local vecHorizontal is vxcl(positionat(ship, TIME:SECONDS + eta_time) + ship:position - body:position, ovel).
         set vecHorizontal:mag to sqrt(body:MU/(body:Radius + altitude)).
        // clearvecdraws().
        // local ovelvec is VECDRAW(V(0,0,0), ovel, RGB(1,1,0), "Orbital Vel", 1.0, TRUE, 0.2).
        // local hvelvec is VECDRAW(V(0,0,0), vecHorizontal, RGB(0,1,0), "Horizontal Vel", 1.0, TRUE, 0.2).
        // local dvelvec is VECDRAW(V(0,0,0), vecHorizontal - ovel, RGB(0,0,1), "Delta V", 1.0, TRUE, 0.2).

       return vecHorizontal - ovel. //deltaV as a vector
    }

    function circularized {
        parameter at_apo is true.
        local dv is circ_deltav(at_apo).
        if dv:mag < 0.0005 {
            pout("Circularization complete. ecc=" + ship:obt:ECCENTRICITY).
            unlock steering.
            unlock throttle.
            clearvecdraws().
            return true.
        }
        if (times["diffTime"]("circ_to") > timeout) {
            pout("Circularize timed out.").
            unlock steering.
            unlock throttle.
            clearvecdraws().
            return true.
        }
        return false.
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
