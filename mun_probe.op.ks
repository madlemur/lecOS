// Rescue mission script
// Ken Cummins (madlemur)
//   based on work by
// Kevin Gisi
// http://youtube.com/gisikw

{
  local missionfiles is lex(
    "launch", "Missions/launch_mission.ks"
  ).

  for file in missionfiles:values {
    download(file, file).
    runpath("1:" + file).
  }

  local missions is list().
  missions:add(launch_mission(100000, 90, 750000)).

  local dependency is uniqueSet(
    "mission_runner.v0.1.0.ks",
    "transfer.v0.2.1.ks",
    "hillclimb.v0.1.0.ks",
    "maneuver.v0.2.0.ks"
  ).
  local mission_sequence is list().
  local mission_events is lex().

  for mission in missions {
    for lib in mission["dependency"] {
      dependency:add(lib).
    }
    for seq in mission["sequence"]
      mission_sequence:add(seq).
    if mission["events"]:length > 0
      for evt in mission["events"]:keys
        mission_events:add(evt, mission["events"][evt]).
  }
  for file in dependency {
    download(file, file).
    runpath("1:" + file).
  }
  mission_sequence:add("mun_transfer").
  mission_sequence:add({ parameter mission. transfer["seek"]("Mun", 20000). maneuver["exec"](). maneuver["set_apo"](20000). maneuver["exec"]().mission["next"](). }).
  mission_sequence:add("mission_complete").
  mission_sequence:add({ parameter mission. set deleteOnFinish to true. hudtext("Mission script completed.", 5, 2, 25, white, true). mission["terminate"](). }).

  run_mission(mission_sequence, mission_events).
}
