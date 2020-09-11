@lazyGlobal off.
// libLoader - Initializes shared library strucures and global functions
print("Initializing library management...").
{
  LOCAL s is stack().
  LOCAL d is lex().

  /////////////////////////////////
  // Any library that is import'ed
  // MUST export itself as its last
  // instruction
  /////////////////////////////////
  global import is {
    parameter n.
    if n:istype("STRING") or n:istype("PATH") {
        local p is PATH(n).
        if not d:haskey(p:NAME) {
            s:push(p:NAME).
            RUNONCEPATH(p).
        }
        return d[p:NAME].
    } else {
        return.
    } 
  }.

  global export is {
    parameter v.
    set d[s:pop()] to v.
  }.
}