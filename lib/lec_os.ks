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
        "warpUntil", warpUntil@,
        "doWarp", doWarp@
    ).
    global import is {
        parameter n.
        parameter dl is true.
        local f is libname(n).
        if d:haskey(f) {
            return d[f].
        }
        if exists("0:/"+n) {
            s:push(f).
            local p is "1:/"+n.
            if d:haskey("diskio") {
                if dl {
                    set p to d["diskio"]["loadfile"](n).
                    d["diskio"]["runfile"](p).
                } else {
                    d["diskio"]["runfile"]("0:/"+n).
                }
            } else {
                if dl {
                    copypath("0:/"+n, p).
                    RUNONCEPATH(p).
                } else {
                    RUNONCEPATH("0:/"+n).
                }
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
    // Print to HUD
    global phud is {
        PARAMETER t, del is 3, pos is 2, s IS 40, c IS YELLOW, ec is FALSE.
        HUDTEXT(t, del, pos, s, c, ec).
        pout("HUD: " + t).
    }.
    // Print to OUTput (console)
    global pout is {
        PARAMETER t, wt IS TRUE.
        IF wt and d:haskey("text") { SET t TO d["text"]["formatMET"]() + " " + t. }
        PRINT t.
        plog(t).
    }.
    // Print to LOGfile
    global plog is {
        PARAMETER t.
        IF IS_LOGGING and exists(LOGFILE) { LOG t TO LOGFILE. }
    }.
    // Start LOGfile
    global slog is {
        PARAMETER f IS padRep(0,"_",SHIP:NAME) + ".log".
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
    // A bit to unpack here... 
    // This will pad the string t with leading zeros until it is length l
    // It will also replace all spaces in the resulting string with s
    global padRep is {
        PARAMETER l, s, t.
        RETURN (""+t):PADLEFT(l):REPLACE(" ",s).
    }.
    
    // Stage, with some timekeeping
    function _stage {
        pout("Staging.").
        if d:haskey("time") {
            d["time"]["setTime"]("STAGE").
        }
        STAGE.
    }

    // Normalize angle to [0,360)
    function mAngle {
        PARAMETER a.
        local b is MOD(a, 360).
        if b < 0 { set b to b + 360. }
        return b.
    }

    // Warp until wt or until s_f returns a truthy value
    function warpUntil {
        PARAMETER wt, s_f IS { RETURN FALSE. }.
        // Don't bother warping for 30 seconds or less
        if wt - TIME:SECONDS > 30 {
            pout("Engaging time warp.").
            WARPTO(wt).
            WAIT UNTIL s_f() OR wt < TIME:SECONDS.
            killWarp().
            pout("Time warp over.").
        }
    }

    // Blind warp for wt SECONDS
    function doWarp {
        PARAMETER wt.
        warpUntil(TIME:SECONDS + wt).
    }

    // Killswitch for the warp engines
    function killWarp {
        KUNIVERSE:TIMEWARP:CANCELWARP().
        WAIT UNTIL SHIP:UNPACKED.
    }

    global toIRF is {
      // changes to inertial right-handed coordinate system where ix = SPV, iy = vcrs(SPV, V(0, 1, 0)), iz = V(0, 1, 0)
      parameter oldVec, SPV is SolarPrimeVector.
      return V( oldVec:x * SPV:x + oldVec:z * SPV:z, oldVec:z * SPV:x - oldVec:x * SPV:z, oldVec:y).
    }.

    global fromIRF is {
      // changes from inertial right-handed coordinate system where ix = SPV, iy = vcrs(SPV, V(0, 1, 0)), iz = V(0, 1, 0)
      parameter irfVec, SPV is SolarPrimeVector.
      return V( irfVec:x * SPV:x - irfVec:y * SPV:z, irfVec:z, irfVec:x * SPV:z + irfVec:y * SPV:x ).
    }.
    
    // lib-style access for boot_lib functions
    global __ is boot_lib.
    // This should be a filesystem-safe name for the vessel
    global SAFENAME is padRep(0, "_", SHIP:NAME).
}
