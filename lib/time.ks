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

    local TIMES is lexicon("STAGE", -1).

    if EXISTS("times.json") {
        set TIMES to READJSON("times.json").
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
        WRITEJSON(TIMES, "times.json").
    }

    export(self).
}
