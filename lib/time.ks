@LAZYGLOBAL OFF.
PRINT("LEC TIME v%VERSION_NUMBER%").
{
    local self is lexicon(
        "setTime", setTime@,
        "diffTime", diffTime@,
        "hasTime", hasTime@,
        "delTime", delTime@,
        "stageTime", diffTime@:bind("STAGE")
    ).

    local TIMES is lexicon("STAGE", -9999999).

    if EXISTS("0:/times.json") {
        set TIMES to READJSON("0:/times.json").
    }

    FUNCTION hasTime {
      PARAMETER n.
      return TIMES:haskey(n).
    }
    FUNCTION delTime {
      PARAMETER n.
      if TIMES:haskey(n) {
        TIMES:remove(n).
        saveTimes().
      }
    }
    FUNCTION setTime
    {
      PARAMETER n, t IS TIME:SECONDS.
      SET TIMES[n] TO t.
      saveTimes().
    }

    FUNCTION diffTime
    {
      PARAMETER n.
      RETURN TIME:SECONDS - TIMES[n].
    }

    FUNCTION saveTimes {
        WRITEJSON(TIMES, "0:/times.json").
    }

    export(self).
}
