{
  local f is "1:/runmode.ks".
  local df is "1:/datafile.json".
  export(
    {
      parameter d.
      local r is 0.
      if exists(f)
        set r to import("runmode.ks").
      local s is list().
      local e is lex().
      local v is lex().
      if exists(df) {
        local nv is readjson(df).
        v:clear().
        for t in nv:keys
          v:add(t, nv[t]).
      }
      local n is {
        parameter m is r+1.
        if not exists(f)
          create(f).
        local h is open(f).
        h:clear().
        h:write("export("+m+").").
        writejson(v, df).
        set r to m.
      }.
      d(s,e,v,n).
      return {
        until r>=s:length {
          if exists(df) {
            local nv is readjson(df).
            v:clear().
            for t in nv:keys
              v:add(t, nv[t]).
          }
          s[r]().
          writejson(v, df).
          for t in e:values
            t().
          wait 0.
        }
      }.
    }
  ).
}
