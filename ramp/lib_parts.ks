@LAZYGLOBAL OFF.
{
  LOCAL lib_parts is LEXICON(
    "ExtendAntennas", ExtendAntennas@,
    "RetractAntennas", RetractAntennas@,
    "ControlFromDockingPort", ControlFromDockingPort@,
    "DeployFairings", DeployFairings@
  ).

  FUNCTION ExtendAntennas {
      FOR P IN SHIP:PARTS {
          IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
              LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
              FOR A IN M:ALLACTIONNAMES() {
                  IF A:CONTAINS("Extend") { M:DOACTION(A,True). }
              }.
          }
      }.
  }

  FUNCTION RetractAntennas {
      FOR P IN SHIP:PARTS {
          IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
              LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
              FOR A IN M:ALLACTIONNAMES() {
                  IF A:CONTAINS("Retract") { M:DOACTION(A,True). }
              }.
          }
      }.
  }

  //Try to control from the specified docking port.
  FUNCTION ControlFromDockingPort {
      parameter cPart. //The docking port you want to control from.
      local success is false.

      // Try to control from the port
      if cPart:MODULES:CONTAINS("ModuleDockingNode") {
          LOCAL M IS cPart:GETMODULE("ModuleDockingNode").
          FOR Event IN M:ALLEVENTNAMES() {
              IF Event:CONTAINS("Control") { M:DOEVENT(Event). success on. }
          }.
      }

      // Try to open/deploy the port
      if cPart:MODULES:CONTAINS("ModuleAnimateGeneric") {
          LOCAL M IS cPart:GETMODULE("ModuleAnimateGeneric").
          FOR Event IN M:ALLEVENTNAMES() {
              IF Event:CONTAINS("open") or Event:CONTAINS("deploy") or Event:CONTAINS("extend") { M:DOEVENT(Event). }
          }.
      }

      Return success.
  }

  FUNCTION DeployFairings {
      FOR P IN SHIP:PARTS {
          IF P:MODULES:CONTAINS("ModuleProceduralFairing") {
              LOCAL M IS P:GETMODULE("ModuleProceduralFairing").
              FOR Event IN M:ALLEVENTNAMES() {
                  IF Event:CONTAINS("deploy") M:DOEVENT(Event).
              }.
          }
      }.
  }

  export(lib_parts).
}
