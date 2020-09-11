@lazyGlobal off.
// global delegates for file functionality
runOncePath("./libIO.ks").
print("Initializing file management...").
{

    LOCAL VOLUME_NAMES IS LIST().
    listVolumes().
    pVolumes().
    
    FUNCTION listVolumes  {
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
    }

  FUNCTION pVolumes
  {
    FOR vn IN VOLUME_NAMES { 
        printOut("Volume(" + vn + ") has " + VOLUME(vn):FREESPACE + " bytes.", false). 
    }
  }

  FUNCTION findPath
  {
    PARAMETER fn.
    FOR vn IN VOLUME_NAMES {
      LOCAL lfp IS vn + ":/" + fn.
      IF EXISTS(lfp) { RETURN lfp. }
    }
    RETURN "".
  }

  FUNCTION findSpace
  {
    PARAMETER fn, mfs.
    FOR vn IN VOLUME_NAMES { IF VOLUME(vn):FREESPACE > mfs { RETURN vn + ":/" + fn. } }
    printOut("ERROR: no room!").
    RETURN "".
  }

  GLOBAL loadScript is
  {
    PARAMETER fn, loud IS TRUE.
    LOCAL lfp IS findPath(fn).
    IF lfp <> "" { RETURN lfp. }

    LOCAL afp IS "0:/" + fn.
    LOCAL afs IS VOLUME(0):OPEN(fn):SIZE.
    IF loud { printOut("Copying from: " + afp + " (" + afs + " bytes)"). }

    SET lfp TO findSpace(fn, afs).
    if lfp <> "" {
      COPYPATH(afp,lfp).
      IF loud { printOut("Copied to: " + lfp). }
    }
    RETURN lfp.
  }.

  GLOBAL delScript is
  {
    PARAMETER fn.
    LOCAL lfp IS findPath(fn).
    IF lfp <> "" { DELETEPATH(lfp). }
  }.
}