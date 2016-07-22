// ComSat boot script
// Ken Cummins (madlemur)
//   based on work by
// Kevin Gisi
// http://youtube.com/gisikw

{
  for dependency in list(
    "mission_runner.v0.1.0.ks",
    "hillclimb.v0.1.0.ks",
    "maneuver.v0.1.0.ks",
    "launcher.v0.1.0.ks",
    "rabbit_ears_mission.ks",
    "event_lib.v0.1.0.ks"
  ) if not exists(dependency) copy dependency from 0.

  run mission_runner.v0.1.0.ks.
  run event_lib.v0.1.0.ks.
  run hillclimb.v0.1.0.ks.
  run maneuver.v0.1.0.ks.
  run launcher.v0.1.0.ks.
  run rabbit_ears_mission.ks.

  run_mission(rabbit_ears_mission["sequence"], rabbit_ears_mission["events"]).
}
