@LAZYGLOBAL OFF.
pout("LEC EVENTS v%VERSION_NUMBER%").
{
    local self is lex(
        "checkStaging", checkStaging@,
        "deployFairings", deployFairings@,
        "deployPanels", deployPanels@
    ).

    local waitToStage is 1.
    local fairingATM is 0.05.
    local fairingAltPct is 0.9.
    local panelsAltPct is 1.05.
    local minScience is 5.
    local englist is false.

    local times is import("lib/time.ks", false).
    local staging is import("lib/staging.ks", false).

    function checkStaging {
        parameter mission, name.
        // Can't stage, don't bother to check...
        if times["stageTime"]() < waitToStage {
          return false.
        }
        if staging["stagingCheck"]() {
            __["stage"]().
            steeringManager:resetPids().
        }
    }

    function deployFairings {
        parameter mission, name.
        if body:atm:height * fairingAltPct < ship:altitude AND ship:Q < fairingATM {
            pout("Deploying/Jettisoning fairings.").
            FOR module IN SHIP:MODULESNAMED("ModuleProceduralFairing") { // Stock and KW Fairings
                // and deploys them
                if module:HASEVENT("deploy") {
                  module:DOEVENT("deploy").
                }
            }.
            // Iterates over a list of all parts using the fairing module from the Procedural Fairings Mod
            FOR module IN SHIP:MODULESNAMED("ProceduralFairingDecoupler") { // Procedural Fairings
                // and jettisons them (PF uses the word jettison in the right click menu instead of deploy)
                if module:HASEVENT("jettison") {
                  module:DOEVENT("jettison").
                }
            }.
            mission["startEvent"]("panels").
            mission["delEvent"](name).
        }
    }

    function deployPanels {
        parameter mission, name.
        if body:atm:height * panelsAltPct < ship:altitude {
            pout("Deploying solar panels").
            panels on.
            mission["delEvent"](name).
        }
        if mission["hasEvent"]("fairings") {
          mission["pauseEvent"](name).
        }
    }
    export(self).
}
