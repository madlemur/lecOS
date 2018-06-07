lock tr to alt:radar.
lock g to constant:g * body:mass / body:radius^2.
lock md to (ship:availablethrust / ship:mass) - g.
lock sd to ship:verticalspeed^2 / (2 * md).
lock it to sd / tr.
lock im to tr / abs(ship:verticalspeed).

WAIT UNTIL ship:verticalspeed < -1.
  print "Preparing for hoverslam...".
  rcs on.
  brakes on.
  lock steering to srfretrograde.
  when im < 3 then {gear on.}

WAIT UNTIL tr < sd + 2.
  print "Performing hoverslam".
  lock throttle to it.

WAIT UNTIL ship:verticalspeed > -0.01.
  print "Hoverslam completed".
  set ship:control:pilotmainthrottle to 0.
  rcs off.
