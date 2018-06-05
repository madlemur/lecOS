{
  global science_lib is lex(
    "version", "0.1.0",
    "transmitScience", transmitScience@
  ).

  function transmitScience {
    parameter mission.
    for pmod in ship:modulesnamed("ModuleScienceExperiment") {
      if pmod:HASDATA {
        pmod:TRANSMIT.
      }
    }
  }
}
