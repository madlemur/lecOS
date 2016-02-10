//debug vectors
local i is 0.
global debug_vector is list().
local colors is list( rgb(0,1,0), rgb(0,0,1), rgb(1,0,0), rgb(1,1,0), rgb(0,1,1), rgb(1,1,1) ).

until i >= 6 {
  debug_vector:add( vecDrawArgs( v(0,0,0), v(0,0,0), colors[i] , "debug #" + i, 1, false) ).
  set i to i + 1.
}
