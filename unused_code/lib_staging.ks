@lazyglobal off.

function checkStages {
  local myEngines is list().
  // I use long variables to avoid reference to others
  list engines in myEngines.

  for shipEngine in myEngines {

    if ( shipEngine:flameout ) {
      local currentStage to shipEngine:stage.
      local parentPart to shipEngine.
      local foundDecoupler to false.

      until not(parentPart:hasparent) {
        if (
          parentPart:modules:contains("ModuleAnchoredDecoupler") and
          parentPart:stage = shipEngine:stage - 1 
        ) {
          //print "found for " + shipEngine + " dec " + parentPart.
          set foundDecoupler to true.
          break.
        }

        set parentPart to parentPart:parent.
      }

      if ( foundDecoupler ) {
        //print "stage flameout engines!".
        // stage.
        return 1.
      }
    }
    //print e:stage + " " + e:parent:parent:stage.
  }

  IF (SHIP:LIQUIDFUEL > 0) AND (STAGE:LIQUIDFUEL < 0.01) AND (STAGE:SOLIDFUEL < 0.01) {
    //PRINT "ENGINE START REQUIRED".
    // STAGE.
    return 1.
  }

  return 0.
}
