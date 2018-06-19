@LAZYGLOBAL OFF.
{
    local self is lex(
        "checkStaging", checkStaging@,
        "deployFairings", deployFairings@
    ).

    local waitToStage is 2.
    local fairingATM is 0.05.
    local fairingAltPct is 0.9.
    local minScience is 5.
    local englist is false.

    local times is import("lib/time.ks").

    function checkStaging {
        parameter mission, name.
        // Can't stage, don't bother to check...
        if times["stageTime"]() < waitToStage {
          return false.
        }
        // We're going to cache the engine list to avoid walking the part tree every tick.
        if englist:istype("boolean") {
          pout("Enumerating engines", true).
          list engines in englist.
        }
        local flameout is false.
        for eng in englist { if eng:flameout { set flameout to true. break. } }
        if flameout or maxthrust = 0 {
          if flameout
            // Since an engine has flamed out, there's an implicit assumption that the engine list will change
            set englist to false.
          __["stage"]().
          steeringmanager:resetpids().
        }
    }

    function deployFairings {
        parameter mission, name.
        if body:atm:height * fairingAltPct < ship:altitude AND ship:Q < fairingATM {
            pout("Deploying/Jettisoning fairings.").
            FOR module IN SHIP:MODULESNAMED("ModuleProceduralFairing") { // Stock and KW Fairings
                // and deploys them
                module:DOEVENT("deploy").
            }.
            // Iterates over a list of all parts using the fairing module from the Procedural Fairings Mod
            FOR module IN SHIP:MODULESNAMED("ProceduralFairingDecoupler") { // Procedural Fairings
                // and jettisons them (PF uses the word jettison in the right click menu instead of deploy)
                module:DOEVENT("jettison").
            }.
            mission["delEvent"](name).
        }
    }
    export(self).
}
