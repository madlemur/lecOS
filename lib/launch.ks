require("lib","circularize.ks").
{
  global pitch is 90.
  global thrott is 0.

  function LockSteering {
    lock steering to heading(90,pitch).
  }

  function CapTWR {
    parameter maxTWR is 3.0.
    local g0 to Kerbin:mu/Kerbin:radius^2.
    global thrott to min(1, ship:mass*g0*maxTWR / max( ship:availablethrust, 0.001 ) ).
  }

  function printtlm {
    local tpitch to 90 - vang( up:vector, velocity:surface ).
    print "Apoapsis: " + round( apoapsis/1000, 2 ) + " km    " at (0,30).
    print "Periapsis: " + round( periapsis/1000, 2 ) + " km    " at (0,31).
    print " Altitude: " + round( altitude/1000, 2 ) + " km    " at (24,30).
    print " Pitch: " + round( tpitch ) + " deg  " at (24,31).
  }

  function GravityTurn {
    parameter vstart.
    parameter AP45 is apoapsis.
    parameter APstop is 60000.
    parameter v45 is 500.

    local vsm to velocity:surface:mag.
    if ( vsm < v45 ) {
      global pitch to 90 - arctan( (vsm - vstart)/(v45 - vstart) ).
    }
    else {
      global pitch to max(0, 45*(apoapsis - APstop) / (AP45 - APstop) ).
    }
  }

  function startnextstage {
    until ship:availablethrust > 0 {
      if altitude<body:atm:height lock steering to srfprograde.
      wait 0.5.
      stage.
    }
  }

  function APkeep {
    parameter apw.
    local Kp to 200.
    if apoapsis > apw { global thrott to 0. }
    else { global thrott to max( 0.05, Kp*(apw - apoapsis)/apw ). }
  }

  global gettoorbit is {
    parameter Horb to body:atm:height + 10000.
    parameter GTstart to 800.
    parameter GTendAP to 55000.

    local maxTWR to 3.0.
    local initialpos to ship:facing.
    lock steering to initialpos.
    global thrott to 1.
    lock throttle to thrott.
    startnextstage().

    LockSteering().
    until alt:radar > GTstart {
      CapTWR(maxTWR).
      startnextstage().
      printtlm().
      wait 0.
    }

    local GTStartSpd to velocity:surface:mag.
    local Apo45 to apoapsis.
    local lock vpitch to 90 - vang( up:vector, velocity:surface ).

    until apoapsis >= Horb {
      if vpitch >= 45 { set Apo45 to apoapsis. }
      GravityTurn(GTStartSpd,Apo45,GTendAP).
      startnextstage().
      printtlm().
      wait 0.
    }

    global thrott to 0.
    lock steering to prograde.

    until altitude > body:atm:height {
      APkeep(Horb).
      printtlm().
      wait 0.
    }
    lock throttle to 0.
    print "We are in space. ".
    wait 5.

    wait until altitude > apoapsis - 20.
    circularize().

    print "We are in orbit: " + round(apoapsis/1000,2) + "x" + round(periapsis/1000,2) + " km. ".
    wait 5.

  }.
}
