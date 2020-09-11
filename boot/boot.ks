// lec OS bootfile
@LAZYGLOBAL OFF.

//Print hardware info
CLEARSCREEN.
print "kOS processor version " + core:version.
print "Running on " + core:element:name.
print core:volume:capacity + " total space".
print core:volume:freespace + " bytes free".

//Waits 5 seconds for ship loads and stabilize physics, etc...
WAIT 5.

print "Bootstrapping lecOS".

runOncePath("lib/libIO.ks").
runOncePath("lib/libFile.ks").
runOncePath("lib/libLoader.ks").

printOut("lecOS loaded").