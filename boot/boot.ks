@LAZYGLOBAL OFF.
PRINT("LEC BOOTLOADER v%VERSION_NUMBER%").
{
    LOCAL OSFILE is "/lib/lec_os.ks".
    local waituntil is 0.
    IF NOT EXISTS("1:"+OSFILE) {
        set waituntil to 0.
        UNTIL HOMECONNECTION:ISCONNECTED {
            IF waituntil < TIME:SECONDS {
                pout("Waiting for connection to archive.").
                set waituntil to TIME:SECONDS + 10.
            }
            WAIT 0.
        }
        IF EXISTS("0:"+OSFILE) {
            pout("Copying LEC_OS from archive.").
            COPYPATH("0:"+OSFILE, "1:"+OSFILE).
        }
    }
    IF EXISTS("1:"+OSFILE) {
        RUNONCEPATH("1:"+OSFILE).
    } ELSE {
        PRINT "Unable to load LEC_OS. Shutting down.".
        SHUTDOWN.
    }

    LOCAL SHIPFILE is "0:/"+SAFENAME+".ops.ks".
    LOCAL OPSFILE is "1:/operations.ks".
    LOCAL RESUME_OPS is"1:/resume.ops.ks".
    IF EXISTS(RESUME_OPS) {
        pout("Resuming operations.").
        COPYPATH(RESUME_OPS, OPSFILE).
    } ELSE {
        IF NOT EXISTS(OPSFILE) {
            set waituntil to 0.
            UNTIL HOMECONNECTION:ISCONNECTED {
                IF waituntil < TIME:SECONDS {
                    pout("Waiting for connection to archive.").
                    set waituntil to TIME:SECONDS + 10.
                }
                WAIT 0.
            }
            IF EXISTS(SHIPFILE) {
                pout("Copying ops file from archive.").
                COPYPATH(SHIPFILE, OPSFILE).
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
