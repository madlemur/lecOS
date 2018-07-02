@LAZYGLOBAL OFF.
PRINT("LEC MANEUVER v%VERSION_NUMBER%").
{
  local self is lex (

  ).
  local t is 0.
  local targetV is 0.
  local targetP is 0.
  local steervec is 0.
  local burnMag is 0.

  local node_bestFacing is 5.   // ~5  degrees error (10 degree cone)
  local node_okFacing   is 20.  // ~20 degrees error (40 degree cone)

  function setManeuver {
    parameter n.
    local dv
    if n:isType("ManeuverNode") {
      set dv to n:deltav.
      set t to n:eta + TIME:SECONDS.
    } else if n:isType("List") {
      if n:length = 2 {
        set dv to n[0].
        set t to n[1].
      } if n:length = 4 {
        set dv to V(n[0],n[1]n[2]).
        set t to n[3].
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
        ((t - TIME:SECONDS <= nodeDob / 2) and utilIsShipFacing(steerVec,node_okFacing,5)) or
        ship:angularvel:mag < 0.0001 { return true. }
    return false.
  }

  function maneuverComplete {
    set steervec to (targetV - velocityAt(ship, t)) - ( targetP - positionAt(ship, t)).
    local nodeAccel is ship:availablethrust / ship:mass.

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

  function utilIsShipFacing {
    parameter FaceVec.
    parameter maxDeviationDegrees is 8.
    parameter maxAngularVelocity is 0.01.

    return vdot(FaceVec, ship:facing:forevector) >= cos(maxDeviationDegrees) and
           ship:angularvel:mag < maxAngularVelocity.
  }
}
