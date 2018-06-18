@LAZYGLOBAL OFF.
{
  import("lib/diskio.ks").
  import("lib/text.ks").
  local mission is import("lib/mission.ks").
  import("lib/time.ks").
  mission["loadMission"]().
  mission["runMission"]().
}
