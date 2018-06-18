@LAZYGLOBAL OFF.
pout("LEC MISSION v%VERSION_NUMBER%").
{
    local self is lex(
        "loadMission", loadMission@,
        "runMission", runMission@,
        "next", updateRunmode@,
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
        "delData", delData@,
        "setSequence", setSequence@
    ).
    local sequence is list("Dummy", { parameter mission. mission["next"](). }).
    local data is lex("_MISSION_DATA_", lex()).
    local events is lex().
    local done is false.
    local runmode is 0.

    local diskio is import("lib/diskio.ks").

    function setSequence {
      parameter seq.
      set sequence to seq.
    }

    function updateRunmode {
        PARAMETER n is runmode + 1.
        saveState().
        local fp is diskio["findpath"]("mission.runmode").
        if fp = "" {
            set fp to diskio["findspace"]("mission.runmode").
            create(fp).
        }
        local file is open(fp).
        file:clear().
        file:write(sequence[2 * n]).
        set runmode to n.
        loadState().
    }
    function loadMission {
        PARAMETER fp.
        local lfp is diskio["loadfile"](fp).
        diskio["runFile"](lfp, self).
    }
    function runMission {
        if resumeMission() >= 0 pout("Resuming mission").
        until done or runmode * 2 >= sequence:length {
          sequence[runmode * 2 + 1]().
          for event in events:keys {
              events[event](self).
          }
          wait 0.
        }
        local fp is diskio["findpath"]("mission.runmode").
        if NOT fp = "" { deletepath(fp). }
    }
    function resumeMission {
        local fp is diskio["findpath"]("mission.runmode").
        local n is -1.
        if NOT fp = "" {
            local last_mode is open(fp):readall():string.
            set n to indexof(sequence, last_mode).
            if n >= 0 { update_runmode(n / 2). }
        }
        return n.
    }
    function hasRunmode {
        PARAMETER mn.
        return sequence:contains(mn).
    }
    function setRunmode {
        PARAMETER mn.
        if hasRunmode(rm) return.
        set runmode to mn.
    }
    function currRunmode {
        return sequence[runmode * 2].
    }
    function endMission {
        set done to true.
    }
    function addRunmode {
        PARAMETER name, delegate.
        local newMode is 0.
        local newName is name.
        if name:matchespattern("/^\d{3}-.*$/") {
            set newMode to name:substring(0,3).
            set newName to name:remove(0,4).
        } else {
            set newMode to padRep(3,"0",sequence:length / 2).
        }
        local modename is padRep(3,"0",sequence:length / 2) + "-" + name.
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
    function saveState {
        local d is lex().
        local fp is diskio["findfile"]("mission.data").
        if NOT fp = "" {
            set d to readjson(fp).
        }
        if data:length > 0 {
          set d[currRunmode()] to data.
        } else {
          if d:haskey(currRunmode()) d:remove(currRunmode()).
        }
        set d["__MISSION__"] to mission_data.
        writejson(d, fp).
    }
    function loadState {
        local d is lex().
        local fp is diskio["findfile"]("mission.data").
        if NOT fp = "" {
            set d to readjson(fp).
        }
        set data to lex().
        if d:haskey(currRunmode()) set data to d[currRunmode()].
        if d:haskey("__MISSION__") set mission_data to d["__MISSION__"].
        else set mission_data to lex().
    }
    function indexof {
      parameter _list, item. local i is 0.
      for el in _list {
        if el = item return i.
        set i to i + 1.
      }
      return -1.
    }
    export(self).
}
