@LAZYGLOBAL OFF.
pout("LEC MANEUVER v%VERSION_NUMBER%").
{
  local self is lex (
      "orientCraft", orientCraft@,
      "isOriented", isOriented@,
      "nodeComplete", nodeComplete@,
      "circThrott", circThrott@,
      "circDeltaV", circDeltaV@,
      "isCircularized", isCircularized@
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

  local node_bestFacing is .5.   // ~.5 degree error (1 degree cone)
  local node_okFacing   is 2.   // ~2 degrees error (4 degree cone)

  function findVect() {
      parameter mnv.
      if mnv:isType("Scalar") {
          if Career():CANMAKENODES AND HASNODE {
              local mnvnode is nextnode.
              return mnvnode:deltav.
          } 
      } else if mnv:isType("Vector") {
          return mnv.
      } else if mnv:isType("Lexicon") {
          if mnv:HASKEY("deltav") {
              return(mnv["deltav"]).
          }
          if mnv:HASKEY("prograde") AND
             mnv:HASKEY("normal") AND
             mnv:HASKEY("radial") AND 
             mnv:HASKEY("utime") {
                 // Use maths to build positionat and velocityat in order to
                 // properly build deltav
          }
      }
      return false.
  }
  
  function findEta {
      parameter mnv.
      if mnv:isType("Scalar") {
          if Career():CANMAKENODES AND HASNODE {
              local mnvnode is nextnode.
              return mnvnode:eta.
          }
      } else if mnv:isType("Lexicon") {
          if mnv:HASKEY("eta") {
              return(mnv["eta"]).
          }
          if mnv:HASKEY("utime") {
             return(mnv["utime"] - TIME:SECONDS).
          }
      }
      return 0.
  }

  function orientCraft {
      parameter mnv is 0.
      local mnvVect is findVect(mnv).
      if not mnvVect return mnvVect.
      set steervec to LOOKDIRUP(mnvVect,facing:topvector).
      set thrott to 0.
      lock steering to steervec.
      lock throttle to thrott.
      return true.
    }

  function isOriented {
    parameter mnv is 0.
    local mnvVect is findVect(mnv).
    local mnvEta is findEta(mnv).
    if not mnvVect return mnvVect.
    local BurnTime is staging["burnTimeForDv"](mnvVect:mag)/2.
    if utilIsShipFacing(mnvVect,node_bestFacing,0.01) or // Good aim.
        ((mnvEta <= BurnTime and // Fair aim, and
          utilIsShipFacing(mnvVect,node_okFacing,2)) or // we're running late!
        // ship:angularvel:mag < 0.001 or // This fat tub isn't turning on it's own, so sure, we're facing as good as it's gonna get.
        mnvEta/BurnTime < 0.25) { // The time has come, just go for it, and hope it works out...
            return true.
        }
    return false.
  }

  function nodeComplete {
    parameter mnv is 0.
    parameter useWarp is true.
    local mnvVect is findVect(mnv).
    local mnvEta is findEta(mnv).
    if not mnvVect return mnvVect.
    if HASNODE { set mnvNode to nextnode. } else { pout("orbit:transition = " + orbit:transition). unlock all. set thrott to 0. return true. }
    set steervec to LOOKDIRUP(mnvVect,facing:topvector).
    wait 0.1.
    if not isOriented(mnv) {
        set thrott to 0.
        return false.
    }
    local DeltaV is mnvVect:mag.
    local BurnTime is staging["burnTimeForDv"](DeltaV)/2.
    local LowBurn is staging["burnTimeForDv"](0.5).
    local Simmer is LowBurn/2.
    if useWarp and (mnvEta > (BurnTime + 15)) {
      wait 1.
        __["warpUntil"](time:seconds + mnvEta - BurnTime - 10).
    }

    if BurnTime < mnvEta {
      print "waiting to burn" at (0,0).
        set thrott to 0.
        return false.
    }
    set thrott to max(LowBurn, min(1,BurnTime*2)).
    print "burning at  " + round(max(LowBurn, min(1,BurnTime*2)) * 100, 2) + "%    " at (0,0).
    if DeltaV <= .1 {
      print "burn completed                    " at (0,0).
        set thrott to 0.
        unlock all.
        if mnv:isType("ManeuverNode") {
            remove mnv.
        }
        return true.
    }
    if DeltaV < 0.5 {
    	set thrott to max(Simmer, BurnTime).
      print "smudging at " + round(max(Simmer,BurnTime) * 100, 2) + "%    " at (0,0).
        return false.
    }
  }

  function setCircAt {
      parameter t is time:seconds + 30.
      // orbital velocity at t
      local ovel is velocityat(ship, t):orbit.
      // remove radial component, so it's only the "horizontal" velocity
      local vecHorizontal is vxcl(positionat(ship, t) - body:position, ovel).
      // Determine the altitude at t
      local altitudeAt is (positionat(ship, t) - body:position):mag.
      // Make that "horizontal" velocity a circular orbits velocity
      set vecHorizontal:mag to sqrt(body:MU/(altitudeAt)).
      // create and add the node
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
