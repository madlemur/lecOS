@LAZYGLOBAL OFF.
PRINT("LEC MANEUVER v%VERSION_NUMBER%").
{
  local self is lex (
      "setManeuver", setManeuver@,
      "orientCraft", orientCraft@,
      "isOriented", isOriented@,
      "maneuverComplete", maneuverComplete@,
      "circularized", circularized@,
      "circ_thrott", circ_thrott@,
      "circ_heading", compass_of_vel@,
      "circ_pitch", circ_pitch@,
      "circ_deltav", circ_deltav@
  ).
  local t is 0.
  local targetV is 0.
  local targetP is 0.
  local steervec is 0.
  local burnMag is 0.
  local staging is import("lib/staging.ks").

  local node_bestFacing is 5.   // ~5  degrees error (10 degree cone)
  local node_okFacing   is 20.  // ~20 degrees error (40 degree cone)

  function setManeuver {
    parameter n is NEXTNODE.
    local dv
    if n:isType("ManeuverNode") {
      set dv to n:deltav.
      set t to n:eta + TIME:SECONDS.
    } else if n:isType("List") {
      if n:length = 2 {
        set dv to n[1].
        set t to n[0].
      } if n:length = 4 {
        set dv to V(n[1],n[2]n[3]).
        set t to n[0].
      }
    } else if n:isType("Lexicon") {
      if n:haskey("deltav") {
        set dv to n["deltav"].
      } else {
        set dv to V(n["prograde"], n["radialout"], n["normal"]).
      }
      set t to n["nodetime"].
    } else {
      return false.
    }
    set burnMag to dv:mag.
    set targetV to velocityAt(ship, t) + dv.
    set targetP to positionAt(ship, t).
    set steervec to lookdirup(dv, ship:up:vector):vector.
    return true.
  }

  function orientCraft {
    if steerVec:isType("Vector") {
      lock steering to steerVec.
      return true.
    }
    return false.
  }

  function isOriented {
    if  utilIsShipFacing(steerVec,node_bestFacing,0.5) or
        ((t - TIME:SECONDS <= staging["burnTimeForDv"](burnMag) / 2) and utilIsShipFacing(steerVec,node_okFacing,5)) or
        ship:angularvel:mag < 0.0001 { return true. }
    return false.
  }

  function maneuverComplete {
    set steervec to (targetV - velocityAt(ship, t)) - ( targetP - positionAt(ship, t)).
    local nodeAccel is staging["thrustToWeight"]().

    if nodeAccel > 0 {
      if utilIsShipFacing(steervec,node_okFacing,2) {
        //feather the throttle
        set th to min(steervec:mag/nodeAccel, 1.0).
      } else {
        // we are not facing correctly! cut back thrust to 10% so gimbaled
        // engine will push us back on course
        set th to 0.1.
      }
      // three conditions for being done:
      //   1) overshot (node delta vee is pointing opposite from initial)
      //   2) burn DV increases (off target due to wobbles)
      //   3) burn DV gets too small for main engines to cope with
      if (vdot(targetV, steervec) < 0) or
                      (steervec:mag > burnMag + 0.05) or
                      (steervec:mag <= 0.2) { return true. }
    }
    set burnMag to steervec:mag.
    return false.
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

    function circ_pitch {
        return -(eta_ap_with_neg()/3).
    }

    function circ_thrott {
        parameter deltav.
        if not times["hasTime"]("circ") {
            pout("eta: " + eta:apoapsis).
            pout("burn: " + staging["burnTimeForDv"](deltav:mag)).
            pout("deltav: " + deltav:mag).
            times["setTime"]("circ", TIME:SECONDS + eta:apoapsis - staging["burnTimeForDv"](deltav:mag)/2).
            times["setTime"]("circ_to", TIME:SECONDS + eta:apoapsis + staging["burnTimeForDv"](deltav:mag)/2).
        }
        if times["diffTime"]("circ") > 0 {
          if vang(ship:facing:vector,deltav) > 2 { return 0. } //Throttle to 0 if not pointing the right way
           else { return max(0,min(1,deltav:mag/10)). } //lower throttle gradually as remaining deltaV gets lower
        }
        return 0.
    }

    function circ_deltav {
        local ovel is velocityat(ship, TIME:SECONDS + eta:apoapsis):orbit.
         local vecHorizontal is vxcl(positionat(ship, TIME:SECONDS + eta:apoapsis) + ship:position - body:position, ovel).
         set vecHorizontal:mag to sqrt(body:MU/(body:Radius + altitude)).
        // clearvecdraws().
        // local ovelvec is VECDRAW(V(0,0,0), ovel, RGB(1,1,0), "Orbital Vel", 1.0, TRUE, 0.2).
        // local hvelvec is VECDRAW(V(0,0,0), vecHorizontal, RGB(0,1,0), "Horizontal Vel", 1.0, TRUE, 0.2).
        // local dvelvec is VECDRAW(V(0,0,0), vecHorizontal - ovel, RGB(0,0,1), "Delta V", 1.0, TRUE, 0.2).

       return vecHorizontal - ovel. //deltaV as a vector
    }

    function circularized {
        local dv is circ_deltav().
        if dv:mag < 0.005 {
            pout("Circularization complete. ecc=" + ship:obt:ECCENTRICITY).
            unlock steering.
            unlock throttle.
            set timeout to 90.
            clearvecdraws().
            return true.
        }
        if (times["diffTime"]("circ_to") > timeout) {
            pout("Circularize timed out.").
            unlock steering.
            unlock throttle.
            set timeout to 90.
            clearvecdraws().
            return true.
        }
        if (dv:mag < 0.05 AND times["diffTime"]("circ_to") > 5) {
            times["setTime"]("circ_to").
            set timeout to 5.
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
}
