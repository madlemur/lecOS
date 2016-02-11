// Maneuver Library v1.0.0
// Kevin Gisi
// http://youtube.com/gisikw
RUN lib_warp.

SET burnoutCheck TO "reset".
FUNCTION MNV_BURNOUT {
  PARAMETER autoStage.

  IF burnoutCheck = "reset" {
    SET burnoutCheck TO MAXTHRUST.
    RETURN FALSE.
  }

  IF burnoutCheck - MAXTHRUST > 10 {
    IF autoStage {
      SET currentThrottle TO THROTTLE.
      LOCK THROTTLE TO 0.
      WAIT 1. STAGE. WAIT 1.
      LOCK THROTTLE TO currentThrottle.
    }
    SET burnoutCheck TO "reset".
    RETURN TRUE.
  }

  RETURN FALSE.
}

// Time to complete a maneuver
FUNCTION MNV_TIME {
  PARAMETER dV.

  LOCAL engine_stats = MNV_ENGINE_STATS().

  LOCAL f IS engine_stats["Thrust"] * 1000.  // Engine Thrust (kg * m/s²)
  LOCAL m IS SHIP:MASS * 1000.        // Starting mass (kg)
  LOCAL e IS CONSTANT:E.            // Base of natural log
  LOCAL p IS engine_stats["ISP"].         // Engine ISP (s)
  LOCAL g IS 9.82.                    // Gravitational acceleration constant (m/s²)

  RETURN g * m * p * (1 - e^(-dV/(g*p))) / f.
}

function MNV_BURN_TIME {
  declare local parameter dV.

  local e is CONSTANT:E.
  local eng_stats is get_engine_stats().
  local mass_rate is eng_stats["MassRate"].
  local v_e is eng_stats["ExitVel"].

  // Rocket equation solved for t.
  local burn_t is  SHIP:MASS*(1 - e^(-dV/v_e))/mass_rate.

  return burn_t.
}

FUNCTION MNV_ENGINE_STATS {
  local g is 9.82.	// Engines use this.

  local all_thrust is 0.
  local old_isp_devider is 0.
  local all_engines is LIST().

  list ENGINES in all_engines.
  for eng in all_engines {
    if eng:IGNITION AND NOT eng:FLAMEOUT {
      set all_thrust to (all_thrust + eng:AVAILABLETHRUST).
      set old_isp_devider to (old_isp_devider + (eng:AVAILABLETHRUST / eng:VISP)).
    }
  }

  local mean_isp is (all_thrust / old_isp_devider).
  local ch_rate is all_thrust/(g*mean_isp).
  local exit_velocity is all_thrust/ch_rate.

  local stat_block is lexicon().
	stat_block:add("Thrust", all_thrust).
	stat_block:add("ISP", mean_isp).
	stat_block:add("MassRate", ch_rate).
	stat_block:add("ExitVel", exit_velocity).

	return stat_block.
}

// Delta v requirements for Hohmann Transfer
FUNCTION MNV_HOHMANN_DV {
  PARAMETER desiredAltitude.

  SET u  TO SHIP:OBT:BODY:MU.
  SET r1 TO SHIP:OBT:SEMIMAJORAXIS.
  SET r2 TO desiredAltitude + SHIP:OBT:BODY:RADIUS.

  // v1
  SET v1 TO SQRT(u / r1) * (SQRT((2 * r2) / (r1 + r2)) - 1).

  // v2
  SET v2 TO SQRT(u / r2) * (1 - SQRT((2 * r1) / (r1 + r2))).

  RETURN LIST(v1, v2).
}

// Execute the next node
FUNCTION MNV_EXEC_NODE {
  PARAMETER autoWarp.

  LOCAL n IS NEXTNODE.
  LOCAL v IS n:BURNVECTOR.

  LOCAL startTime IS TIME:SECONDS + n:ETA - MNV_TIME(v:MAG)/2.
  LOCK STEERING TO n:BURNVECTOR.

  IF autoWarp { WARPTO(startTime - 30). }

  WAIT UNTIL TIME:SECONDS >= startTime.
  LOCK THROTTLE TO MIN(MNV_TIME(n:BURNVECTOR:MAG), 1).
  WAIT UNTIL VDOT(n:BURNVECTOR, v) < 0.
  LOCK THROTTLE TO 0.
  UNLOCK STEERING.
}
