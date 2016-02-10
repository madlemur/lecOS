@LAZYGLOBAL off.

function getClosestWaypoint {
	local allw is allwaypoints().
  if ( allw:length = 0 ) {
    print "no waypoints".
    return false.
  }

  local d is (ship:position-allw[0]:position):mag.
  local closest is allw[0].

  for w in allw {
      if (ship:position-w:position):mag < d {
        set d to (ship:position-w:position):mag.
        set closest to w.
      }
  }

  return closest.
}

// in degs
function getSlope {
  declare parameter spot. //ship-raw
  declare parameter radius. // in meters

  local minh is ship:altitude.
  local maxh is 0.
  local x is 0.
  local y is 0.

  from { set x to -radius. } until x > radius step { set x to x + radius. } do {
    from { set y to -radius. } until y > radius step { set y to y + radius. } do {
      local shifted is spot + y * north:vector + x * north:rightvector.
      local ns is body:geopositionof( shifted ).
      if ( ns:terrainHeight < minh ) { set minh to ns:terrainHeight. }
      if ( ns:terrainHeight > maxh ) { set maxh to ns:terrainHeight. }
    }
  }

  return arctan2( maxh - minh, 2 ).
}


function compass {

  local pf is vxcl( up:vector, facing:vector ).
  local res is vang( north:vector, pf ).

  local cr is vcrs( north:vector, pf ).
  if ( vdot( cr, up:vector ) < 0 ) {
    set res to 360 - res.
  }

  return res.
}
