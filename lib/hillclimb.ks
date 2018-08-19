@LAZYGLOBAL OFF.
pout("LEC HILLCLIMB v%VERSION_NUMBER%").
{
    local self is lexicon (
        "improve", improve@
    ).

    function improve {
      parameter data, stepSize, scoreFunction.
      local scoreToBeat is scoreFunction(data).
      local bestCandidate is data.
      local candidates is list().
      local index is 0.
      // If stepsize is a scalar, use it for all data values
      if (not stepSize:isType("List")) {
          local foo is list().
          FROM { local i is 0. } UNTIL i < data:length STEP { set i to i + 1. } DO { foo:add(stepSize). }
          set stepSize to foo.
      }
      // If the list is shorter than the data list, don't try to improve extra data points
      if stepSize:length < data:length {
          from { local i is stepSize:length. } until i > data:length step { set i to i + 1. } do { stepSize:add(0). }
      }

      from { local index is 0. } until index >= data:length step { set index to index + 1. } do {
        if stepSize[index] > 0 {
            local incCandidate is data:copy().
            local decCandidate is data:copy().
            set incCandidate[index] to incCandidate[index] + stepSize[index].
            set decCandidate[index] to decCandidate[index] - stepSize[index].
            candidates:add(incCandidate).
            candidates:add(decCandidate).
          }
      }
      for candidate in candidates {
        local candidateScore is scoreFunction(candidate).
        if candidateScore < scoreToBeat {
          set scoreToBeat to candidateScore.
          set bestCandidate to candidate.
        }
      }
      return bestCandidate.
    }

    export(self).
}
