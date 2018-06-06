// Template Mission Script
// KSProgramming - Cheers Kevin Games

local maneuver is import("maneuver.ks").
local event_lib is import("event_lib.ks").
local launcher is import("launcher.ks").
local navigate is import("navigate.ks").

local mission is lexicon(
    "sequence", list(
      "preflight", preflight@,
      "launch", launch@,
      "ascent", ascent@
    ),
    "events", lex(
      "transmitScience", science_lib["transmitScience"]
    ),
    "data", lex(
        "target_altitude", 100000,
        "target_inclination", 0,
        "target_lan", 0
    )
).

function preflight {
  parameter mission.

  set ship:control:pilotmainthrottle to 0.
  __["pOut"]("Launch parameters: " + mission["get_data"]("target_altitude") + ":" + mission["get_data"]("target_inclination") + ":" + mission["get_data"]("target_lan")).
  if launcher["launch"](orbiter_mission["target_heading"], orbiter_mission["target_altitude"], orbiter_mission["final_altitude"]) {
    launcher["start_countdown"](5).
    mission["next"]().
  } else {
    __["pOut"]("Unable to launch, mission terminated.", true).
    mission["terminate"]().
  }

}

function launch {
  parameter mission.
  if launcher["countdown"]() <= 0 {
    mission["add_event"]("staging", event_lib["staging"]).
    mission["next"]().
  }
}

function ascent {
  parameter mission.
  if launcher["ascent_complete"]() {
      mission["next"]().
    }
}

export(mission).
