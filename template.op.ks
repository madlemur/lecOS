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
    run_mission(mission["sequence"], mission["events"], mission["data"]).
}
