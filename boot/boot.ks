/////////////////////////////////////////////////////////////////////////////
// Universal boot script for RAMP system.
/////////////////////////////////////////////////////////////////////////////
// Copy all scripts to local volume; run mission script. This is suitable for
// single-CPU vessels that will be operating out of comms range.
//
// To customize the mission, edit <ship name>.ks in 0:/start folder before
// launch; it will be persisted onto the craft you launch, suitable for
// archive-free operation.
//
// Nevertheless, every time this boots, it will try to copy the files again,
// if possible.
// It expects the RAMP scripts files to be saved in 0:/ramp folder.
/////////////////////////////////////////////////////////////////////////////

//Print info
CLEARSCREEN.
print "kOS processor version " + core:version.
print "Running on " + core:element:name.
print core:volume:capacity + " total space".
print core:volume:freespace + " bytes free".
Print "Universal bootloader vBUILD_VERSION.BUILD_RELEASE.BUILD_PATCH BUILD_DATE".
//Waits 5 seconds for ship loads and stabilize physics, etc...
WAIT 5.
{
	PRINT("Bootstrapping OS").
	SET ScriptPath to fetchScript("/lib/os.ks").
	if ScriptPath = 0 {
		PRINT "Unable to find OS script.".
		PRINT "Halting execution.".
		SHUTDOWN.
	}
	RUNONCEPATH(ScriptPath).

	//Set up volumes
	SET HD TO CORE:VOLUME.
	SET ARC TO 0.
	SET Startup to "startup".
	SET Resume to "resume".
	SET ScriptPath to _os_["loadScript"](Resume, SHIP:NAME:REPLACE(" ","_") + "_" + Resume + ".ks").
	IF ScriptPath = "" {
		PRINT "No " + Resume + " script found.".
		SET ScriptPath to _os_["loadScript"](Startup, SHIP:NAME:REPLACE(" ","_") + "_" + Startup + ".ks").
	}

	if ScriptPath = "" {
		PRINT "No " + Startup + " script found.".
		IF NOT HOMECONNECTION:ISCONNECTED {
			PRINT "Deploying antennas and rebooting.".
			FOR P IN SHIP:PARTS {
				IF P:MODULES:CONTAINS("ModuleDeployableAntenna") {
					LOCAL M IS P:GETMODULE("ModuleDeployableAntenna").
					FOR A IN M:ALLACTIONNAMES() {
						IF A:CONTAINS("Extend") { M:DOACTION(A,True). }
					}.
				}
			}.
			REBOOT.
		}
	} ELSE {
		RUNPATH(ScriptPath).
	}

	LOCAL FUNCTION fetchScript {
		PARAMETER sname.
		PARAMETER spath is "".

		LOCAL ScriptPath is 0.

		if spath = "" {
			SET spath TO sname.
		}

		PRINT "Looking for " + sname + " script.".
		IF EXISTS(spath) OR EXISTS(spath + ".ks") {
			PRINT "Found local script".
			SET ScriptPath TO spath.
		} ELSE IF HOMECONNECTION:ISCONNECTED {
			SET ARC TO VOLUME(0).
			PRINT "Looking for " + ARC:Name + ":" + sname + ".".
			IF EXISTS(ARC:Name + ":" + sname) {
				PRINT "Copying remote script.".
				IF NOT COPYPATH(ARC:Name + ":" + sname, spath) {
					PRINT "Unable to copy remote script.".
					SET ScriptPath TO ARC:Name + ":" + sname.
				} ELSE {
					SET ScriptPath TO spath.
				}
			}
		}
		RETURN ScriptPath.
	}
}
