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
    
    FUNCTION hasTime {
      PARAMETER n.
      return TIMES:haskey(n).
    }
    FUNCTION delTime {
      PARAMETER n.
      if TIMES:haskey(n)
        TIMES:remove(n).
    }
    FUNCTION setTime
    {
      PARAMETER n, t IS TIME:SECONDS.
      SET TIMES[n] TO t.
    }

    FUNCTION diffTime
    {
      PARAMETER n.
      RETURN TIME:SECONDS - TIMES[n].
    }

    export(self).
}
