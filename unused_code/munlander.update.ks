DOWNLOAD("lib_ui.ks").
DOWNLOAD("maneuver.ks").
DOWNLOAD("lib_staging.ks").
DOWNLOAD("docking.ks").
DOWNLOAD("navigate.ks").

DOWNLOAD("mun_crasher.ks").
DOWNLOAD("transfer.ks").
DOWNLOAD("launch.ks").

run once lib_ui.
local _p IS "munlander".
run launch(0,150000).
ship:partstagged("StickAnt")[0]:getmodule("RTAntenna"):doaction("Activate").
ship:partstagged("DishAnt")[0]:getmodule("RTAntenna"):setfield("target", "Kerbin").
ship:partstagged("DishAnt")[0]:getmodule("RTAntenna"):doaction("Activate").
SET TARGET TO BODY("Mun").
run transfer.
WAIT 5.
uiBanner(_p, "WAITING FOR TARGET ACQUISITION!").
ag1 off.
wait until ag1.
run once docking.
dok_dock("dock","dock2").
// wait 15.
ag1 off.
uiBanner(_p, "WAITING FOR TARGET ACQUISITION!").
wait until ag1.
//SET target TO VESSEL("Mun Lander II").
run mun_crasher.
