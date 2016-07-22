// ComSat boot script
// Ken Cummins (madlemur)
//   based on work by
// Kevin Gisi
// http://youtube.com/gisikw

{
  for dependency in list(
    "mission_runner.v0.1.0.ks",
    "navigate.v0.1.0.ks",
    "maneuver.v0.1.0.ks",
    "rendezvous.v0.1.0.ks",
    "transfer.v0.2.1.ks",
    "crew_transfer_1_mission.ks",
    "hillclimb.v0.1.0.ks"
  ) if not exists(dependency) copy dependency from 0.

  run mission_runner.v0.1.0.ks.
  run navigate.v0.1.0.ks.
  run maneuver.v0.1.0.ks.
  run rendezvous.v0.1.0.ks.
  run transfer.v0.2.1.ks.
  run crew_transfer_1_mission.ks.
  run hillclimb.v0.1.0.ks.

  run_mission(crew_transfer_1_mission["sequence"], crew_transfer_1_mission["events"]).
}
