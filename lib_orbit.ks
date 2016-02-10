// /////////
// lib_orbit
// /////////

@LAZYGLOBAL off.

// Initialize an orbit with all six Keplerian elements
function init_orbit_full {
parameter
  sma,  // Semimajor Axis
  ecc,  // Eccentricity
  incl, // Inclination
  lan,  // Longitude of Ascending Node  '-' implies that lan is undefined
  aop,  // Argument of Periapsis        '-' implies that aop is undefined
  tanom.// True Anomaly                 '-' implies that tanom is undefined

}


// Initialize an orbit with five of the six Keplerian elements
//  We don't need True Anomaly since we're just defining the shape of the orbit,
//  not the current state of the orbiting body.
function init_orbit {
parameter
  sma,  // Semimajor Axis
  ecc,  // Eccentricity
  incl, // Inclination
  lan,  // Longitude of Ascending Node  '-' implies that lan is undefined
  aop.  // Argument of Periapsis        '-' implies that aop is undefined

  return init_orbit_full(sma,ecc,incl,lan,aop,'-').
}

// Minimal orbital initialization. Just apoapsis, periapsis, and inclination.
function init_orbit_min {
  parameter
    apo,  // Apoapsis
    peri, // Periapsis
    incl. // Inclination
  local sma = (body:radius * 2 + peri + apo) / 2.
  local ecc = 1 - ( 2 / ( ( ( body:radius + apo ) / ( body:radius + peri ) ) + 1 ) ).
  return init_orbit_full(sma, ecc, incl, '-', '-').
}

function init_orbit_circ {
  parameter
    orbalt, // Orbital altitude
    incl.   // Inclination

  return init_orbit_min(orbalt, orbalt, incl).
}

function init_orbit_min_eq {
  parameter
    apo,  // Apoapsis
    peri. // Periapsis

  return init_orbit_min(apo, peri, 0).
}

function init_orbit_circ_eq {
  parameter
    orbalt. // Orbital altitude

  return init_orbit_min(orbalt, orbalt, 0).
}
