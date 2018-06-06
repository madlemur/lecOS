clearscreen.

set inc to 45. // orbit inclination
set orbalt to 100 * 1000. // circular orbit altitude
set V_orb to sqrt( constant():G * body:mass / ( orbalt + body:radius)). // orbital velocity
set pit to 90. // initialize pitch

print "Launch azimuth script.".
print "Launches to a " + orbalt + "m orbit inclined " + inc + " degrees.".
print " ".
print "  current pitch = ".
print "        azimuth = ".
print "   corrected az = ".
print "hor orbital vel = ".

on ag1 { set pit to pit - 1. preserve. }.
on ag2 { set pit to pit + 1. preserve. }.


// Call to update the display of numbers:
declare function display_block {
	declare parameter
		startCol, startRow. // define where the block of text should be positioned

	print round(pit,2) + " degrees   " at (startCol,startRow).
	print round(az_orb,2) + " degrees   " at (startCol,startRow+1).
	print round(az_corr,2) + " degrees   " at (startCol,startRow+2).
	print round(orb_vel_h:mag,2) + " m/s   " at (startCol,startRow+3).
}.

set steer to heading(90, 90).
lock steering to steer.

until ship:apoapsis >= orbalt {
	set az_orb to arcsin ( cos(inc) / cos(ship:latitude)).

	if (abs(ship:obt:inclination - inc) < 0.1) {
		set steer to heading(az_orb, pit).
	} else {
		// project desired orbit onto surface heading
		set az_orb to arcsin ( cos(inc) / cos(ship:latitude)).
		// create desired orbit velocity vector
		set orb_vel to heading(az_orb, 0)*v(0, 0, V_orb).

		// find horizontal component of current orbital velocity vector
		set orb_vel_h to ship:velocity:orbit - vdot(ship:velocity:orbit, up:vector:normalized)*up:vector:normalized.

		// calculate difference between desired orbital vector and current (this is the direction we go)
		set vel_corr to orb_vel - orb_vel_h.

		// project the velocity correction vector onto north and east directions
		set vel_n to vdot(vel_corr, ship:north:vector:normalized).
		set vel_e to vdot(vel_corr, heading(90,0):vector:normalized).
		// calculate compass heading
		set az_corr to arctan2(vel_e, vel_n).

		// update our steering
		set steer to heading(az_corr, pit).
	}
	display_block(18,3).
	wait 0.001.
}.
set ship:control:pilotmainthrottle to 0.
