@LAZYGLOBAL OFF.
PRINT("LEC DISKIO v%VERSION_NUMBER%").
{

    local self is lexicon(
        "listVolumes", listVolumes@,
        "findFile", findFile@,
        "findSpace", findSpace@,
        "loadFile", loadFile@,
        "delFile", delFile@,
        "runFile", runFile@
    ).
    
    FUNCTION listVolumes {
        return list(CORE:CURRENTVOLUME:NAME).
    }

    FUNCTION findFile {
        PARAMETER fn.
        LOCAL lfp IS CORE:CURRENTVOLUME:NAME + ":/" + fn.
        IF EXISTS(lfp) { RETURN lfp. }
        RETURN "".
    }

    FUNCTION findSpace {
        PARAMETER fn, mfs.
        IF CORE:CURRENTVOLUME:FREESPACE > mfs {
            RETURN CORE:CURRENTVOLUME:NAME + ":/" + fn.
        }
        pout "ERROR: no room for " + fn + " (" + mfs + "b)!".
        RETURN "".
    }

    FUNCTION loadFile {
        PARAMETER fn, loud IS TRUE.
        LOCAL lfp IS self["findFile"](fn).
        IF NOT lfp = "" { RETURN lfp. }

        LOCAL afp IS "0:/" + fn.
        LOCAL afs IS VOLUME(0):OPEN(fn):SIZE.
        IF loud { pOut("Copying from: " + afp + " (" + afs + " bytes)"). }

        SET lfp TO self["findSpace"](fn, afs).
        if lfp = "" {
            pout("ERROR: unable to copy file " + fn).
            RETURN "".
        } else {
            COPYPATH(afp,lfp).
            IF loud { pOut("Copied to: " + lfp). }
            RETURN lfp.
        }
    }

    FUNCTION delFile {
        PARAMETER fn.
        LOCAL lfp IS self["findFile"](fn).
        IF not lfp = "" { DELETEPATH(lfp). }
    }

    FUNCTION runFile {
        PARAMETER fn, delafter is FALSE.
        local lfn is self["findFile"](fn).
        if not lfn = "" {
            local result IS RUNPATH(lfn).
            if delafter {
                self["delFile"](lfn).
            }
            return result.
        }
        return "".
    }

    export(self).
}
