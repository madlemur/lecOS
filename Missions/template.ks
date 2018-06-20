@LAZYGLOBAL OFF.
{
    // This sample mission should get a craft into about a 100km equitorial orbit,  staging, jettisoning fairings, and deploying solar panels as it goes.
    parameter mission.
    local launch is import("lib/launch.ks").
    local mission_list is list (
        "PreLaunch", { parameter mission. local l_detail is launch["calcLaunchDetails"](100000, 15, 59). for d in l_detail { pout(d). }. set l_time to l_detail[1]. lock steering to heading(l_detail[0], 90). lock throttle to 1. __["warpUntil"](l_time - 15). mission["next"](). },
        "Launch", { parameter mission. if TIME:SECONDS > l_time mission["startEvent"]("staging"). if SHIP:AIRSPEED > 100 { mission["next"](). } },
        "Turn", { parameter mission. lock steering to st. setSteering(). mission["next"](). },
        "Ascend", { parameter mission. setSteering(). if ship:apoapsis > 100000 { lock throttle to max(0, ((100005-SHIP:APOAPSIS)/700)). mission["next"](). } },
        "Coast", { parameter mission. setSteering(). if ship:altitude > body:atm:height AND ship:apoapsis > 100000 { panels on. mission["next"](). } },
        "WaitApo", { parameter mission. if ship:altitude + 100 > ship:apoapsis { lock throttle to th. RCS ON. mission["next"](). } },
        "Circularize", { parameter mission. if circularize() { lock throttle to 0. lock steering to body("sun"):position. wait(5). RCS OFF. unlock throttle. unlock steering. mission["endMission"](). } }
    ).
    local th is 0.
    local st is ship:prograde:forevector.
    local l_time is 0.

    function setSteering {
      set st to heading(launch["getBearing"](),launch["getPitch"]()).
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
