// Mission Runner
// Kevin Gisi
// Kenneth Cummins
// http://youtube.com/gisikw
@LAZYGLOBALS OFF.
PRINT "mission_runner vBUILD_VER.BUILD_REL.BUILD_PAT BUILD_NUM"
{
  function mission_runner {
    parameter sequence is list(), events is lex(), mission_data is lex().
    local data is lex().
    output("starting mission runner").
    local runmode is 0. local done is 0.

    // This object gets passed to sequences and events, to allow them to
    // interact with the event loop.
    local mission is lex(
      "add_event", add_event@,
      "remove_event", remove_event@,
      "next", next@,
      "switch_to", switch_to@,
      "runmode", report_runmode@,
      "terminate", terminate@,
      "add_data", add_data@,
      "remove_data", remove_data@,
      "get_data", get_data@,
      "has_data", has_data@
    ).

    // Recover runmode from disk
    if core:volume:exists("mission.runmode") {
      local last_mode is core:volume:open("mission.runmode"):readall():string.
      local n is indexof(sequence, last_mode).
      if n <> -1 update_runmode(n / 2).
    }

    // Main event loop
    until done or runmode * 2 >= sequence:length {
      sequence[runmode * 2 + 1](mission).
      for event in events:keys {
          events[event](mission).
      }
      wait 0.
    }
    if core:volume:exists("mission.runmode")
      core:volume:delete("mission.runmode").

    // Update runmode, persisting to disk
    function update_runmode {
      parameter n.
      save_state().
      if not core:volume:exists("mission.runmode")
        core:volume:create("mission.runmode").
      local file is core:volume:open("mission.runmode").
      file:clear().
      file:write(sequence[2 * n]).
      set runmode to n.
      load_state().
    }

    function save_state {
      local d is lex().
      if core:volume:exists("mission.data") {
        set d to readjson("mission.data").
      }
      if data:length > 0 {
        set d[report_runmode()] to data.
      } else {
        if d:haskey(report_runmode()) d:remove(report_runmode()).
      }
      set d["__MISSION__"] to mission_data.
      writejson(d, "mission.data").
    }

    function load_state {
      local d is lex().
      if core:volume:exists("mission.data")
        set d to readjson("mission.data").
      set data to lex().
      if d:haskey(report_runmode()) set data to d[report_runmode()].
      if d:haskey("__MISSION__") set mission_data to d["__MISSION__"].
      else set mission_data to lex().
    }

    // List helper function
    function indexof {
      parameter _list, item. local i is 0.
      for el in _list {
        if el = item return i.
        set i to i + 1.
      }
      return -1.
    }

 // +---------------------------------------------------+
 // | Mission functions, passed to sequences and events |
 // +---------------------------------------------------+

    // Add a new named event to the main event loop
    function add_event {
      parameter name, delegate.
      set events[name] to delegate.
    }

    // Remove an event by name
    function remove_event {
      parameter name.
      if events:haskey(name) {
          events:remove(name).
      }
    }

    // Switch to the next available runmode
    function next {
      update_runmode(runmode + 1).
    }

    // Switch to a specific runmode by name
    function switch_to {
      parameter name.
      update_runmode(indexof(sequence, name) / 2).
    }

    // Return the current runmode (read-only)
    function report_runmode {
      return sequence[runmode * 2].
    }

    // Add a key/value pair
    function add_data {
      parameter key, value, isglobal is false.
      if isglobal
        set mission_data[key] to value.
      else
        set data[key] to value.
      save_state().
    }

    // Remove a key/value pair
    function remove_data {
      parameter key.
      if data:haskey(key) {
          data:remove(key).
      }
      if mission_data:haskey(key) {
          mission_data:remove(key).
      }
      save_state().
    }

    // Retreive the value for a given key
    function get_data {
      parameter key.
      if data:haskey(key)
        return data[key].
      else
        return mission_data[key].
    }

    // Checks for existance of a key
    function has_data {
      parameter key.
      return data:haskey(key) or mission_data:haskey(key).
    }

    // Allow explicit termination of the event loop
    function terminate {
      set done to 1.
    }
  }

  global run_mission is mission_runner@.
}
