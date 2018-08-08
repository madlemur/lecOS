@LAZYGLOBAL OFF.
pout("LEC MISSION v%VERSION_NUMBER%").
{
    local self is lex(
        "loadMission", loadMission@,
        "runMission", runMission@,
        "next", updateRunmode@:bind(-1),
        "setRunmode", setRunmode@,
        "currRunmode", currRunmode@,
        "appendRunmode", appendRunmode@,
        "hasRunmode", hasRunmode@,
        "endMission", endMission@,
        "addEvent", addEvent@,
        "hasEvent", hasEvent@,
        "pauseEvent", pauseEvent@,
        "startEvent", startEvent@,
        "delEvent", delEvent@,
        "addData", addData@,
        "getData", getData@,
        "hasData", hasData@,
        "delData", delData@,
        "setSequence", setSequence@
    ).
    local sequence is list("Dummy", { parameter mission. mission["next"](). }).
    local data is lex().
    local mission_data is lex().
    local events is lex().
    local done is false.
    local runmode is 0.

    local diskio is import("lib/diskio.ks", false).

    function updateRunmode {
        PARAMETER n is -1.
        if n = -1 set n to runmode + 1.
        if n * 2 < sequence:length {
            saveState().
            local fp is diskio["findfile"]("mission.runmode").
            if fp = "" {
                set fp to diskio["findspace"]("mission.runmode", sequence[2 * n]:length).
                create(fp).
            }
            local file is open(fp).
            file:clear().
            file:write(sequence[2 * n]).
            set runmode to n.
            loadState().
            return true.
        } else {
            pout("Runmode " + n + " is out of bounds.").
            set done to true.
            return false.
        }
    }
    function loadMission {
        PARAMETER fn is "Missions/" + SAFENAME + ".ks".
        LOCAL lfp is diskio["loadFile"](fn).
        if lfp = "" {
          pout("Unable to load mission " + fn).
          set done to true.
        }
        pout("Loading mission " + lfp).
        diskio["runFile"](lfp, self).
    }
    function runMission {
        if resumeMission() >= 0 pout("Resuming mission").
        until done or runmode * 2 >= sequence:length {
          sequence[runmode * 2 + 1](self).
          for event in events:keys {
              if events[event][0] {
                  events[event][1](self, event).
              } else {
              }
          }
        }
        saveState().
        local fp is diskio["findfile"]("mission.runmode").
        if NOT fp = "" { deletepath(fp). }
    }
    function resumeMission {
        local fp is diskio["findfile"]("mission.runmode").
        local n is -1.
        if NOT (fp = "") {
            local last_mode is open(fp):readall():string.
            set n to indexof(sequence, last_mode).
            if n >= 0 { updateRunmode(n / 2). }
        }
        return n.
    }
    function hasRunmode {
        PARAMETER mn.
        local n is -1.
        set n to indexof(sequence, mn).
        return n >= 0.
    }
    function setRunmode {
        PARAMETER mn.
        local ix is indexof(sequence, mn).
        if ix >= 0 {
            updateRunmode(ix / 2).
            return true.
        } else {
            return false.
        }
    }
    function currRunmode {
        return sequence[runmode * 2].
    }
    function endMission {
        set done to true.
    }
    function appendRunmode {
        PARAMETER name, delegate.
        if hasRunmode(name) >= 0 {
            pout("Runmode named " + name + " already added.").
            return false.
        }
        if delegate:istype("KOSDelegate") {
            sequence:add(name).
            sequence:add(delegate).
            return true.
        } else {
            pout("Runmode must be accompanied by a function delegate.").
            return false.
        }
    }
    function addEvent {
        PARAMETER name, delegate.
        PARAMETER isActive is true.
        events:add(name, list(isActive, delegate)).
    }
    function hasEvent {
        PARAMETER name.
        return events:haskey(name).
    }
    function pauseEvent {
        PARAMETER name.
        if hasEvent(name) {
          pout("Disabling event " + name).
            local evt is events[name].
            set events[name] to list(false, evt[1]).
        }
    }
    function startEvent {
        PARAMETER name.
        if hasEvent(name) {
          pout("Enabling event " + name).
            local evt is events[name].
            set events[name] to list(true, evt[1]).
        }
    }
    function delEvent {
        PARAMETER name.
        if hasEvent(name) {
            events:remove(name).
        }
    }
    function addData {
        PARAMETER name, value.
        PARAMETER msn_data is FALSE.
        if msn_data {
            if mission_data:haskey(name) {
                mission_data:remove(name).
            }
            mission_data:add(name, value).
        } else {
            if data:haskey(name) {
                data:remove(name).
            }
            data:add(name, value).
        }
        return true.
    }
    function getData {
        PARAMETER name.
        if data:haskey[name] {
            return data[name].
        } else if mission_data:haskey[name] {
            return mission_data[name].
        }
        return false. // for lack of a better value...
    }
    function hasData {
        PARAMETER name.
        return (data:haskey(name) or mission_data:haskey(name)).
    }
    function delData {
        PARAMETER name.
        if data:haskey(name) {
            data:remove(name).
            return true.
        } else if mission_data:haskey[name] {
            mission_data:remove(name).
            return true.
        }
        return false.
    }
    function saveState {
        local d is lex().
        local fp is diskio["findFile"]("mission.data").
        if NOT (fp = "") {
            set d to readjson(fp).
        }
        if data:length > 0 {
          set d[currRunmode()] to data.
        } else {
          if d:haskey(currRunmode()) d:remove(currRunmode()).
        }
        set d["__MISSION__"] to mission_data.
        diskio["delFile"](fp).
        local lfp is diskio["findSpace"]("mission.data", d:dump:length).
        writejson(d, lfp).
    }
    function loadState {
        local d is lex().
        local fp is diskio["findFile"]("mission.data").
        if NOT (fp = "") {
            set d to readjson(fp).
        }
        set data to lex().
        set mission_data to lex().
        if d:haskey(currRunmode()) set data to d[currRunmode()].
        if d:haskey("__MISSION__") set mission_data to d["__MISSION__"].
    }
    function indexof {
      parameter _list, item. local i is 0.
      for el in _list {
        if el = item return i.
        set i to i + 1.
      }
      return -1.
    }
    function setSequence {
      PARAMETER seq.
      if NOT seq:istype("LIST") OR mod(seq:length, 2) > 0 {
        pout("Error setting mission sequence. Must be a list of label, delegate pairs.").
        return false.
      } else {
        set sequence to seq.
        return true.
      }
    }
    export(self).
}
