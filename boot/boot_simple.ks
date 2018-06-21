/////////////////////////////////////////////////////////////////////////////
// Simple ascend-to-orbit boot script.
/////////////////////////////////////////////////////////////////////////////
// Launch and ascend to a fixed altitude.
//
// MUST NOT be used for vessels that will operate out of comms range!!
/////////////////////////////////////////////////////////////////////////////

@LAZYGLOBAL OFF.

PRINT("Bootstrapping OS").

COPYPATH("0:/lib/os.ks", "1:/lib/os.ks").
GLOBAL _os_ IS RUNONCEPATH("1:/lib/os.ks").
