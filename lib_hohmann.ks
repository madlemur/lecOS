
//KOS angleUntilHohmann
// Return the angle (in degrees) of offset from now to when
// the optimal Hohmann transfer point is to reach the given
// target body.  Assumes circular orbits.
// RETURNS: global variable: haOffset.  (Hohmann angle offset).

function hohmann {
  declare parameter ha_source. // ship doing the transfer.
  declare parameter ha_dest. // Destination of transfer.

  // Positions of source and dest objects relative to the source's SOI body.
  local source_pos is (ha_source:position - ha_source:body:position).
  local dest_pos is (ha_dest:position - ha_source:body:position).

  // ha_phi is the angle betwen source and the destination right now.
  local ha_phi is VANG(source_pos, dest_pos).

  // If I am in the "away" half of my orbit, adjust angle accordingly
  if VDOT(ha_source:velocity:orbit, ha_dest:position) < 0 {
    set ha_phi to 360 - ha_phi.
  }
  // Solution taken from:
  //   https://docs.google.com/document/d/1IX6ykVb0xifBrB4BRFDpqPO6kjYiLvOcEo3zwmZL0sQ/edit
  // ha_orbits: fraction of an orbit the destination will
  // make in the time it takes the source to get there:
  local ha_orbits is
  0.5 * ( (source_pos:mag + dest_pos:mag) /
          (2*dest_pos:mag)
        ) ^ 1.5 .
  // ha_theta: how much the destination's angle position
  // will have moved after it performs ha_orbits.
  local ha_theta is 360 * mod( ha_orbits, 1 ).
  // ha_rho: angle I need to be behind the destination when I make the burn:
  local ha_rho is 180 - ha_theta.

  // Report the difference between where I want to be (ha_rho) and where I am (ha_phi):
  return ha_phi - ha_rho.
}
