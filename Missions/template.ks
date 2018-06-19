@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local mission_list is list (
        "PreLaunch", { parameter mission. pout("PreLaunch"). wait(5). mission["next"](). },
        "Launch", { parameter mission. pout("Whee!"). lock throttle to 1. lock steering to heading(90, lpitch()). mission["startEvent"]("staging"). mission["next"](). },
        "Ascend", { parameter mission. if ship:apoapsis > 100000 { lock throttle to max(0, ((100005-SHIP:APOAPSIS)/1000)). mission["next"](). } },
        "Coast", { parameter mission. if ship:altitude > body:atm:height AND ship:apoapsis > 100000 { panels on. mission["next"](). } },
        "WaitApo", { parameter mission. if eta:apoapsis < 10 { lock throttle to th. lock steering to st. mission["next"](). } },
        "Circularize", { parameter mission. if circularize() { lock throttle to 0. lock steering to body("sun"):position. wait(5). unlock throttle. unlock steering. mission["endMission"](). } }
    ).
    local th is 0.
    local st is ship:prograde:forevector.

    function lpitch {
      if altitude > 250
        RETURN MIN(90,MAX(0, MAX(90 * (1 - SQRT(ALTITUDE/60000)),45-VERTICALSPEED))).
      else
        return 90.
    }
    function circularize {
      local a0 is 2.                  // aoa limit
      local kt is 2.                  // gain factor

      local sc is sqrt(body:mu/(body:radius+altitude)). //circular speed
      local hv is vxcl(up:vector,velocity:orbit):normalized. //horizontal velocity
      local ev to hv*sc-velocity:orbit.
      if ev:mag < 0.05 return true.
      local ad is 1-vang(facing:vector,ev)/a0.
      set st to lookdirup(ev,facing:topvector).
      set th to min(ad*kt*ev:mag*mass/max(1,maxthrust),1).
      if ship:availablethrust = 0 { set th to max(th,0.05). }
      return false.
    }
    mission["setSequence"](mission_list).
}
