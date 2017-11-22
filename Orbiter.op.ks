{
  set mission_builder to import("mission_builder.v0.1.0.ks").
  mission_builder["add_mission"](import("Missions/launch_mission.ks")(95000, 10, 115000, 120)).
  mission_builder["run_mission"]().
}
