// Execute Ascent Profile v1.0.0
// Kevin Gisi
// http://youtube.com/gisikw

RUN ONCE lib_staging.

FUNCTION EXECUTE_ASCENT_STEP {
  PARAMETER direction.
  PARAMETER minAlt.
  PARAMETER newAngle.
  PARAMETER newThrust.

  UNTIL FALSE {

    MNV_BURNOUT(true).

    IF ALTITUDE > minAlt {
      LOCK STEERING TO HEADING(direction, newAngle).
      LOCK THROTTLE TO newThrust.
      BREAK.
    }

    WAIT 0.1.
  }
}

// This requires the values be put into a Queue in the correct order.
FUNCTION EXECUTE_ASCENT_PROFILE {
  PARAMETER direction.
  PARAMETER profile.

  UNTIL profile:length < 3 {
    EXECUTE_ASCENT_STEP(
      direction,
      profile:pop,
      profile:pop,
      profile:pop
    ).
  }
}
