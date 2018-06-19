@LAZYGLOBAL OFF.
{
  import("lib/diskio.ks").
  import("lib/text.ks").
  local mission is import("lib/mission.ks").
  local events is import("lib/events.ks").

  mission["loadMission"]("Missions/template.ks").

  mission["addEvent"]("fairings", events["deployFairings"]).
  mission["addEvent"]("staging", events["checkStaging"]).
  mission["pauseEvent"]("staging"). // Don't start staging just yet...

  mission["runMission"]().
}
