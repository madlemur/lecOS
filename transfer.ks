/////////////////////////////////////////////////////////////////////////////
// Transfer to target
/////////////////////////////////////////////////////////////////////////////
// Hohmann transfer to a satellite of the vessel's SoI body.
/////////////////////////////////////////////////////////////////////////////
run once lib_ui.
run once maneuver.
run once navigate.

LOCAL _p IS "Transfer".

if ship:body <> target:body {
  uiError(_p, "Target outside of SoI").
  wait 5.
  reboot.
}

local ri is abs(obt:inclination - target:obt:inclination).

if ri > 0.25 {
  uiBanner(_p, "Align planes with " + target:name).
  NAV_INC_TGT().
  MNV_EXEC_NODE(true).
}

NAV_HOH().
uiBanner(_p, "Transfer injection burn").
MNV_EXEC_NODE(true).

until obt:transition <> "encounter" {
  // run warp(eta:transition+1).
}

// TODO - deal with collision (radial burn)
local newAlt is target:radius * 0.5.
if target:atm:height > newAlt {
  set newAlt to target:atm:height * 1.25.
}
if periapsis < newAlt {
  local radialDir is ship:up.
  lock steering to radialDir.
  wait until vang(radialDir:forevector, heading:forevector) < 3.
  lock throttle to MAX(0, MIN(1, (newAlt - periapsis) / 1000)).
  wait until periapsis >= newAlt.
  lock throttle to 0.
}

uiBanner(_p, "Transfer braking burn").
// Circularize
MNV_CIRC().
