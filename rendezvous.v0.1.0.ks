// Rendezvous Library v0.1.0
// Ken Cummins from original by
// Kevin Gisi
// http://youtube.com/gisikw
//
// This library assumes that the active vessel has already mostly matched the
// target craft's orbit and position. This is for fine-tuning the rendezvous.
{

  local relativeVelocity is 0.

  global rendezvous is lex(
    "version", "0.1.0",
    "approach", approach@,
    "cancel", approach@,
    "await_nearest", await_nearest@,

    "lastDistance", -1
  ).

  FUNCTION steer {
    PARAMETER vector.

    LOCK STEERING TO vector.
    WAIT UNTIL abs(steeringmanager:yawerror) < 2 and
			 abs(steeringmanager:pitcherror) < 2 and
			 abs(steeringmanager:rollerror) < 2.
  }

  FUNCTION approach {
    PARAMETER craft, speed is 0.
    LOCK relativeVelocity TO craft:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT.
    LOCAL deadband is max(speed * 0.02, 0.05).

    if relativeVelocity:MAG > speed + deadband {
      steer(relativeVelocity).
    } else if relativeVelocity:MAG < speed - deadband {
      steer(craft:POSITION).
    }
    LOCK maxAccel TO SHIP:MAXTHRUST / SHIP:MASS.
    LOCK THROTTLE TO MIN(1, ABS(speed - relativeVelocity:MAG) / maxAccel).
    if ABS(relativeVelocity:MAG - speed) < deadband or (relativeVelocity:MAG < speed AND craft:DISTANCE/relativeVelocity:MAG < 10){
      LOCK THROTTLE TO 0.
      LOCK STEERING TO relativeVelocity.
      return true.
    }
    return false.
  }

  FUNCTION await_nearest {
    PARAMETER craft, minDistance is 1.
    if rendezvous["lastDistance"] < 0 {
      set rendezvous["lastDistance"] to craft:DISTANCE.
    }
    if craft:distance > rendezvous["lastDistance"] OR craft:distance <= minDistance {
      set rendezvous["lastDistance"] to -1.
      return true.
    }
    return false.
  }
}
