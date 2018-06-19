@LAZYGLOBAL OFF.
{
    parameter mission.
    local mission_list is list (
        "PreLaunch", { parameter mission. pout("PreLaunch"). wait(5). mission["next"](). },
        "Launch", { parameter mission. pout("Whee!"). lock throttle to 1. lock steering to heading(90, lpitch()). mission["startEvent"]("staging"). mission["next"](). },
        "Ascend", { parameter mission. if ship:apoapsis > 85000 { lock throttle to 0. mission["next"](). } },
        "Coast", { parameter mission. if ship:altitude > body:atm:height { panels on. mission["next"](). } },
        "Circularize", { parameter mission. if eta:apoapsis < 5 { circularize(). mission["endMission"](). } wait(1). }
    ).
    function lpitch {
      if altitude > 250
        RETURN MIN(90,MAX(0, MAX(90 * (1 - SQRT(ALTITUDE/60000)),45-VERTICALSPEED))).
      else
        return 90.
    }
    function circularize {
      local a0 is 2.                  // aoa limit
      local kt is 2.                  // gain factor
      local hz is 10.                 // controller rate

      local st is facing.
      local th is 0.
      lock steering to st.
      lock throttle to th.

      until false {
        local sc is sqrt(body:mu/(body:radius+altitude)). //circular speed
        local hv is vxcl(up:vector,velocity:orbit):normalized. //horizontal velocity
        local ev to hv*sc-velocity:orbit.
        if ev:mag < 0.05 break.
        local ad is 1-vang(facing:vector,ev)/a0.
        set st to lookdirup(ev,facing:topvector).
        set th to min(ad*kt*ev:mag*mass/max(1,maxthrust),1).
        if ship:availablethrust = 0 { set th to max(th,0.05). }
        wait 1/hz.
      }
      set th to 0.
      wait 1.
      unlock steering.
      set ship:control:pilotmainthrottle to 0.
      unlock throttle.
    }
    mission["setSequence"](mission_list).
}
