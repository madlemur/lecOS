{
  for dependency in list(
    "mission_runner.v0.1.0.ks",
    "launcher.v0.1.0.ks",
    "Missions/first_look_mission.ks",
    "event_lib.v0.1.0.ks",
    "science_lib.v0.1.ks"
  ) if not exists(dependency) copypath("0:"+dependency, path()).

  run mission_runner.v0.1.0.ks.
  run event_lib.v0.1.0.ks.
  run launcher.v0.1.0.ks.
  run science_lib.v0.1.ks.
  run first_look_mission.ks.

  run_mission(first_look_mission["sequence"], first_look_mission["events"]).
}
