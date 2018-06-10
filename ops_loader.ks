@LAZYGLOBAL OFF.
{
    __["pOut"]("LEC OPS_LOADER v%VERSION_NUMBER%").
    local sName is __["padRep"](0,"_",SHIP:NAME).

    // check for connection to KSC for archive volume access if no instructions stored
    if not (HOMECONNECTION:ISCONNECTED) {
        __["pOut"]("Out of range, checking for operations file...").
        local bop is __["findPath"]("operations.ks").
        if bop <> "" {
            __["pOut"]("Found " + bop + ".").
            RUNPATH(bop).
            __["pOut"]("Operations execution complete").
            wait 2.
            reboot.
        }
        __["pOut"]("waiting for KSC link...").
        wait until HOMECONNECTION:ISCONNECTED.
        __["pOut"]("KSC link established, fetching operations file...").
    }

    // check for a new bootscript
    // destroy the log if needed to make room, but only if it'll make room
    local bfn is __["loadScript"](sName + ".boot.ks", TRUE, FALSE).
    if bfn <> "" {
        movepath(bfn, CORE:VOLUME:BOOTFILENAME).
        __["pOut"]("New boot file received.").
    } else {
        // check for new operations
        // destroy the log if needed to make room, but only if it'll make room
        local ofn is __["loadScript"](sName + ".op.ks", TRUE, FALSE).
        if ofn <> "" {
            __["pOut"]("Executing operations file.").
            RUNPATH(ofn).
            __["pOut"]("Operations execution complete.").
        }
    }
    wait 2.
    reboot.
}
