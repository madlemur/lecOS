// lib_pipeline.ks
// 
// Using function delegates to allow function chaining.
// Based on Kevin Gisik's "kOS v0.19.0 Deep Dive - Pipelines" video

// Allows for up to an additional 5 parameters per chained function call.
// Be sure you know what you're doing, since there's no way to verify how many arguments a function takes,
// this will just pass all the arguments you provide to the function.

// Usage: Pipeline(value)(@function, arg2, ...)(@function, arg2, ...)(...)().

function Pipeline {
  parameter v0.
  local null is CHAR(0).

  function uf {
    parameter vn.

    function nf {
      parameter o  is null,
                a2 is null,
                a3 is null,
                a4 is null,
                a5 is null,
                a6 is null,
      if o  = null return vn.
      if a2 = null return uf(o(vn)).
      if a3 = null return uf(o(vn, a2)).
      if a4 = null return uf(o(vn, a2, a3)).
      if a5 = null return uf(o(vn, a2, a3, a4)).
      if a6 = null return uf(o(vn, a2, a3, a4, a5)).
                   return uf(o(vn, a2, a3, a4, a5, a6)).
    }

    return nf@.
  }

  return uf(v0).
}
