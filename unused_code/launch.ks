@LAZYGLOBAL OFF.
parameter incl.
parameter orbalt.
run once lib_ui.
run once lib_staging.
run once maneuver.

local _p IS "launch".

//includes
LOCAL target_alt to MAX(orbalt, (SHIP:BODY:ATM:HEIGHT + 30000)).
LOCAL incl_init to 0.

if incl = 0 {
	set incl_init to 90.
} else {
	set incl_init to arcsin( cos(incl) /cos(SHIP:LATITUDE) ).
}
uiBanner(_p, "Launching for inclination: " + incl).

local v_eqrot to 2* constant:PI * SHIP:BODY:RADIUS / SHIP:BODY:ROTATIONPERIOD.
local v_orbit to sqrt ( SHIP:BODY:MU / target_alt).

local dir to arctan ((v_orbit * sin(incl_init) - v_eqrot*cos(SHIP:LATITUDE) ) /( v_orbit *cos(incl_init) )  ).

//local dir to incl_init.
uiBanner(_p, "Setting Direction to: " + round(dir,1)).

uiBanner(_p, "starting up").

SAS off.
//SAS on.

lock steering to heading(SHIP:HEADING,90).

lock THROTTLE to 0.0 .

uiBanner(_p, "Countdown").
uiBanner(_p, "3").
wait 1.
uiBanner(_p, "2").
wait 1.
uiBanner(_p, "1").
lock THROTTLE to 1.0 .
wait 1.


uiBanner(_p, "Engines Start").
stage.
// init_launch_autofunctions().
// autostage().


// Ascending and Turning Code
LOCAL need_turn to TRUE.
LOCAL once to TRUE.
LOCAL do_turn to TRUE.
LOCAL initial_pitch to 5.
LOCAL need_stage IS 0.
//LOCAL initial_pitch to 2.
LOCAL turn_end to (SHIP:BODY:ATM:HEIGHT).
if turn_end = 0 {
	set turn_end to 7000.
}

local pitch to 0.

UNTIL SHIP:OBT:APOAPSIS > target_alt {
	if checkStages() = 1 {
		stage.
	}
	if need_turn AND ALT:RADAR > 300 {

		if once {
			uiBanner(_p, "Initial roll started").
			set once to FALSE.
		}

		LOCAL tr to ((dir-SHIP:HEADING)/500).

		LOCAL pr to ((initial_pitch)/700).
		LOCAL direction_i to (SHIP:HEADING+(ALT:RADAR-300)*tr).
		LOCAL pitch_i to ((arccos (sqrt(SHIP:OBT:APOAPSIS/turn_end))) -((ALT:RADAR-300) *pr)).

		if direction_i > dir {
			set need_turn to FALSE.
			set direction_i to dir.
			uiBanner(_p, "Initial roll completed").
		}	else {

		lock steering to heading(direction_i,pitch_i).
		}
	}

	if  ALT:RADAR > 1000 {
		if do_turn {
			set pitch to (arccos (sqrt(SHIP:OBT:APOAPSIS/turn_end))-initial_pitch).
			if pitch < 0 {
				uiBanner(_p, "Turn completed").
				set do_turn to FALSE.
				set pitch to 0.
			}
		}
		LOCK STEERING TO HEADING(dir, pitch).
		// print "pitch: " + round(pitch,1) + "  " at (20,33).

	}
// 	auto_asparagus().
// 	autostage().

    // print "alt:radar: " + round(ALT:RADAR) + "  " at (0,33).
    // print "Thrust:    " + round(SHIP:AVAILABLETHRUST,1) + "   " at (0,34).

 //   print "apoapis: " + round(apoapsis/1000,3) at (0,35).
 //   print "periapis: " + round(periapsis/1000,3) at (20,35).

	wait 0.1.
}

// Ascending Finished. Circlet Code and other Stuff

lock THROTTLE to 0 .

uiBanner(_p, "waiting for exit of atmosphere").
set WARP TO 2.
wait until SHIP:ALTITUDE > BODY:ATM:HEIGHT.

set WARP TO 0.

PANELS on.
AG2 on.

// init_autostage().
MNV_SET_ALT(ETA:APOAPSIS,(SHIP:ORBIT:APOAPSIS/1000)).

wait 2.

// run_node().
MNV_EXEC_NODE(true).
MNV_CIRC().

//giving back control.
SAS off .
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
