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

uiBanner(_p, "Transfer braking burn").
// Circularize
MNV_CIRC().
