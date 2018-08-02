@LAZYGLOBAL OFF.
pout("LEC VOLMGT v%VERSION_NUMBER%").
{
    LOCAL self is lexicon(
        "init", init@
    ).
    FUNCTION init {
        IF CORE:CURRENTVOLUME:NAME = "" { SET CORE:CURRENTVOLUME:NAME TO "Disk0". }
        LOCAL cvn IS CORE:CURRENTVOLUME:NAME.
        SET VOLUME_NAMES TO LIST(cvn).

        LOCAL disk_num IS 1.
        LOCAL pl IS LIST().
        LIST PROCESSORS IN pl.
        FOR p IN pl {
            LOCAL LOCK vn TO p:VOLUME:NAME.
            IF p:MODE = "READY" AND p:BOOTFILENAME = "None" AND vn <> cvn {
                IF vn = "" {
                    SET p:VOLUME:NAME TO ("Disk" + disk_num).
                    SET disk_num TO disk_num + 1.
                }
                VOLUME_NAMES:ADD(vn).
            }
        }
        if isImported("diskio") and not isImported("volmgt"){
            local dio is import("diskio", false).
            set dio["findFile"] to findFile@.
            set dio["findSpace"] to findSpace@.
        }
        wait 0.
    }

    FUNCTION findFile {
        PARAMETER fn.
        FOR vn IN VOLUME_NAMES {
            LOCAL lfp IS vn + ":/" + fn.
            IF EXISTS(lfp) { RETURN lfp. }
        }
        RETURN "".
    }

    FUNCTION findSpace {
        PARAMETER fn, mfs.
        FOR vn IN VOLUME_NAMES {
            IF VOLUME(vn):FREESPACE > mfs {
                RETURN vn + ":/" + fn.
            }
        }
        pout "ERROR: no room for " + fn + " (" + mfs + "b)!".
        RETURN "".
    }

    export(self).

}
