// Rendezvous Library v0.1.0
// Ken Cummins from original by
// Kevin Gisi
// http://youtube.com/gisikw
//
// This library assumes that the active vessel has already mostly matched the
// target craft's orbit and position. This is for fine-tuning the rendezvous.
{


  global rendezvous is lex(
    "version", "0.1.0",
    "steer", steer@,
    "approach", approach@,
    "cancel", cancel@,
    "await_nearest", await_nearest@,
    "rendezvous", rendezvous@
  ).

  function rendezvous {
    parameter tgt.
    cancel(tgt,100).
    lock tgtdist to (ship:position - tgt:position):mag.
    if(tgtdist > 2000) {
      approach(tgt, 100).
      await_nearest(tgt, 2000).
    }
    cancel(tgt,50).
    if(tgtdist > 500) {
      approach(tgt, 50).
      await_nearest(tgt, 500).
    }
    cancel(tgt,5).
    if(tgtdist > 100) {
      approach(tgt, 5).
      await_nearest(tgt, 100).
    }
    cancel(tgt,2).
    if(tgtdist > 5) {
      approach(tgt, 2).
      await_nearest(tgt,5).
    }
    cancel(tgt).
  }

  FUNCTION steer {
    PARAMETER vector.

    LOCK STEERING TO vector.
    WAIT UNTIL VANG(SHIP:FACING:FOREVECTOR, vector) < 2.
  }

  FUNCTION approach {
    PARAMETER craft, speed.

    LOCK relativeVelocity TO craft:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT.
    steer(craft:POSITION).

    LOCK maxAccel TO max(SHIP:MAXTHRUST / SHIP:MASS,0.000001).
    LOCK THROTTLE TO MIN(1, ABS(speed - relativeVelocity:MAG) / maxAccel).

    WAIT UNTIL relativeVelocity:MAG > speed - 0.1.
    LOCK THROTTLE TO 0.
    LOCK STEERING TO relativeVelocity.
  }

  FUNCTION cancel {
    PARAMETER craft.
    PARAMETER tolerance is 0.01.

    LOCK relativeVelocity TO craft:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT.
    steer(relativeVelocity).

    LOCK maxAccel TO max(SHIP:MAXTHRUST / SHIP:MASS,0.000001).
    LOCK THROTTLE TO MIN(1, relativeVelocity:MAG / maxAccel).

    WAIT UNTIL relativeVelocity:MAG < tolerance + 0.01.
    LOCK THROTTLE TO 0.
  }

  FUNCTION await_nearest {
    PARAMETER craft, minDistance.

    UNTIL 0 {
      SET lastDistance TO craft:DISTANCE.
      WAIT 0.5.
      IF craft:distance > lastDistance OR craft:distance < minDistance { BREAK. }
    }
  }
}
