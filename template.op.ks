{
    for dependency in list(
      "mission_runner.ks",
      "navigate.ks",
      "maneuver.ks",
      "launcher.ks",
      "event_lib.ks"
    ) {
        import(dependency).
      }
    local mission is import("Missions/template_mission.ks").
    local mission_parameters is mission_file:build_mission(100000, 0, 0).
    run_mission(mission_parameters["sequence"], mission_parameters["events"], mission_parameters["data"]).
}
