@LAZYGLOBALS OFF.
{
    __:pOut("LEC OPS_LOADER v$$VER_NUM$$.$$REL_NUM$$.$$PAT_NUM$$ $$BLD_NUM$$").
    local sName is __:padRep(0,"_",SHIP:NAME).

    // check for connection to KSC for archive volume access if no instructions stored
    if not (addons:rt:haskscconnection(ship)) {
        __:pOut("waiting for KSC link...").
        wait until addons:rt:haskscconnection(ship).
    }

    __:pOut("KSC link established, fetching operations...").
    wait addons:rt:kscdelay(ship).

    // check for a new bootscript
    // destroy the log if needed to make room, but only if it'll make room
    local bfn is __:loadScript(sName + ".boot.ks", TRUE, FALSE).
    if bfn <> "" {
        movepath(bfn, CORE:VOLUME:BOOTFILENAME).
        __:pOut("New boot file received").
        wait 2.
        reboot.
    }

    // check for new operations
    // destroy the log if needed to make room, but only if it'll make room
    local ofn is __:loadScript(sName + ".op.ks", TRUE, FALSE).
    if ofn <> "" {
        __:pOut("Executing operations file").
        RUNPATH(ofn).
        if deleteOnFinish __:delScript(ofn).
        __:pOut("Operations execution complete").
        wait 2.
        reboot.
    }
}
