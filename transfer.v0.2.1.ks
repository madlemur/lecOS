// Maneuver Node Transfer Library v0.2.1
// Kevin Gisi
// http://youtube.com/gisikw

{
  local MANEUVER_LEAD_TIME is 600.
  local SLOPE_THRESHHOLD is 1.
  local INFINITY is 2^64.

  global transfer is lex(
    "version", "0.2.1",
    "seek", seek@
  ).

  function seek {
    parameter target_body, target_periapsis.
    local attempt is 1.
    local data is starting_data(attempt).

    // Seek encounter, advancing start time if we get stuck
    until 0 {
      set data to hillclimb["seek"](data, transfer_fit(target_body), 100).
      set data to hillclimb["seek"](data, transfer_fit(target_body), 50).
      set data to hillclimb["seek"](data, transfer_fit(target_body), 10).
      set data to hillclimb["seek"](data, transfer_fit(target_body), 1).
      set data to hillclimb["seek"](data, transfer_fit(target_body), 0.5).
      set data to hillclimb["seek"](data, transfer_fit(target_body), 0.25).
      set data to hillclimb["seek"](data, transfer_fit(target_body), 0.1).
      set data to hillclimb["seek"](data, transfer_fit(target_body), 0.05).

      local tnode is make_node(data).
      add tnode. wait 0.01.

      if target_body:istype("Body") and transfers_to(nextnode, target_body) {
        remove tnode. wait 0.01.
        break.
      }

      if target_body:istype("Vessel") {
        local atime is time:seconds + tnode:eta + tnode:orbit:period/2.
        local adist is (positionat(target_body, atime) - positionat(ship, atime)):mag.
        print adist + "m".
        if adist < target_periapsis {
          remove tnode. wait 0.01.
          break.
        }
      }
      remove tnode. wait 0.01.
      set attempt to attempt + 1.
      set data to starting_data(attempt).
    }

    if target_body:istype("Body") {
      // Refine for inclination
      set data to hillclimb["seek"](data, inclination_fit(target_body), 10).
      set data to hillclimb["seek"](data, inclination_fit(target_body), 1).
      set data to hillclimb["seek"](data, inclination_fit(target_body), 0.1).
      // Refine for periapsis
      set data to hillclimb["seek"](data, periapsis_fit(target_body, target_periapsis), 10).
      set data to hillclimb["seek"](data, periapsis_fit(target_body, target_periapsis), 1).
    }
    remove_any_nodes().
    return make_node(data).
  }

  function transfer_fit {
    parameter target_body.
    function fitness_fn {
      parameter data.
      local maneuver is make_node(data).
      remove_any_nodes().
      add maneuver. wait 0.01.
      if target_body:istype("Body") {
        if transfers_to(maneuver, target_body) {
          remove maneuver. wait 0.01. return 1.
        }
      }
      local fitness is -INFINITY.
      if maneuver:orbit:periapsis > body:atm:height {
        local fitness_check is closest_approach(
          target_body,
          time:seconds + maneuver:eta,
          time:seconds + maneuver:eta + maneuver:orbit:period
        ).
        set fitness to -fitness_check.
      }
      remove maneuver. wait 0.01.
      return fitness.
    }
    return fitness_fn@.
  }

  function inclination_fit {
    parameter target_body.
    function fitness_fn {
      parameter data.
      local maneuver is make_node(data).
      add maneuver. wait 0.01.
      if target_body:istype("Body") {
        if not transfers_to(maneuver, target_body) {
          remove maneuver. wait 0.01. return -INFINITY.
        }
        local fitness is -abs(maneuver:orbit:nextpatch:inclination).
        remove maneuver. wait 0.01. return fitness.
      }
      if target_body:istype("Vessel") {
        local itime is time:seconds + maneuver:eta + maneuver:orbit:period.
        local vang_diff is vang(vcrs(target_body:velocity:orbit, target_body:position - target_body:body:position),
                                vcrs(velocityat(ship, itime):orbit, positionat(ship:body, itime))).
        remove maneuver. wait 0.01.
        return -vang_diff.
      }
    }
    return fitness_fn@.
  }

  // TODO: There's a lot of shared code in these fitness functions. Probably
  // means some stuff can be merged / abstracted
  function periapsis_fit {
    parameter target_body, target_periapsis.
    function fitness_fn {
      parameter data.
      local maneuver is make_node(data).
      remove_any_nodes().
      add maneuver. wait 0.01.
      if target_body:istype("Body") {
        if not transfers_to(maneuver, target_body) {
          remove maneuver. wait 0.01. return -INFINITY.
        }
        local fitness is -abs(maneuver:orbit:nextpatch:periapsis - target_periapsis).
        remove maneuver. wait 0.01. return fitness.
      } else if target_body:istype("Vessel") {
        local fitness is -INFINITY.
        if maneuver:orbit:periapsis > body:atm:height {
          local fitness_check is closest_approach(
            target_body,
            time:seconds + maneuver:eta,
            time:seconds + maneuver:eta + maneuver:orbit:period
          ).
          set fitness to -fitness_check[0].
        }
        remove maneuver. wait 0.01.
        return fitness.
      }
    }
    return fitness_fn@.
  }

  function closest_approach {
    parameter target_body, start_time, end_time.
    local start_slope is slope_at(target_body, start_time).
    local end_slope is slope_at(target_body, end_time).
    local middle_time is (start_time + end_time) / 2.
    local middle_slope is slope_at(target_body, middle_time).
    until (end_time - start_time < 0.1) or middle_slope < 0.1 {
      if (middle_slope * start_slope) > 0
        set start_time to middle_time.
      else
        set end_time to middle_time.
      set middle_time to (start_time + end_time) / 2.
      set middle_slope to slope_at(target_body, middle_time).
    }
    return separation_at(target_body, middle_time).
  }

  function slope_at {
    parameter target_body, at_time.
    return (
      separation_at(target_body, at_time + 1) -
      separation_at(target_body, at_time - 1)
    ) / 2.
  }

  function separation_at {
    parameter target_body, at_time.
    return (positionat(ship, at_time) - positionat(target_body, at_time)):mag.
  }

  function transfers_to {
    parameter maneuver, target_body.
    return (
      target_body:istype("Body") and
      maneuver:orbit:hasnextpatch and
      maneuver:orbit:nextpatch:body = target_body
    ).
  }

  function starting_data {
    parameter attempt.
    return list(time:seconds + MANEUVER_LEAD_TIME * attempt, 0, 0, 0).
  }

  function make_node {
    parameter data.
    return node(data[0], data[1], data[2], data[3]).
  }

  function remove_any_nodes {
    until not hasnode {
      remove nextnode. wait 0.01.
    }
  }
}
