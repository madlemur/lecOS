@LAZYGLOBAL OFF.
pout("LEC MUN v%VERSION_NUMBER%").
{
    local maneuver is import("lib/maneuver.ks", false).
    local self is lex(
        "setMunTransfer", setMunTransfer@
    ).
    local transnode is 0.
    // Functional Launch Script

    function protectFromPast {
      parameter originalFunction.
      local replacementFunction is {
        parameter data.
        if data[0] < time:seconds + 15 {
          return 2^64.
        } else {
          return originalFunction(data).
        }
      }.
      return replacementFunction@.
    }

    function setMunTransfer {
      parameter peri is 80000.
      local transfer is list(time:seconds + 30, 0, 0, 0).
      set transNode to Node(transfer[0], transfer[1], transfer[2], transfer[3]).
      add transNode.
      wait 0.
      set transfer to improveConverge(transfer, protectFromPast(munTransferScore@:bind(peri))).
      set transnode:eta to transfer[0] - TIME:SECONDS.
      set transnode:radialout to transfer[1].
      set transnode:normal to transfer[2].
      set transnode:prograde to transfer[3].
    }

    function munTransferScore {
      parameter peri.
      parameter data.
      set transnode:eta to data[0] - TIME:SECONDS.
      set transnode:radialout to data[1].
      set transnode:normal to data[2].
      set transnode:prograde to data[3].
      local result is 0.
      if transnode:orbit:hasNextPatch {
        set result to transnode:orbit:nextPatch:periapsis.
        if abs(transnode:orbit:netPatch:inclination) > 90 {
          set result to transnode:orbit:netPatch:body:soiradius - 1/result to transnode:orbit:nextPatch:periapsis.
        }
      } else {
        set result to distanceToMunAtApoapsis(transnode).
      }
      if result < 0 { set result to result^2 + Mun:radius. }
      return abs(result - peri).
    }

    function altitudeAt {
      parameter t.
      return (positionAt(ship, t) - positionAt(Kerbin, t)):mag.
    }

    function distanceToMunAtApoapsis {
      parameter mnv.
      local apoapsisTime is ternarySearch(
        altitudeAt@,
        time:seconds + mnv:eta,
        time:seconds + mnv:eta + (mnv:orbit:period / 2),
        1
      ).
      return (positionAt(ship, apoapsisTime) - positionAt(Mun, apoapsisTime)):mag.
    }

    function improveConverge {
      parameter data, scoreFunction.
      for stepSize in list(list(100, 0, 0, 100), list(10, 0, 0, 10), list(1, 1, 0, 1)) {
        until false {
          local oldScore is scoreFunction(data).
          set data to improve(data, stepSize, scoreFunction).
          if oldScore <= scoreFunction(data) {
            break.
          }
        }
      }
      return data.
    }

    function ternarySearch {
      parameter f, left, right, absolutePrecision.
      until false {
        if abs(right - left) < absolutePrecision {
          return (left + right) / 2.
        }
        local leftThird is left + (right - left) / 3.
        local rightThird is right - (right - left) / 3.
        if f(leftThird) < f(rightThird) {
          set left to leftThird.
        } else {
          set right to rightThird.
        }
      }
    }

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
      // If the list is shorter than the data list, don't try to improve those data points
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
