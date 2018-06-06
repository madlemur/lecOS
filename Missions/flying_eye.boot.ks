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
    "flying_eye_mission.ks"
  ) if not exists(dependency) copy dependency from 0.

  run mission_runner.v0.1.0.ks.
  run hillclimb.v0.1.0.ks.
  run maneuver.v0.1.0.ks.
  run flying_eye_mission.ks.

  run_mission(flying_eye_mission["sequence"], flying_eye_mission["events"]).
}
