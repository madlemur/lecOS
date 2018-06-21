@LAZYGLOBAL OFF.
{
  local diskio is import("lib/diskio.ks").

  import("lib/text.ks").

  local mission is import("lib/mission.ks").
  diskio["delfile"]("lib/mission.ks").

  local events is import("lib/events.ks").

  import("lib/launch.ks").
  diskio["delfile"]("lib/launch.ks").

  mission["loadMission"]("Missions/template.ks").

  mission["addEvent"]("fairings", events["deployFairings"]).
  mission["addEvent"]("panels", events["deployPanels"]).
  mission["addEvent"]("staging", events["checkStaging"], false).

  mission["runMission"]().
}
