{
    local maneuver is import("lib/maneuver.ks", false).
    local self is lex(
        "setTransfer", setTransfer@
    ).
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

    function setTransfer {
      parameter peri is 80000.
      local transfer is list(time:seconds + 30, 0, 0, 0).
      set transfer to improveConverge(transfer, protectFromPast(munTransferScore@:bind(peri))).
      local transNode is Node(transfer[0], transfer[1], transfer[2], transfer[3]).
      add transNode.
    }

    function munTransferScore {
      parameter peri.
      parameter data.
      local mnv is node(data[0], data[1], data[2], data[3]).
      add mnv.
      local result is 0.
      if mnv:orbit:hasNextPatch {
        set result to mnv:orbit:nextPatch:periapsis.
      } else {
        set result to distanceToMunAtApoapsis(mnv).
      }
      remove mnv.
      return abs(result - peri).
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

    function altitudeAt {
      parameter t.
      return (positionAt(ship, t) - positionAt(Kerbin, t)):mag.
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

    function improveConverge {
      parameter data, scoreFunction.
      for stepSize in list(100, 10, 1) {
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

    function improve {
      parameter data, stepSize, scoreFunction.
      local scoreToBeat is scoreFunction(data).
      local bestCandidate is data.
      local candidates is list().
      local index is 0.
      until index >= data:length {
        local incCandidate is data:copy().
        local decCandidate is data:copy().
        set incCandidate[index] to incCandidate[index] + stepSize.
        set decCandidate[index] to decCandidate[index] - stepSize.
        candidates:add(incCandidate).
        candidates:add(decCandidate).
        set index to index + 1.
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

    function executeManeuver {
      parameter mList.
      local mnvNode is Node(mList).
      add mnvNode.
      maneuver["orientCraft"](mnvNode).
      wait until maneuver["isOriented"](mnvNode).
      until maneuver["nodeComplete"](mnvNode) { wait 0. doAutoStage(). }
      lock throttle to 0.
      unlock steering.
    }

    function doShutdown {
      lock throttle to 0.
      lock steering to prograde.
    }

    export(self).
}
