run once lib_challenge2.
run once lib_warp.
run once maneuver.

set SHIP:NAME to "Mun Crasher".
set TARGET to "Mun Lander".
stage.
wait 1.


stop_at_nc(TARGET:GEOPOSITION).
local landing_spot to TARGET:GEOPOSITION.
local target_alt to landing_spot:TERRAINHEIGHT + 615.
MNV_EXEC_NODE(true).


warp(ETA:PERIAPSIS-120).

// Reduce the error from run_node. this is from the game not the math.
lock steering to PROGRADE.
wait 15.
until (SHIP:ORBIT:PERIAPSIS - target_alt) > -1 {
	lock THROTTLE to 0.01.
	wait 0.
	lock THROTTLE to 0.0.
}
print "Prograde ok".
lock steering to (-1 * SHIP:VELOCITY:SURFACE).
wait 15.

until (SHIP:ORBIT:PERIAPSIS - target_alt) < 1 {
	lock THROTTLE to 0.01.
	wait 0.
	lock THROTTLE to 0.0.
}
print "Retrograde ok".


lock steering to (-1 * SHIP:VELOCITY:SURFACE).

local eng_stats to MNV_ENGINE_STATS().
local ch_rate to  eng_stats["MassRate"].
local v_e to  eng_stats["ExitVel"].
local M to SHIP:MASS.
local v_burn to VELOCITYAT(SHIP,TIME:SECONDS+ETA:PERIAPSIS):SURFACE:MAG.

local t to MNV_BURN_TIME(v_burn).
local stop_distance to v_burn*t - (v_e*(t - M/ch_rate) *ln(M/(M-t*ch_rate)) + v_e*t) .

// wait until its time to start burning.
wait until (SHIP:POSITION - landing_spot:POSITION):MAG <= (stop_distance+80).

lock throttle to 1.0.
// better early than to late
gear on.

// We have mostly horizontal speed, kill it.
wait until SHIP:VELOCITY:SURFACE:MAG < 8.5.

local lock my_grav to BODY:MU/((BODY:RADIUS+ SHIP:ALTITUDE)^2).
local lock t_set to 1.00*(SHIP:MASS*my_grav/ship:maxthrust).
print "t_set:   " + round(t_set,2).
lock THROTTLE to t_set.



wait until ((ALT:RADAR < 0.5) OR (SHIP:STATUS = "LANDED") OR (SHIP:OBT:VELOCITY:SURFACE:MAG < 1.0)).

lock THROTTLE to 0.
lock steering to lookdirup(UP:Vector, ship:facing:topvector).
wait 5.
clearscreen.

print "".
local d_target to round((SHIP:POSITION - TARGET:POSITION):MAG,1).
print "We landed "+d_target +" m from our target".

wait 5.
SAS off.
