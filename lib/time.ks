@LAZYGLOBAL OFF.
PRINT("LEC TIME v%VERSION_NUMBER%").
{
    local self is lexicon(
        "setTime", setTime@,
        "diffTime", diffTime@,
        "stageTime", diffTime@:BIND("STAGE")
    ).

    local TIMES is lexicon().

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
