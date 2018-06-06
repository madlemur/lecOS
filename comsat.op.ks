// Herald Boot Script
// Kevin Gisi
// http://youtube.com/gisikw

{
  for dependency in list(
    "mission_runner.v0.1.0.ks",
    "navigate.v0.2.0.ks",
    "maneuver.v0.2.0.ks",
    "launcher.v0.1.0.ks",
    "event_lib.v0.1.0.ks",
    "Missions/comsat_mission.ks"
  ) {
      download(dependency, dependency).
      runpath("1:" + dependency).
    }
  local mission is comsat_mission(100000, 90, 550000).
  run_mission(mission["sequence"], mission["events"]).
}
