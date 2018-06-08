// Template Mission Script
// KSProgramming - Cheers Kevin Games
{
    local event_lib is import("event_lib.ks").
    local launcher is import("launcher.ks").

    local template_mission is lexicon(
        "sequence", list(
          "preflight", preflight@,
          "launch", launch@,
          "ascent", ascent@,
          "final_circ", circularize@
        ),
        "events", lex(
        ),
        "data", lex(
            "target_altitude", 300000,
            "target_inclination", 15,
            "target_lan", 25
        )
    ).

    function preflight {
      parameter mission.
      set ship:control:pilotmainthrottle to 0.
      __["pOut"]("Launch parameters: " + template_mission["data"]["target_altitude"] + ":" + template_mission["data"]["target_inclination"] + ":" + template_mission["data"]["target_lan"]).
      set launchDetails to launcher["calcLaunchDetails"](template_mission["data"]["target_altitude"], template_mission["data"]["target_inclination"], template_mission["data"]["target_lan"]).
      mission["add_data"]("launch_azimuth", launchDetails[0], true).
      __["doWarp"](launchDetails[1]-5).
      if launcher["launch"](template_mission["data"]["target_altitude"], launchDetails[0], mission) {
        launcher["start_countdown"](5, mission).
        mission["next"]().
      } else {
        __["pOut"]("Unable to launch, mission terminated.", true).
        mission["terminate"]().
      }

    }

    function launch {
      parameter mission.
      if launcher["countdown"](mission) <= 0 {
        mission["add_event"]("staging", event_lib["staging"]).
        mission["next"]().
      }
    }

    function ascent {
      parameter mission.
      if launcher["ascent_complete"](mission) {
          mission["next"]().
        }
    }

    function circularize {
      parameter mission.
      if template_mission:haskey("circ") {
        if launcher["circularized"]() {
          template_mission:remove("circ").
          mission["next"]().
        }
      } else {
        launcher["circularize"]().
        set template_mission["circ"] to true.
      }
    }

    export(template_mission).
}
