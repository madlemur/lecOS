clearscreen.
set deleteOnFinish to false.
set backupOps to false.
set tempName to ship:name.
set sName to "".
from {local i is 0.} until i = tempName:length step {set i to i + 1.} do {
  if(tempName[i] = " ") {
    set sName to sName + "_".
  } else {
    set sName to sName + tempName[i].
  }
  wait 0.001.
}
log "" to sName + ".log.np2".

// checks if the requested file exists on the KSC disk
// checks if there is enough room to copy a file from the archive to the vessel
// will remove the log file if the space it frees will allow the transfer
// also accounts for wether the transfer file has a local copy that will be replaced
function download {
  parameter archiveFile, localFile, keepfile is true.
  if not HOMECONNECTION:ISCONNECTED return false.
  if not archive:exists(archiveFile) return false.
  if core:volume:exists(localFile) set localFileSize to core:volume:open(localFile):size.
  else set localFileSize to 0.
  set archiveFileSize to archive:open(archiveFile):size.
  if core:volume:freespace - archiveFileSize + localFileSize < 0 {
    local logfile is sName + ".log.np2".
    if core:volume:freespace - archiveFileSize + localFileSize + core:volume:open(logfile):size > 0 {
      copypath(logfile, "0:").
      core:volume:delete(logfile).
      print "deleting log to free up space".
    } else {
      print "unable to copy file " + archiveFile + ". Not enough disk space".
      return false.
    }
  }
  if localFileSize core:volume:delete(localFile).
  copypath("0:" + archiveFile, localFile).
  if not keepfile
    archive:delete(archiveFile).
  return true.
}

// check if we have new instructions stored in event of comm loss
if core:volume:exists("backup.op.ks") and not (HOMECONNECTION:ISCONNECTED) {
  core:volume:delete("operations.ks").
  movepath("backup.op.ks", "operations.ks").
  print "KSC connection lost. Stored operations file loaded".
} else {

  // check for connection to KSC for archive volume access if no instructions stored
  if not (HOMECONNECTION:ISCONNECTED) {
    print "waiting for KSC link...".
    wait until HOMECONNECTION:ISCONNECTED.
  }

  print "KSC link established, fetching operations...".
  wait HOMECONNECTION:DELAY.

  // check for a new bootscript
  // destroy the log if needed to make room, but only if it'll make room
  if download(sName + ".boot.ks", "boot.ks", false) {
    print "new boot file received".
    wait 2.
    reboot.
  }

  // check for new operations
  // destroy the log if needed to make room, but only if it'll make room
  if download(sName + ".op.ks", "operations.ks", false) print "new operations file received".
}


// ///////////////////
// do any boot stuff
// ///////////////////
set ship:control:pilotmainthrottle to 0.

// date stamp the log
// won't output to archive copy until first ouput() call
set logList to list().
set logStr to "[" + time:calendar + "] boot up".
log logStr to sName + ".log.np2".
logList:add(logStr).

// for logging data, with various considerations
function output {
  parameter text.
  parameter toConsole is false.

  // print to console if requested
  if toConsole print text.

  // log the new data to the file if it will fit
  // otherwise delete the log to start anew
  set logStr to "[" + time:hour + ":" + time:minute + ":" + floor(time:second) + "] " + text.
  if core:volume:freespace > logStr:length {
    log logStr to sName + ".log.np2".
  } else {
    core:volume:delete(sName + ".log.np2").
    log "[" + time:calendar + "] new file" to sName + ".log.np2".
    log logStr to sName + ".log.np2".
  }

  // store a copy on KSC hard drives if we are in contact
  // otherwise save and copy over as soon as we are back in contact
  if HOMECONNECTION:ISCONNECTED {
    if not archive:exists(sName + ".log.np2") archive:create(sName + ".log.np2").
    if logList:length {
      for entry in logList archive:open(sName + ".log.np2"):writeln(entry).
      set logList to list().
    }
    archive:open(sName + ".log.np2"):writeln(logStr).
  } else {
    if core:volume:freespace > logStr:length {
      logList:add(logStr).
    } else {
      core:volume:delete(sName + ".log.np2").
      logList:add("[" + time:calendar + "] new file").
      logList:add(logStr).
    }
  }
}

// store new instructions while a current operations program is running
// if we lose connection before a new script is uploaded, this will run
// running ops should check backupOps flag and call download(shipName + ".bop.ks.", "backup.op.ks").
when HOMECONNECTION:ISCONNECTED and archive:exists(sName + ".bop.ks.") then {
  set backupOps to true.
  if HOMECONNECTION:ISCONNECTED preserve.
}

// run operations?
if not core:volume:exists("operations.ks") and HOMECONNECTION:ISCONNECTED {
  print "waiting to receive operations...".
  until download(sName + ".op.ks.", "operations.ks") {
    if not HOMECONNECTION:ISCONNECTED {
      if not core:volume:exists("backup.op.ks") {
        print "KSC connection lost, awaiting connection...".
        wait until HOMECONNECTION:ISCONNECTED.
        reboot.
      } else {
        if core:volume:exists("operations.ks") core:volume:delete("operations.ks").
        movepath("backup.op.ks", "operations.ks").
        print "KSC connection lost. Stored operations file loaded".
        break.
      }
    }
    wait 1.
  }
}
output("executing operations", true).
RUNPATH("1:operations.ks").
if deleteOnFinish deletepath("1:operations.ks").
output("operations execution complete", true).
wait 2.
reboot.
