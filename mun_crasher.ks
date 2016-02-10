run lib_challenge2.
run lib_warp.

set SHIP:NAME to "Mun Crasher".
set TARGET to "Mun Lander".
stage.
wait 1.


stop_at_nc(TARGET:GEOPOSITION).
local landing_spot to TARGET:GEOPOSITION.
local target_alt to landing_spot:TERRAINHEIGHT + 615.
run_node().


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

local eng_stats to get_engine_stats().
local ch_rate to  eng_stats[2].
local v_e to  eng_stats[3].
local M to SHIP:MASS.
local v_burn to VELOCITYAT(SHIP,TIME:SECONDS+ETA:PERIAPSIS):SURFACE:MAG.

local t to get_burn_t(v_burn).
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

// Throw this at the end of your script to have it print out the optimal Delta V.
if ship:status = "LANDED" {

    set M0 to 24.92998.
    set M1 to mass.
    set ISP to 350.
    set g0 to 9.80665.

    set DeltaV_used to g0*ISP*ln(M0/M1).

    set Rf to ship:body:radius + altitude.
    set Rcir to ship:body:radius + 100000.
    set u to ship:body:MU.
    set a to (Rf + Rcir)/2.
    set e to (Rcir - Rf)/(Rf + Rcir).
    set Vgrnd to 2*Rf*(constant():pi)/138984.38.
    set Vcir to sqrt(u/Rcir).
    set Vap to sqrt(((1 - e)*u)/((1 + e)*a)).
    set Vper to sqrt(((1 + e)*u)/((1 - e)*a)).
    set DeltaV_opt to (Vcir - Vap) + (Vper-Vgrnd).
    set Deviation to DeltaV_used - DeltaV_opt.

    print "You used " + round(Deviation,2) + "m/s more than the optimal" .

}
print "".
local d_target to round((SHIP:POSITION - TARGET:POSITION):MAG,1).
print "We landed "+d_target +" m from our target".

wait 5.
SAS off.
