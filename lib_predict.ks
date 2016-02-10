@LAZYGLOBAL OFF.

function eta_to_ta {
  parameter
    orbit_in,
    ta_deg.

  local targettime is time_pe_to_ta(orbit_in, ta_deg).
  local curtime is time_pe_to_ta(orbit_in, orbit_in:trueanomaly).

  local ta is targettime - curtime.

  if ta < 0 { set ta to ta - orbit_in:period. }

  return ta.
}

function time_pa_to_ta {
  parameter
    orbit_in,
    ta_deg.

  local ecc is orbit_in:eccentricity.
  local sma is orbit_in:semimajoraxis.
  local e_anom_deg is arctan2( sqrt(1-ecc^2)*sin(ta_deg), ecc + cos (ta_deg) ).
  local e_anom_rad is e_anom_deg * constant():pi/180.
  local m_anom_rad is e_anom_rad - ecc * sin(e_anom_deg).

  return m_anom_rad / sqrt( orbit_in:body:mu / sma^3 ).
}

function orbit_normal {
  parameter orbit_in.

  return VCRS( orbit_in:body:position - orbit_in:position,
               orbit_in:velocity:orbit ):NORMALIZED.
}

function find_ascending_node_ta {
  parameter orbit_1, orbit_2.

  local normal_1 is orbit_normal(orbit_1).
  local normal_2 is orbit_normal(orbit_2).

  local vec_body_to_node is VCRS(normal_1, normal_2).

  local pos_1_body_rel is orbit_1:position - orbit_1:body:position.

  local ta_ahead is VANG( vec_body_to_node, pos_1_body_rel).

  if VDOT( normal_1, sign_check_vec) < 0 {
    set ta_ahead to 180 - ta_ahead.
  }

  return mod( orbit_1:trueanomaly + ta_ahead, 360).
}

function inclination_match_burn {
  parameter
    vessel_1,
    orbit_2.

    local normal_1 is orbit_normal(vessel_1:obt).
    local normal_2 is orbit_normal(orbit_2).

    local node_ta is find_ascending_node_ta(vessel_1:obt, orbit_2).

    if node_ta < 90 or node_ta > 270 {
      set node_ta to mod(node_ta + 180, 360).
    }

    local burn_eta is eta_to_ta(vessel_1:obt, node_ta).
    local burn_ut is time:seconds + burn_eta.
    local burn_unit is (normal_1 + normal_2):NORMALIZED.
    local vel_at_eta is VELOCITYAT(vessel_1,burn_ut):ORBIT.
    local burn_mag is -2*vel_at_eta:MAG*COS(VANG(vel_at_eta,burn_unit)).

    return LIST(burn_ut, burn_mag*burn_unit).
}

function orbit_altitude_at_ta {
  parameter
    orbit_in,
    true_anom.

    local sma is orbit_in:semimajoraxis.
    local ecc is orbit_in:eccentricity.
    local r is sma*(1-ecc^2)/(1+ecc*COS(true_anom)).

    return r - orbit_in:body:radius.
}

function ta_offset {
  parameter
    orbit_1,
    orbit_2.

  local pe_lng_1 is
    orbit_1:argumentofperiapsis +
    orbit_1:longitudeofascendingnode.

  local pe_lng_2 is
    orbit_2:argumentofperiapsis +
    orbit_2:longitudeofascendingnode.

  return pe_lng_1 - pe_lng_2.
}

function orbit_cross_ta {
  parameter
    orbit_1,
    orbit_2,
    max_epsilon,
    min_epsilon.

  local pe_ta_off is ta_offset( orbit_1, orbit_2 ).

  local incr is max_epsilon.
  local prev_diff is 0.
  local start_ta is orbit_1:trueanomaly.
  local ta is start_ta.

  until ta > start_ta + 180 or abs(incr) < min_epsilon {
    local diff is orbit_altitude_at_ta(orbit_1, ta) -
                  orbit_altitude_at_ta(orbit_2, pe_ta_off + ta).
    if diff + prev_diff < 0 {
      set incr to -incr/10.
    }
    set prev_diff to diff.
  }
  if ta > start_ta+360 {
    return -1.
  } else {
    return mod(ta,360).
  }
}
