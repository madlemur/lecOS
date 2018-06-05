{
  local event_lib is lex(
    "staging", staging@
  ).

  function staging {
    parameter mission.
    local englist is list().
    // We're going to cache the engine list to avoid walking the part tree every tick.
    if not event_lib:haskey("englist") {
      output("Enumerating engines", true).
      list engines in englist.
      set event_lib["englist"] to englist.
    }
    local flameout is false.
    set englist to event_lib["englist"].
    for eng in englist { if eng:flameout { set flameout to true. break. } }
    if flameout or maxthrust = 0 {
      if flameout
        // Since an engine has flamed out, there's an implicit assumption that the engine list will change
        event_lib:remove("englist").
      stage.
      steeringmanager:resetpids().
    }
  }

  export(event_lib).
}
