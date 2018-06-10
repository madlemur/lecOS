// Mission Runner
// Kevin Gisi
// Kenneth Cummins
// http://youtube.com/gisikw
@LAZYGLOBAL OFF.
__["pOut"]("LEC MISSION_RUNNER v%VERSION_NUMBER%").
{
  function mission_runner {
    parameter sq is list(), events is lex(), m_d is lex().
    local data is lex().
    __["pOut"]("starting mission runner").
    local rm is 0. local done is 0.

    // This object gets passed to sequences and events, to allow them to
    // interact with the event loop.
    local mission is lex(
      "add_event", a_e@,
      "remove_event", r_e@,
      "next", nx@,
      "switch_to", s_t@,
      "runmode", r_r@,
      "terminate", t@,
      "add_data", a_d@,
      "remove_data", r_d@,
      "get_data", g_d@,
      "has_data", h_d@
    ).

    // Recover runmode from disk
    local rmp is __["findPath"]("mission.runmode").
    if rmp <> "" {
      local l_m is open(rmp):readall():string.
      local n is indexof(sq, l_m).
      if n <> -1 u_r(n / 2).
    }

    // Main event loop
    until done or rm * 2 >= sq:length {
      sq[rm * 2 + 1](mission).
      for event in events:keys {
          events[event](mission).
      }
      wait 0.
    }
    set rmp to __["findPath"]("mission.runmode").
    if rmp <> ""
      __["delScript"](rmp).

    // Update runmode, persisting to disk
    function u_r {
      parameter n.
      s_st().
      if sq:length >= (2*n) {
        __["store"](sq[2 * n], "mission.runmode").
        set rm to n.
        l_st().
      }
    }

    function s_st {
      local d is lex().
      local dfp is __["findPath"]("mission.data").
      if dfp <> "" {
        set d to readjson(dfp).
      }
      if data:length > 0 {
        set d[r_r()] to data.
      } else {
        if d:haskey(r_r()) d:remove(r_r()).
      }
      set d["__MISSION__"] to m_d.
      if dfp <> ""
        __["delScript"](dfp).
      set dfp to __["findSpace"]("mission.data", d:dump:length * 1.2).
      if dfp = "" {
          __["pOut"]("Unable to save all mission data. Deleting previous runmode data.").
          local dndx is 0.
          until dfp <> "" or dndx >= rm {
              d:REMOVE(sq[dndx * 2]).
              set dndx to dndx + 1.
              set dfp to __["findSpace"]("mission.data", d:dump:length * 1.2).
          }
      }
      if dfp <> ""
        writejson(d, dfp).
      else
        __["hudMsg"]("Unable to save mission data. Mission success in danger.").
    }

    function l_st {
      local d is lex().
      local dfp is __["findPath"]("mission.data").
      if dfp <> ""
        set d to readjson(dfp).
      set data to lex().
      if d:haskey(r_r()) set data to d[r_r()].
      if d:haskey("__MISSION__") set m_d to d["__MISSION__"].
      else set m_d to lex().
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
    function a_e {
      parameter n, d.
      set events[n] to d.
    }

    // Remove an event by name
    function r_e {
      parameter n.
      if events:haskey(n) {
          events:remove(n).
      }
    }

    // Switch to the next available runmode
    function nx {
      u_r(rm + 1).
    }

    // Switch to a specific runmode by name
    function s_t {
      parameter n.
      u_r(indexof(sq, n) / 2).
    }

    // Return the current runmode (read-only)
    function r_r {
      if sq:length <= (rm*2) {
        return sq[rm * 2].
      }
      return false.
    }

    // Add a key/value pair
    function a_d {
      parameter k, vl, ig is false.
      if ig
        set m_d[k] to vl.
      else
        set data[k] to vl.
      s_st().
    }

    // Remove a key/value pair
    function r_d {
      parameter k.
      if data:haskey(k) {
          data:remove(k).
      }
      if m_d:haskey(k) {
          m_d:remove(k).
      }
      s_st().
    }

    // Retreive the value for a given key
    function g_d {
      parameter k.
      if data:haskey(k)
        return data[k].
      else
        return m_d[k].
    }

    // Checks for existance of a key
    function h_d {
      parameter k.
      return data:haskey(k) or m_d:haskey(k).
    }

    // Allow explicit termination of the event loop
    function t {
      set done to 1.
    }
  }

  global run_mission is mission_runner@.
  export(mission_runner@).
}
