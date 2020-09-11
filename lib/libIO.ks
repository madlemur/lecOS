@lazyGlobal off.

{
    local L_F is "".

    // UI and I/O functions for consistient formatting and display
    GLOBAL padRepl is
    {
        PARAMETER left, str, txt.
        RETURN (""+txt):PADLEFT(left):REPLACE(" ",str).
    }.

    GLOBAL fmtDateTime is
    {
        PARAMETER ts IS TIME:SECONDS.
        RETURN "[" + padRepl(4,"0",ts:YEAR - 1) + " " + padRepl(3,"0",ts:DAY - 1) + " " + ts:CLOCK + "]".
    }.

    GLOBAL fmtTime is
    {
        PARAMETER ts IS TIME:SECONDS.
        RETURN "[" + ts:CLOCK + "]".
    }.

    GLOBAL logText is
    {
        PARAMETER txt.
        IF L_F <> "" { 
            LOG txt TO L_F. 
        }
    }.

    GLOBAL printOut is
    {
        PARAMETER t, wt IS TRUE.
        IF wt { SET t TO fmtDateTime() + " " + t. }
        PRINT t.
        logText(t).
    }.

    GLOBAL beginLog is
    {
        PARAMETER logFile IS "0:/log/" + padRepl(0,"_",SHIP:NAME) + ".txt".
        SET L_F TO logFile.
        IF logFile <> "" { 
            logText(SHIP:NAME).
            printOut("Log file: " + L_F). 
        }
    }.

    GLOBAL hudMsg is
    {
        PARAMETER txt, clr IS YELLOW, sz IS 40.
        HUDTEXT(txt, 3, 2, sz, clr, FALSE).
        printOut("HUD: " + txt).
    }.
}