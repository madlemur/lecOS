// Herald Boot Script
// Kevin Gisi
// http://youtube.com/gisikw

{
  for dependency in list(
    "mission_runner.v0.1.0.ks",
    "hillclimb.v0.1.0.ks",
    "maneuver.v0.1.0.ks",
    "starwalker_mission.ks"
  ) if not exists(dependency) copy dependency from 0.

  run mission_runner.v0.1.0.ks.
  run hillclimb.v0.1.0.ks.
  run maneuver.v0.1.0.ks.
  run starwalker_mission.ks.

  run_mission(starwalker_mission["sequence"], starwalker_mission["events"]).
}
