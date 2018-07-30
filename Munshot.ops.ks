@LAZYGLOBAL OFF.
{
  import("lib/diskio.ks", false).
  import("lib/text.ks", false).
  import("lib/staging.ks", false).
  local mission is import("lib/mission.ks", false).
  local events is import("lib/events.ks", false).
  import("lib/launch.ks", false).
  import("lib/maneuver.ks", false).
  import("lib/mun.ks", false).

  mission["loadMission"]("Missions/Munshot.ks").

  mission["addEvent"]("fairings", events["deployFairings"]).
  mission["addEvent"]("panels", events["deployPanels"]).
  mission["addEvent"]("staging", events["checkStaging"], false).

  mission["runMission"]().
}
