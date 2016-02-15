// Generalized Boot Script v1.0.1
// Kevin Gisi
// http://youtube.com/gisikw

LOCAL _libs IS list().
// The ship will use updateScript to check for new commands from KSC.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

// Display a message
FUNCTION NOTIFY {
  PARAMETER m.
  HUDTEXT("kOS: " + m, 5, 2, 50, YELLOW, false).
}

// Detect whether a file exists on the specified volume
FUNCTION HAS_FILE {
  PARAMETER n.
  PARAMETER v.

  SWITCH TO v.
  LIST FILES IN af.
  FOR file IN af {
    IF file:NAME = n {
      SWITCH TO 1.
      RETURN TRUE.
    }
  }

  SWITCH TO 1.
  RETURN FALSE.
}

// First-pass at introducing artificial delay. ADDONS:RT:DELAY(SHIP) represents
// the line-of-site latency to KSC, as per RemoteTech
FUNCTION DELAY {
  SET d TO ADDONS:RT:DELAY(SHIP) * 3. // Total delay time
  SET a TO 0.                       // Accumulated time

  UNTIL a >= d {
    SET s TO TIME:SECONDS.
    WAIT UNTIL (TIME:SECONDS - start) > (d - a) OR NOT ADDONS:RT:HASCONNECTION(SHIP).
    SET a TO a + TIME:SECONDS - s.
  }
}

// Get a file from KSC
FUNCTION DOWNLOAD {
  PARAMETER n.

  DELAY().
  IF HAS_FILE(n, 1) {
    DELETE n.
  }
  IF HAS_FILE(n, 0) {
    COPY n FROM 0.
  }
}

// Put a file on KSC
FUNCTION UPLOAD {
  PARAMETER n.

  DELAY().
  IF HAS_FILE(n, 0) {
    SWITCH TO 0. DELETE n. SWITCH TO 1.
  }
  IF HAS_FILE(n, 1) {
    COPY n TO 0.
  }
}

// Run a library, downloading it from KSC if necessary
FUNCTION REQUIRE {
  PARAMETER n.
  NOTIFY("Requiring " + n).
  IF(_libs:CONTAINS(n)) {
    return.
  }
  IF NOT HAS_FILE(n, 1) { DOWNLOAD(n). }
  IF HAS_FILE("tmp.exec.ks", 1) {
    DELETE "tmp.exec.ks".
  }
  RENAME n TO "tmp.exec.ks".
  RUN tmp.exec.ks.
  RENAME "tmp.exec.ks" TO n.
  _libs:ADD(n).
}

// THE ACTUAL BOOTUP PROCESS
SET u TO SHIP:NAME + ".update.ks".
IF NOT HAS_FILE(u, 0) {
	SET u TO CORE:TAG + ".update.ks".
}

// If we have a connection, see if there are new instructions. If so, download
// and run them.
IF ADDONS:RT:HASCONNECTION(SHIP) {
  IF HAS_FILE(u, 0) {
    NOTIFY("Updating with " + u).
    DOWNLOAD(u).
    SWITCH TO 0. DELETE u. SWITCH TO 1.
    IF HAS_FILE("update.ks", 1) {
      DELETE update.ks.
    }
    RENAME u TO "update.ks".
    RUN update.ks.
    DELETE update.ks.
  }
}

// If a startup.ks file exists on the disk, run that.
IF HAS_FILE("startup.ks", 1) {
  NOTIFY("Running startup.").
  RUN startup.ks.
} ELSE {
  WAIT UNTIL ADDONS:RT:HASCONNECTION(SHIP).
  NOTIFY("No startup or update available. Rebooting in 10 seconds.").
  WAIT 10. // Avoid thrashing the CPU (when no startup.ks, but we have a
           // persistent connection, it will continually reboot).
  NOTIFY("Rebooting...").
  REBOOT.
}
