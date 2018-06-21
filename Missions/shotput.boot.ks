// Herald Boot Script
// Kevin Gisi
// http://youtube.com/gisikw

{
  for dependency in list(
    "mission_runner.v0.1.0.ks",
    "hillclimb.v0.1.0.ks",
    "maneuver.v0.1.0.ks",
    "shotput_mission.ks"
  ) if not exists(dependency) copy dependency from 0.

  run mission_runner.v0.1.0.ks.
  run hillclimb.v0.1.0.ks.
  run maneuver.v0.1.0.ks.
  run shotput_mission.ks.

  run_mission(shotput_mission["sequence"], shotput_mission["events"]).
}
