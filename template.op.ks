{
    for dependency in list(
      "mission_runner.ks",
      "launcher.ks",
      "event_lib.ks"
    ) {
      __["pOut"]("Importing " + dependency).
        local lib is import(dependency).
      }
    local mission is import("Missions/template_mission.ks").
    run_mission(mission["sequence"], mission["events"], mission["data"]).
}
