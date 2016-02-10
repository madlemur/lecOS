@LAZYGLOBAL off.
run lib_debug.

function angle_of_attack {
  return  vang(ship:srfprograde:vector, getThrustDirection():vector).
}

function readAcc {

  // A combination of both the gravitational pull and the engine thrust.
  if ( SHIP:SENSORS:ACC:mag <> 0 ) {
    return SHIP:SENSORS:ACC:mag.
  }

  if ( time:seconds - lastMeasureTime > 1 ) {
    //print "elapsed = " + (time:seconds - lastMeasureTime).
    //print "speed delta = " + (ship:AirSpeed - lastShipSpeed).
    //print "acc = " + (ship:AirSpeed - lastShipSpeed) / (time:seconds - lastMeasureTime).
    if ( lastMeasureTime > 0 ) {
      set cachedAcc to (ship:AirSpeed - lastShipSpeed) / (time:seconds - lastMeasureTime).
    }
    set lastShipSpeed to ship:AirSpeed.
    set lastMeasureTime to time:seconds.
  }

  return cachedAcc.
}

local lastVertAccMeasureTime to 0.
local lastShipVerticalSpeed to 0.
local cachedVertAcc to 0.

function readVertAcc {
  if ( time:seconds - lastVertAccMeasureTime > 1 ) {
    if ( lastVertAccMeasureTime > 0 ) {
      set cachedVertAcc to (ship:verticalSpeed - lastShipVerticalSpeed) / (time:seconds - lastVertAccMeasureTime).
    }
    set lastShipVerticalSpeed to ship:verticalSpeed.
    set lastVertAccMeasureTime to time:seconds.
  }

  return cachedVertAcc.
}

local lastHorizAccMeasureTime to 0.
local lastShipHorizontalSpeed to 0.
local cachedHorizAcc to 0.

function readHorizAcc {
  if ( time:seconds - lastHorizAccMeasureTime > 1 ) {
    if ( lastHorizAccMeasureTime > 0 ) {
      set cachedHorizAcc to (ship:surfaceSpeed - lastShipHorizontalSpeed) /
        (time:seconds - lastHorizAccMeasureTime).
    }
    set lastShipHorizontalSpeed to ship:verticalSpeed.
    set lastHorizAccMeasureTime to time:seconds.
  }

  return cachedHorizAcc.
}

// calculate mean
local avgDrag is 0.
local avgDragCount is 1.

function getDrag {
  //declare parameter vess.
  
  local myVariable is 0.
  local totalThrust to 0.
  LIST ENGINES IN myVariable.

  for egn in myVariable {
    set totalThrust to totalThrust + egn:thrust.
  }

  if ( totalThrust = 0 ) {
    if ( avgDrag > 0 ) {
      return avgDrag. // cannot get drag without thrust. default
    } else {
      return 0.2. // rude default
    }
  }

  local acceleration to abs(readAcc()).
  local drag to totalThrust/1000 - ship:mass/1000*(acceleration).
  if ( drag < 0 ) { // no thrust
    if ( avgDrag = 0 ) {
      return 0.2.
    } else {
      return avgDrag.
    }
  }

  local newDrag to ((avgDrag * avgDragCount) + drag).
  set avgDragCount to avgDragCount + 1.
  set avgDrag to newDrag / avgDragCount.

  //print "Total thrust = " + totalThrust.
  //print "Acceleration = " + acceleration.
  //print "Drag = " + avgDrag.
  return avgDrag.
 //0 = Thrust - mass*gravity - Drag - mass*acceleration
 // Drag = Thrust - mass*(gravity - acceleration)
}

function getTermVel {

  local _termVel is 2*sqrt(ship:verticalSpeed^2 + ship:surfaceSpeed^2).
    //todo drag
  if body:atm:exists {
    local drag is getDrag().

    if ( drag = 0 ) {
      return _termVel.
    }

    local atmos is (body:atm:sealevelpressure / 101.325) * ( CONSTANT():E ^ ( - SHIP:ALTITUDE / 5000 ) ). // 5000 body:atm:scale
    local dens is atmos * 1.2230948554874.
    //local dens is body:atm:sealevelpressure 101325 * ( CONSTANT():E ^ ( - SHIP:ALTITUDE / 5000 ) ) * 1.2230948554874.

    set _termVel to sqrt( 250 * ship:body:mu / ( ((body:radius+ship:altitude) ^ 2) * dens * drag  ) ).

    //print "atmos = " + atmos + " atm".
    //print "dens = " + dens + " kg/m^3".
    //print "termvel = " + _termVel + " m/s".
    return _termVel.
  }

  return _termVel.
}

// not working
function getControlPart {
  for p in ship:parts {
    if (p:controlFrom) {
      return p.
    }
  }
}

function getThrustDirection {
  local myVariable is list().
  local totalThrust to ship:position.
  LIST ENGINES IN myVariable.

  for egn in myVariable {
    if (egn:stage = stage:number or (
      ship:availableThrust = 0 and egn:stage = stage:number - 1
    )) {
      set totalThrust to totalThrust + egn:facing:vector.
      //print egn:name.
      //local dv23 is vecDrawArgs(v(0,0,0), totalThrust, yellow, egn:name, 20, true).
    }
  }

  set totalThrust to totalThrust / myVariable:length.
  //local dv23 is vecDrawArgs(v(0,0,0), totalThrust, yellow, "totalThrust", 20, true).
  return totalThrust:direction.
}

// return fore error according facing along axis. for direction d.
function getForeErr {
  declare parameter v. // to minimize - srfprograde e.g.

  local proVec is vxcl( facing:rightVector, vxcl( facing:vector, v)).

  set v1:show to true.
  set v1:vector to proVec.
  set v1:scale to 10.
  set v1:label to "fore".

  local res is proVec:mag.
  if vang( facing:foreVector, proVec ) > 90 {
    set res to -res.
  }

  return res.
}

function getStarErr {
  declare parameter v.
  local dirVec is vxcl( facing:topvector, vxcl( facing:vector, v ) ).
  set v2:show to true.
  set v2:vector to dirVec.
  set v2:scale to 10.
  set v2:label to "star".
  //local res to vang(facing:vector, vxcl( facing:topvector, vec)).
  local res is dirVec:mag.
  // if on left side do it -0..-180
  if vang( facing:rightVector, dirVec ) > 90 { // we are facing  left of prograde
    set res to -res.
  }

  return res.
}

function getShipTorque {
  local totalTorque is 0.

  for p in ship:parts {

    if p:modules:contains( "ModuleReactionWheel" ) and 
      p:getModule("ModuleReactionWheel"):getField("reaction wheels") <> "Disabled" {
      local axisTorque is getPartTorque( p:name ).
      local medT is ( axisTorque[0] + axisTorque[1] + axisTorque[2] ) / 3.
      //set totalTorque to totalTorque + (medT / p:position:mag).
      set totalTorque to totalTorque + medT.
    }
  }

  return totalTorque.
}
