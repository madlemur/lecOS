@LAZYGLOBAL off.
run lib_common.
run lib_staging.
run lib_nav.

function createNodeAtApo {
  declare parameter alt.
  // create apoapsis maneuver node
  print "T+" + round(missiontime) + " Apoapsis maneuver, orbiting " + body.
  print "T+" + round(missiontime) + " Apoapsis: " + round2(apoapsis/1000) + "km.".
  print "T+" + round(missiontime) + " Periapsis: " + round2(periapsis/1000) + "km" + " -> " + round(alt/1000) + "km".

  // present orbit properties
  local vom to velocity:orbit:mag.  // actual velocity
  local r to body:radius + altitude.         // actual distance to body
  local ra to body:radius + apoapsis.        // radius in apoapsis
  local va to sqrt( vom^2 + 2*body:mu*(1/ra - 1/r) ). // velocity in apoapsis
  local a to (periapsis + 2*body:radius + apoapsis)/2. // semi major axis present orbit
  // future orbit properties
  local r2 to body:radius + apoapsis.    // distance after burn at apoapsis
  local a2 to (alt + 2*body:radius + apoapsis)/2. // semi major axis target orbit
  local v2 to sqrt( vom^2 + (body:mu * (2/r2 - 2/r + 1/a - 1/a2 ) ) ).
  // setup node
  local deltav to v2 - va.
  print "T+" + round(missiontime) + " Apoapsis burn: " + round2(va) + ", dv:" + round2(deltav) + " -> " + round(v2) + "m/s".
  local x to node(time:seconds + eta:apoapsis, 0, 0, deltav).
  add x.
  print "T+" + round(missiontime) + " Node created.".
  return x.
}

function execNode {

      // execute maneuver node
    print "T+" + round(missiontime) + " Node in: " + round(nextnode:eta) +
      ", DeltaV: " + round(nextnode:deltav:mag).
    print "T+" + round(missiontime) + " Node apoapsis: " +
      round(nextnode:orbit:apoapsis) + ", periapsis: " + round(nextnode:orbit:periapsis).
    global maxda to availablethrust/mass.
    print "T+" + round(missiontime) + " Max DeltaA for engine: " + round(maxda).
    local dob to nextnode:deltav:mag/maxda.     // incorrect: should use tsiolkovsky formula
    print "T+" + round(missiontime) + " Duration of burn: " + round(dob).

    print "T+" + round(missiontime) + " Turning ship to burn direction.".

    //sas on.
    //set sasmode to "maneuver".
    //sas off.
    //rcs on.
    // workaround for steering:pitch not working with node assigned

    lock steering to nextnode:deltav:direction * R(0,0,compass()).

    wait until abs(nextnode:deltav:direction:pitch - facing:pitch) < 0.1 and
      abs(nextnode:deltav:direction:yaw - facing:yaw) < 0.1.

    sas off.
    rcs off.

    print "T+" + round(missiontime) + " Warping to maneuver...".
    //warpTo(nextnode:eta - dob/2).
    // using new stock func:
    // - 10 sec for maneuver
    warpTo(time:seconds + nextnode:eta - dob/2 - 10).
    wait until nextnode:eta - dob/2 <= 10.
    set warp to 0.
    wait until nextnode:eta - dob/2 <= 0.

    print "T+" + round(missiontime) + " Warp complete " + time:calendar + " " + time:clock.

    local np is 0.
    lock np to nextnode:deltav.

    print "T+" + round(missiontime) + " Orbital burn start " + round(nextnode:eta) + " s before apoapsis.".
    // lock steering to node:prograde which wanders off at small deltav
    if nextnode:deltav:mag > 2*maxda {
        when nextnode:deltav:mag < 2*maxda then {
            print "T+" + round(missiontime) + " Reducing throttle, deltav " + round(nextnode:deltav:mag) + ", fuel:" + round(stage:liquidfuel).
            // continue to accelerate node:deltav
            lock steering to np.
        }
    }

    local tvar to 0.
    lock throttle to tvar.
    //print vang(nextnode:deltav, facing:vector).
    when vang(nextnode:deltav, facing:vector) > 15 then {
        print "T+" + round(missiontime) + " Abort throttling!".
        set tvar to 0.
        unlock throttle.
        set throttle to 0.
        remove nextnode.
    }

    until nextnode:deltav:mag < 1 and stage:liquidfuel > 0 {

        local thrust to maxthrust * throttle.
        local da to thrust/mass.
        local tset to 0.

        if ( maxthrust > 0 ) {
          set tset to nextnode:deltav:mag * mass / maxthrust.
          if nextnode:deltav:mag < 2*da and tset > 0.1 {
              set tvar to tset.
          }
          if nextnode:deltav:mag > 2*da {
              set tvar to 1.
          }
        }
        print "Thrust: " + round(thrust) + "  " at (0,28).
        print "DeltaA: " + round(da) + "  " at (0,29).
        print "Node DeltaV: " + round(nextnode:deltav:mag) + "  " at (0,30).
        checkStages().
        wait 0.01.
    }

    lock throttle to 0.
    remove nextnode.
    print "T+" + round(missiontime) + " Burn complete, apoapsis: " + round(apoapsis) + ", periapsis: " + round(periapsis).
    print "T+" + round(missiontime) + " Fuel in orbit: " + round(stage:liquidfuel).
    //print "T+" + round(missiontime) + " Turning to expose solar panels...".
    //set np to prograde + R(-90,0,0).
    //lock steering to np.
    //wait until abs(np:pitch - facing:pitch) < 0.1 and abs(np:yaw - facing:yaw) < 0.1.
    sas on.
    //print "T+" + round(missiontime) + " Burn complete.".
}
