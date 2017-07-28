// Herald Boot Script
// Kevin Gisi
// http://youtube.com/gisikw

{
  for dependency in list(
    "mission_runner.v0.1.0.ks",
    "hillclimb.v0.1.0.ks",
    "maneuver.v0.2.0.ks",
    "launcher.v0.1.0.ks",
    "Missions/comsat_mission.ks",
    "event_lib.v0.1.0.ks"
  ) if not exists(dependency) copypath("0:"+dependency, "1:").

  run "mission_runner.v0.1.0.ks".
  run "hillclimb.v0.1.0.ks".
  run "maneuver.v0.2.0.ks".
  run "launcher.v0.1.0.ks".
  run "event_lib.v0.1.0.ks".
  run "comsat_mission.ks".

  run_mission(comsat_mission["sequence"], comsat_mission["events"]).
}
