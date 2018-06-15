@LAZYGLOBAL OFF.
IF HOMECONNECTION:ISCONNECTED AND EXISTS("0:/lib/logo.ks"){
    RUNPATH("0:/lib/logo.ks").
}
PRINT("LEC_OS v%VERSION_NUMBER%").
{
    local d is lex().
    local s is stack().
    local IS_LOGGING is false.
    local LOGFILE is "".
    local boot_lib is lex(
        "stage", _stage@,
        "mAngle", mAngle@,
        "killWarp", killWarp@,
        "warpUntil", warpUntil@
        "doWarp", doWarp@
    )
    global import is {
        parameter n.
        local f is libname(n).
        if d:haskey(f) {
            return d[f].
        }
        if exists("0:/"+n) {
            s:push(f).
            local p is "1:/"+n.
            if d:haskey("diskio") {
                set p to d["diskio"]["loadfile"](n).
                d["diskio"]["runfile"](p).
            } else {
                copypath("0:/"+n, p).
                RUNONCEPATH(p).
            }
            return d[f].
        }
        return "".
    }.
    global export is {
        parameter v.
        if v:haskey("init") {
            v["init"]().
        }
        set d[s:pop()] to v.
    }.
    global isImported is {
        parameter n.
        local f is libname(n).
        return d:haskey(f).
    }.
    function libname {
        parameter n.
        local f is n.
        if f:endswith(".ks") {
            set f to f:substring(0, f:length - 3).
        }
        if f:contains("/") {
            local fp is f:split("/").
            set f to fp[fp:length -1].
        }
        return f.
    }
    global phud is {
        PARAMETER t, del is 3, pos is 2, s IS 40, c IS YELLOW, ec is FALSE.
        HUDTEXT(t, del, pos, s, c, ec).
        pout("HUD: " + t).
    }.
    global pout is {
        PARAMETER t, wt IS TRUE.
        IF wt and d:haskey["text"] { SET t TO d["text"]["formatMET"] + " " + t. }
        PRINT t.
        plog(t).
    }.
    global plog is {
        PARAMETER t.
        IF IS_LOGGING and exists(LOGFILE) { LOG t TO LOGFILE. }
    }.
    global slog is {
        PARAMETER f IS padRep(0,'_',SHIP:NAME) + ".log".
        if d:haskey("diskio") {
            set LOGFILE to d["diskio"]["findspace"](f, 2048).
        } else {
            set LOGFILE to "1:/"+f.
        }
        set IS_LOGGING to not IS_LOGGING.
        if IS_LOGGING and not exists(LOGFILE) {
            LOG "New log started" to LOGFILE.
        }
    }.
    global padRep is {
        PARAMETER l, s, t.
        RETURN (""+t):PADLEFT(l):REPLACE(" ",s).
    }.

    function _stage {
        pout("Staging.").
        if d:haskey["times"] {
            d["times"]["setTime"]("STAGE").
        }
        STAGE.
    }

    function mAngle {
        PARAMETER a.
        local b is MOD(a, 360).
        if b < 0 { set b to b + 360. }
        return b.
    }

    function warpUntil {
        PARAMETER wt, s_f IS { RETURN FALSE. }.
        if wt - TIME:SECONDS > 30 {
            pout("Engaging time warp.").
            WARPTO(wt).
            WAIT UNTIL s_f() OR wt < TIME:SECONDS.
            killWarp().
            pout("Time warp over.").
        }
    }

    function doWarp {
        PARAMETER wt.
        warpUntil(TIME:SECONDS + wt).
    }

    function killWarp {
        KUNIVERSE:TIMEWARP:CANCELWARP().
        WAIT UNTIL SHIP:UNPACKED.
    }
    global __ is boot_lib.
    global SAFENAME is padRep(0, "_", SHIP:NAME).
}
