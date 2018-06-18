@LAZYGLOBAL OFF.
{
  import("lib/diskio.ks").
  import("lib/text.ks").
  local mission is import("lib/mission.ks").

  mission["loadMission"]("Missions/template.ks").
  mission["runMission"]().
}
