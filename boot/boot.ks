@LAZYGLOBAL OFF.
PRINT("LEC BOOTLOADER v%VERSION_NUMBER%").
{
    IF HOMECONNECTION:ISCONNECTED AND EXISTS("0:/lib/lec_os.ks") {
        PRINT("Connected to archive, downloading LEC_OS.").
        COPYPATH("0:/lib/lec_os.ks", "1:/lib/lec_os.ks").
    }
    IF EXISTS("1:/lib/lec_os.ks") {
        RUNONCEPATH("1:/lib/lec_os.ks").
    } ELSE {
        PRINT "Unable to load LEC_OS. Shutting down.".
        SHUTDOWN.
    }
    LOCAL OPSFILE is "1:/operations.ks".
    LOCAL RESUME_OPS is"1:/resume.ops.ks".
    IF EXISTS(RESUME_OPS) {
        pout("Resuming operations.").
        COPYPATH(RESUME_OPS, OPSFILE).
    } ELSE {
        IF NOT EXISTS(OPSFILE) {
            LOCAL waituntil is TIME:SECONDS - 1.
            UNTIL HOMECONNECTION:ISCONNECTED {
                IF waituntil < TIME:SECONDS {
                    pout("Waiting for connection to archive.").
                    set waituntil to TIME:SECONDS + 10.
                }
                WAIT 0.
            }
            IF EXISTS("1:/"+SAFENAME+".ops.ks") {
                pout("Copying ops file from archive.").
                COPYPATH("1:/"+SAFENAME+".ops.ks", OPSFILE).
            }
        }
    }
    IF EXISTS(OPSFILE) {
        RUNONCEPATH(OPSFILE).
    } ELSE {
        pout("No ops file found. Shutting down.").
        SHUTDOWN.
    }
    pout("Operations completed. Shutting down.").
    SHUTDOWN.
}
