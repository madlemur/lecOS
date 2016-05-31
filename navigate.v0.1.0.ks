{
	global navigate is lex (
		"version", "0.1.0",
		"hohmann", hohmann@, // Degree offset, target
		"target_incl", match_target_inc@,
		"to_incl", match_inc@,
		"target_vel", match_target_vel@,
		"change_apo", set_apo@,
		"change_peri", set_peri@,
		"go_to_alt", set_immediate_alt@,
		"synodic_period", synodicPeriod@
	).

	function hohmann {
		parameter offset, tgt.
		local r1 is (ship:obt:semimajoraxis + ship:obt:semiminoraxis) / 2.
		local r2 is (tgt:obt:semimajoraxis + tgt:obt:semiminoraxis) / 2.
		local approach is 0.

		// dv is not a vector in cartesian space, but rather in "maneuver space"
		// (z = prograde/retrograde dv)
		local dv is V(0, 0, sqrt(body:mu / r1) * (sqrt( (2*(r2-approach)) / (r1+r2-approach) ) - 1)).
		local pt is 0.5 * ((r1+r2) / (2*r2))^1.5.
		local ft is pt - floor(pt).

		// angular distance that target will travel during transfer
		local theta is 360 * ft.
		// necessary phase angle for vessel burn
		local phi is 180 - theta.

		local T is time:seconds.
		local Tmax is T + 1.5 * synodicPeriod(ship:obt, tgt:obt).
		local dt is (Tmax - T) / 20.

		local result is lexicon().

		until false {
			local ps is positionat(ship, T) - body:position.
			local pt is positionat(tgt, T + (tgt:orbit:period * offset/360)) - body:position.
			local vs is velocityat(ship, T):orbit.
			local vt is velocityat(tgt, T + (tgt:orbit:period * offset/360)):orbit.

			// angular velocity of vessel
			local omega is (vs:mag / ps:mag)  * (180/constant():pi).
			// angular velocity of the target
			local omega2 is (vt:mag / pt:mag)  * (180/constant():pi).

			// unsigned magnitude of the phase angle between ship and target
			local phiT is vang(ps, pt).
			// if r2 > r1, then norm:y is negative when ship is "behind" the target
			local norm is vcrs(ps, pt).
			// < 0 if ship is on opposite side of planet
			local dot is vdot(vs, vt).

			local eta is 0.

			if r2 > r1 {
				set eta to (phiT - phi) / (omega - omega2).
			} else {
				set eta to (phiT + phi) / (omega2 - omega).
			}

			// TODO make sure this heuristic works for all cases:
			//   - rendezvous up (untested)
			//   - transfer down (untested)
			if T > Tmax {
				return node(0, dv:x, dv:y, dv:z).
			} else if r2 > r1 and norm:y > 0 {
				set T to T + dt.
			} else if r2 < r1 and norm:y < 0 {
				set T to T + dt.
			} else if (r2 > r1 and dot > 0) or (r2 < r1 and dot < 0) {
				set T to T + dt.
			} else if eta < -1 {
				set T to T + dt.
			} else if abs(eta) > 1 {
				set T to T + eta / 2.
			} else {
				return node(T + eta, dv:x, dv:y, dv:z).
			}
		}
	}

	function synodicPeriod {
	  parameter o1, o2.

	  if o1:period > o2:period {
	    local o is o2.
	    set o2 to o1.
	    set o1 to o.
	  }

	  return 1 / ( (1 / o1:period) - (1 / o2:period) ).
	}

	FUNCTION match_target_inc {
		parameter tgt.
		// Match inclinations with target by planning a burn at the ascending or
		// descending node, whichever comes first.
		//
		// stolen from http://pastebin.com/fq3nqj2p
		// as linked-to by http://www.reddit.com/r/kos/comments/2zehw6/help_calculating_time_to_andn/

		local t0 is time:seconds.
		local ship_orbit_normal is vcrs(ship:velocity:orbit,positionat(ship,t0)-ship:body:position).
		local target_orbit_normal is vcrs(tgt:velocity:orbit,tgt:position-ship:body:position).
		local lineofnodes is vcrs(ship_orbit_normal,target_orbit_normal).
		local angle_to_node is vang(positionat(ship,t0)-ship:body:position,lineofnodes).
		local angle_to_node2 is vang(positionat(ship,t0+5)-ship:body:position,lineofnodes).
		local angle_to_opposite_node is vang(positionat(ship,t0)-ship:body:position,-1*lineofnodes).
		local relative_inclination is vang(ship_orbit_normal,target_orbit_normal).
		local angle_to_node_delta is angle_to_node2-angle_to_node.

		local ship_orbital_angular_vel is (ship:velocity:orbit:mag / (body:radius+ship:altitude))  * (180/constant:pi).
		local time_to_node is angle_to_node / ship_orbital_angular_vel.
		local time_to_opposite_node is angle_to_opposite_node / ship_orbital_angular_vel.

		// the nearest node might be in the past, in which case we want the opposite
		// node. test this by looking at our angular velocity w/r/t the node. There's
		// probably a more straightforward way to do this...
		local t is 0.
		if angle_to_node_delta < 0 {
			set t to (time + time_to_node):seconds.
		} else {
			set t to (time + time_to_opposite_node):seconds.
		}

		local v is velocityat(ship, t):orbit.
		local vt is velocityat(tgt, t):orbit.
		local diff is vt - v.
		local dv is 2 * v:mag * sin(relative_inclination / 2).

		if (diff:y > 0)  {
			return node(t, 0, dv, 0).
		} else {
			return node(t, 0, -dv, 0).
		}
	}

	function match_inc {
		// Match inclinations with target by planning a burn at the ascending or
		// descending node, whichever comes first.

		// Desired orbital inclination
		parameter target_inclination.

		local position is ship:position-ship:body:position.
		local velocity is ship:velocity:orbit.
		local ang_vel is 4 * ship:obt:inclination / ship:obt:period.

		local equatorial_position is V(position:x, 0, position:z).
		local angle_to_equator is vang(position,equatorial_position).

		if position:y > 0 {
			if velocity:y > 0 {
				// above & traveling away from equator; need to rise to inc, then fall back to 0
				set angle_to_equator to 2 * ship:obt:inclination - abs(angle_to_equator).
			}
		} else {
			if velocity:y < 0 {
				// below & traveling away from the equator; need to fall to inc, then rise back to 0
				set angle_to_equator to 2 * ship:obt:inclination - abs(angle_to_equator).
			}
		}

		local frac is (angle_to_equator / (4 * ship:obt:inclination)).
		local dt is frac * ship:obt:period.
		local t is time + dt.

		local relative_inclination is abs(ship:obt:inclination - target_inclination).
		local v is velocityat(ship, T):orbit.
		local dv is 2 * v:mag * sin(relative_inclination / 2).

		if v:y > 0 {
		  // burn anti-normal at ascending node
			return node(T:seconds, 0, -dv, 0).
		} else {
		  // burn normal at descending node
			return node(T:seconds, 0, dv, 0).
		}
	}

	function match_target_vel {
		/////////////////////////////////////////////////////////////////////////////
		// Match velocities at closest approach.
		/////////////////////////////////////////////////////////////////////////////
		// Bring the ship to a stop when it meets up with the target. The accuracy
		// of this program is limited; it'll get you into roughly the same orbit
		// as the target, but fine-tuning will be required if you want to
		// rendezvous.
		/////////////////////////////////////////////////////////////////////////////
		// Determine the time of ship1's closest approach to ship2
		parameter tgt.
		function utilClosestApproach {
		  parameter ship1.
		  parameter ship2.

		  local Tmin is time:seconds.
		  local Tmax is Tmin + 2*ship1:obt:period.
		  local T is 0.

		  // Binary search for time of closest approach
		  local N is 0.
		  until N > 64 {
		    local dt is (Tmax - Tmin) / 4.
		    set T to  Tmin + (2*dt).
		    local Tl is Tmin - dt.
		    local Th is Tmax + dt.

		    local Rl is (positionat(ship1, Tl)) - (positionat(ship2, Tl)).
		    local Rh is (positionat(ship1, Th)) - (positionat(ship2, Th)).

		    if Rh:mag < Rl:mag {
		      set Tmin to T.
		    } else {
		      set Tmax to T.
		    }

		    set N to N + 1.
		  }

		  return T.
		}
		// Figure out some basics
		local T is utilClosestApproach(ship, tgt).
		local Vship is velocityat(ship, T):orbit.
		local Vtgt is velocityat(target, T):orbit.
		local Pship is positionat(ship, T) - body:position.
		local dv is Vtgt - Vship.

		// project dv onto the radial/normal/prograde direction vectors to convert it
		// from (X,Y,Z) into burn parameters. Estimate orbital directions by looking
		// at position and velocity of ship at T.
		local r is Pship:normalized.
		local p is Vship:normalized.
		local n is vcrs(r, p):normalized.
		local sr is vdot(dv, r).
		local sn is vdot(dv, n).
		local sp is vdot(dv, p).

		local dt is dv:mag / accel.

		// Time the burn so that we end thrusting just as we reach the point of closest
		// approach. Assumes the burn program will perform half of its burn before
		// T, half afterward
		return node(T, sr, sn, sp).
	}

	function set_apo {
		/////////////////////////////////////////////////////////////////////////////
		// Change apoapsis.
		/////////////////////////////////////////////////////////////////////////////
		// Establish new apoapsis by performing a burn at periapsis.
		/////////////////////////////////////////////////////////////////////////////

		parameter alt.

		local mu is body:mu.
		local br is body:radius.

		// present orbit properties
		local vom is velocity:orbit:mag.               // actual velocity
		local r is br + altitude.                      // actual distance to body
		local ra is br + periapsis.                    // radius at burn apsis
		local v1 is sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity at burn apsis
		// true story: if you name this "a" and call it from circ_alt, its value is 100,000 less than it should be!
		local sma1 is obt:semimajoraxis.

		// future orbit properties
		local r2 is br + periapsis.                    // distance after burn at periapsis
		local sma2 is (alt + 2*br + periapsis)/2. // semi major axis target orbit
		local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).

		// create node
		local deltav is v2 - v1.
		return node(time:seconds + eta:periapsis, 0, 0, deltav).
	}

	function set_peri {
		/////////////////////////////////////////////////////////////////////////////
		// Change periapsis.
		/////////////////////////////////////////////////////////////////////////////
		// Establish new periapsis by performing a burn at apoapsis.
		/////////////////////////////////////////////////////////////////////////////

		parameter alt.

		local mu is body:mu.
		local br is body:radius.

		// present orbit properties
		local vom is velocity:orbit:mag.               // actual velocity
		local r is br + altitude.                      // actual distance to body
		local ra is br + apoapsis.                     // radius at burn apsis
		local v1 is sqrt( vom^2 + 2*mu*(1/ra - 1/r) ). // velocity at burn apsis
		// true story: if you name this "a" and call it from circ_alt, its value is 100,000 less than it should be!
		local sma1 is (periapsis + 2*br + apoapsis)/2. // semi major axis present orbit

		// future orbit properties
		local r2 is br + apoapsis.               // distance after burn at apoapsis
		local sma2 is (alt + 2*br + apoapsis)/2. // semi major axis target orbit
		local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/sma1 - 1/sma2 ) ) ).

		// create node
		local deltav is v2 - v1.
		return node(time:seconds + eta:apoapsis, 0, 0, deltav).
	}

	function set_immediate_alt {
		/////////////////////////////////////////////////////////////////////////////
		// Change altitude
		/////////////////////////////////////////////////////////////////////////////
		// Perform an immediate burn to establish a new orbital altitude opposite
		// the burn point.
		/////////////////////////////////////////////////////////////////////////////

		parameter alt.

		local mu is constant():G * ship:obt:body:mass.
		local rb is ship:obt:body:radius.

		// present orbit properties
		local vom is velocity:orbit:mag.  // actual velocity
		local r is rb + altitude.
		local va is sqrt( vom^2 ). // velocity in periapsis
		local a is (periapsis + 2*rb + apoapsis)/2. // semi major axis present orbit

		// future orbit properties
		local r2 is rb + altitude.
		local a2 is (alt + 2*rb + periapsis)/2. // semi major axis target orbit
		local v2 is sqrt( vom^2 + (mu * (2/r2 - 2/r + 1/a - 1/a2 ) ) ).

		// create node
		local deltav is v2 - va.
		return node(time:seconds, 0, 0, deltav).
	}
}
