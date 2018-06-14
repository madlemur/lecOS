@LAZYGLOBAL OFF.
pout("LEC MISSION v%VERSION_NUMBER%").
{
    local self is lex(
        "loadMission", loadMission@,
        "runMission", runMission@,
        "next", next@,
        "switchTo", switchTo@,
        "currRunmode", currRunmode@,
        "endMission", endMission@,
        "addEvent", addEvent@,
        "hasEvent", hasEvent@,
        "pauseEvent", pauseEvent@,
        "startEvent", startEvent@,
        "deleteEvent", deleteEvent@,
        "addData", addData@,
        "getData", getData@,
        "hasData", hasData@,
        "delData", delData@
    ).
    local sequence is list().
    local data is lex("_MISSION_DATA_", lex()).
    local events is lex().
    local done is false.
    local runmode is 0.

    function updateRunmode {
        PARAMETER n.
        saveState().
        local fp is diskio["findpath"]("mission.runmode").
        if fp = "" {
            set fp to diskio["findspace"]("mission.runmode").
        }
        set fp to path(fp).
    }

    function loadMission {
        PARAMETER fp.
        PARAMETER sn is SAFENAME.
    }
    function runMission {
        PARAMETER sn is SAFENAME.
    }
    function next {}
    function switchto {
        PARAMETER rm.
    }
    function currRunmode {
        return sequence[runmode * 2].
    }
    function endMission {
        set done to true.
    }
    function addRunmode {
        PARAMETER name, delegate.
        local modename is padRep(3,"0",sequence:length / 2) + name.
        if delegate:istype("KOSDelegate") {
            sequence:add(modename).
            sequence:add(delegate).
            return modename.
        }
        return false.
    }
    function addEvent {
        PARAMETER name, delegate.
        events:add(name, list(true, delegate)).
    }
    function hasEvent {
        PARAMETER name.
        return events:haskey(name).
    }
    function pauseEvent {
        PARAMETER name.
        if hasEvent(name) {
            local evt is events[name].
            set events[name] to list(false, evt[1]).
        }
    }
    function startEvent {
        PARAMETER name.
        if hasEvent(name) {
            local evt is events[name].
            set events[name] to list(true, evt[1]).
        }
    }
    function deleteEvent {
        PARAMETER name.
        if hasEvent(name) {
            events:remove(name).
        }
    }
    function addData {
        PARAMETER name, value.
        PARAMETER msn_data is FALSE.
    }
    function getData {
        PARAMETER name.
    }
    function hasData {
        PARAMETER name.
    }
    function delData {
        PARAMETER name.
    }

    export(self).
}
