{
  for dependency in list(
    "mission_runner.v0.1.0.ks",
    "launcher.v0.1.0.ks",
    "event_lib.v0.1.0.ks",
    "Missions/surveyor_mission.ks"
  ) {
      download(dependency, dependency).
      runpath("1:" + dependency).
    }
  local mission is surveyor_mission().
  run_mission(mission["sequence"], mission["events"]).
}
