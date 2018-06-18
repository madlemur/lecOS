@LAZYGLOBAL OFF.
{
  PARAMETER msn.
  local template_mission is list(
    "Pre-Launch", msg@:bind("PreLaunch", 5),
    "Launch", msg@:bind("Launch", 15),
    "MECO", msg@:bind("MECO", 5)
  ).
  local times is import("lib/time.ks").

  function msg {
    parameter msgText, ttl, mission.
    if times["hasTime"]("msg") AND times["diffTime"]("msg") >= ttl
      times["delTime"]("msg").
      mission["next"]().
    else if times["hasTime"]("msg")
      wait(0.1).
    else {
      phud(msgText).
      times["setTime"]("msg").
    }

  }
  msn["setSequence"](template_mission).
}
