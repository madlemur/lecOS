@LAZYGLOBAL OFF.
pout("LEC NODE v%VERSION_NUMBER%").
{
    local self is lexicon().

    local nodeList is lexicon().
    local times is import("lib/time.ks", false).

    function createNode {
        parameter t. // time, in seconds, in the future to create the node
        parameter pro. // either the magnitude of the prograde component (V(0,0,1)),
                       // OR the entire deltaV vector in SHIP:RAW frame at time of execution
        parameter norm is false. // magnitude of normal component (V(1,0,0)), OR false (entire deltaV provided)
        parameter rad is false. // magnitude of radial component (V(0,1,0)), OR false (entire deltaV provided)

        local burntime is TIME:SECONDS + t.
        local deltaV is 0.
        if pro:istype("Vector") {
            set deltaV to vec(pro).
        } else if pro:istype("Scalar") AND norm:istype("Scalar") AND rad:istype("Scalar") {
            set deltaV to V(norm,rad,pro).
        } else {
            pout("CreateNode: Invalid parameters!").
            return false.
        }

        local currVelAtT is VELOCITYAT(SHIP, TIME:SECONDS + t).
        local nodename is "node_" + SAFENAME + padRep(2,"0",burntime:YEAR - 1) + ":" + padRep(3,"0",burntime:DAY - 1) + ":" + burntime:CLOCK.
        times["settime"](nodename, burntime).

        local newNode is lexicon(
            "eta", times["diffTime"]:bind(nodename),
            "deltaV", deltaV
        ).


    }

    function executeNode {}

    function removeNode {}

    function editNode {}

    function steerToNode {}

    function updateNode {}

    export(self).
}
