// Vanguard Mission Script
// KSProgramming - Cheers Kevin Games

local mission is import("mission").
local event_lib is import("event_lib").
local launcher is import("launcher").

local TARGET_ALTITUDE is 100000.
local circ is false.

local probester_mission is mission(mission_definition@).

function mission_definition {
  parameter seq, ev, data, next.

  seq:add(prelaunch@).
  function prelaunch {
    set ship:control:pilotmainthrottle to 0.
    gear off.
    brakes off.
    if(launcher["launch"](data, 90, TARGET_ALTITUDE)) {
      launcher["start_countdown"](5, data).
      next().
    }
  }

  seq:add(launch@).
  function launch {
    if launcher["countdown"](data) <= 0 {
      ev:add("staging", event_lib["staging"]).
      next().
    }
  }

  seq:add(meco@).
  function meco {
    if launcher["ascent_complete"](data) {
      next().
    }
  }

  seq:add(circularize@).
  function circularize {
    if data:haskey("circ") and data["circ"] {
      if launcher["circularized"]() {
        set circ to false.
        next().
      }
    } else {
      launcher["circularize"]().
      set data["circ"] to true.
    }
  }
}

export(probester_mission).
