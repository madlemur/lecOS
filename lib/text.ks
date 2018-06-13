@LAZYGLOBAL OFF.
PRINT("LEC TEXT v%VERSION_NUMBER%").
{
    local self is lexicon(
        "init", init@,
        "formatTS", formatTS@,
        "formatMET", formatMET@
    )

    LOCAL INIT_MET_TS IS -1.
    LOCAL INIT_MET IS "".

    FUNCTION formatTS
    {
        PARAMETER u_time1, u_time2 IS TIME:SECONDS.
        LOCAL ts IS (TIME - TIME:SECONDS) + ABS(u_time1 - u_time2).
        RETURN "[T+" + padRep(2,"0",ts:YEAR - 1) + " " + padRep(3,"0",ts:DAY - 1) + " " + ts:CLOCK + "]".
    }

    FUNCTION formatMET
    {
        LOCAL m IS ROUND(MISSIONTIME).
        IF m > INIT_MET_TS {
            SET INIT_MET_TS TO m.
            SET INIT_MET TO formatTS(TIME:SECONDS - m).
        }
        RETURN INIT_MET.
    }

    export(self).
}
