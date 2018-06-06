@LAZYGLOBAL OFF.

//Print info
CLEARSCREEN.
print "kOS processor version " + core:version.
print "Running on " + core:element:name.
print core:volume:capacity + " total space".
print core:volume:freespace + " bytes free".
Print "Universal RAMP bootloader".
//Waits 5 seconds for ship loads and stabilize physics, etc...
WAIT 5.

{
  LOCAL s is stack().
  LOCAL d is lex().
  LOCAL VOLUME_NAMES IS LIST().
  listVolumes().
  pVolumes().

  /////////////////////////////////
  // Any library that is import'ed
  // MUST export itself as its last
  // instruction
  /////////////////////////////////
  global import is {
    parameter n.
    if not d:haskey(n) {
        s:push(n).
        RUNONCEPATH(loadScript("1:/"+n)).
    }
    return d[n].
  }.

  global export is {
    parameter v.
    set d[s:pop()] to v.
  }.

  FUNCTION listVolumes
  {
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
    FOR vn IN VOLUME_NAMES { PRINT "Volume(" + vn + ") has " + VOLUME(vn):FREESPACE + " bytes.". }
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
    PRINT "ERROR: no room!".
    RETURN "".
  }

  GLOBAL loadScript is
  {
    PARAMETER fn, loud IS TRUE.
    LOCAL lfp IS findPath(fn).
    IF lfp <> "" { RETURN lfp. }

    LOCAL afp IS "0:/" + fn.
    LOCAL afs IS VOLUME(0):OPEN(fn):SIZE.
    IF loud { pOut("Copying from: " + afp + " (" + afs + " bytes)"). }

    SET lfp TO findSpace(fn, afs).
    COPYPATH(afp,lfp).
    IF loud { pOut("Copied to: " + lfp). }
    RETURN lfp.
  }.

  GLOBAL delScript is
  {
    PARAMETER fn.
    LOCAL lfp IS findPath(fn).
    IF lfp <> "" { DELETEPATH(lfp). }
  }.
}

local startup is loadscript("Missions/" + ship:name:REPLACE(" ","_") + ".ks")
if startup = "" { set startup to loadscript("lib/launch_gui.ks"). }
if startup = "" { PRINT "Unable to load startup script.". }
else { runpath(startup). }
PRINT "Proceed.".
