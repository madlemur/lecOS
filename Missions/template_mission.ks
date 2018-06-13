// Template Mission Script
// KSProgramming - Cheers Kevin Games
{
    local event_lib is import("event_lib.ks").
    local launcher is import("launcher.ks").

    local t_m is lexicon(
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
            "target_lan", 25,
            "pitch_alt", 250,
            "curve_alt", BODY:ATM:HEIGHT * 0.9,
            "fairings_alt", BODY:ATM:HEIGHT * 0.75
        )
    ).

    function preflight {
      parameter mission.
      set ship:control:pilotmainthrottle to 0.
      __["pOut"]("Launch parameters: " + t_m["data"]["target_altitude"] + ":" + t_m["data"]["target_inclination"] + ":" + t_m["data"]["target_lan"]).
      set launchDetails to launcher["calcLaunchDetails"](
          t_m["data"]["target_altitude"],
          t_m["data"]["target_inclination"],
          t_m["data"]["target_lan"]
      ).
      __["setTime"]("launch", launchDetails[1]).
      launcher["launch_init"](
        t_m["data"]["target_altitude"],
        launchDetails[0],
        t_m["data"]["target_inclination"],
        t_m["data"]["pitch_alt"],
        t_m["data"]["curve_alt"]
      ).
      if launchDetails[1] > TIME:SECONDS + 60
        __["doWarp"](launchDetails[1]-10).
      if launcher["launch"](t_m["data"]["target_altitude"], launchDetails[0]) {
        launcher["start_countdown"](5).
        mission["next"]().
      } else {
        __["pOut"]("Unable to launch, mission terminated.", true).
        mission["terminate"]().
      }
    }

    function launch {
      parameter mission.
      if launcher["countdown"]() >= 0 {
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

    function circularize {
      parameter mission.
      if t_m:haskey("circ") {
        if launcher["circularized"]() {
          t_m:remove("circ").
          mission["next"]().
        }
      } else {
        launcher["circularize"]().
        set t_m["circ"] to true.
      }
    }

    export(t_m).
}
