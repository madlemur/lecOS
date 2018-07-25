{
    local self is lex(
        "main", main@
    ).
    // Functional Launch Script

    function main {
      doLaunch().
      doAscent().
      until apoapsis > 100000 {
        doAutoStage().
      }
      doShutdown().
      doCircularization().
      doTransfer().
      print "It ran!".
      wait until false.
    }

    function doCircularization {
      local circ is list(0).
      set circ to improveConverge(circ, eccentricityScore@).
      executeManeuver(list(time:seconds + eta:apoapsis, 0, 0, circ[0])).
    }

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

    function doTransfer {
      local transfer is list(time:seconds + 30, 0, 0, 0).
      set transfer to improveConverge(transfer, protectFromPast(munTransferScore@)).
      local mnv is node(transfer[0], transfer[1], transfer[2], transfer[3]).
      addManeuverToFlightPlan(mnv).
      // executeManeuver(transfer).
    }

    function munTransferScore {
      parameter data.
      local mnv is node(data[0], data[1], data[2], data[3]).
      addManeuverToFlightPlan(mnv).
      local result is 0.
      if mnv:orbit:hasNextPatch {
        set result to mnv:orbit:nextPatch:periapsis.
      } else {
        set result to distanceToMunAtApoapsis(mnv).
      }
      removeManeuverFromFlightPlan(mnv).
      return result.
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

    function eccentricityScore {
      parameter data.
      local mnv is node(time:seconds + eta:apoapsis, 0, 0, data[0]).
      addManeuverToFlightPlan(mnv).
      local result is mnv:orbit:eccentricity.
      removeManeuverFromFlightPlan(mnv).
      return result.
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
      local mnv is node(mList[0], mList[1], mList[2], mList[3]).
      addManeuverToFlightPlan(mnv).
      local startTime is calculateStartTime(mnv).
      wait until time:seconds > startTime - 10.
      lockSteeringAtManeuverTarget(mnv).
      wait until time:seconds > startTime.
      lock throttle to 1.
      until isManeuverComplete(mnv) {
        doAutoStage().
      }
      lock throttle to 0.
      unlock steering.
      removeManeuverFromFlightPlan(mnv).
    }

    function addManeuverToFlightPlan {
      parameter mnv.
      add mnv.
    }

    function calculateStartTime {
      parameter mnv.
      return time:seconds + mnv:eta - maneuverBurnTime(mnv) / 2.
    }

    function maneuverBurnTime {
      parameter mnv.
      local dV is mnv:deltaV:mag.
      local g0 is 9.80665.
      local isp is 0.

      list engines in myEngines.
      for en in myEngines {
        if en:ignition and not en:flameout {
          set isp to isp + (en:isp * (en:availableThrust / ship:availableThrust)).
        }
      }

      local mf is ship:mass / constant():e^(dV / (isp * g0)).
      local fuelFlow is ship:availableThrust / (isp * g0).
      local t is (ship:mass - mf) / fuelFlow.

      return t.
    }

    function lockSteeringAtManeuverTarget {
      parameter mnv.
      lock steering to mnv:burnvector.
    }

    function isManeuverComplete {
      parameter mnv.
      if not(defined originalVector) or originalVector = -1 {
        declare global originalVector to mnv:burnvector.
      }
      if vang(originalVector, mnv:burnvector) > 90 {
        declare global originalVector to -1.
        return true.
      }
      return false.
    }

    function removeManeuverFromFlightPlan {
      parameter mnv.
      remove mnv.
    }

    function doLaunch {
      lock throttle to 1.
      doSafeStage().
      doSafeStage().
    }

    function doAscent {
      lock targetPitch to 88.963 - 1.03287 * alt:radar^0.409511.
      set targetDirection to 90.
      lock steering to heading(targetDirection, targetPitch).
    }

    function doAutoStage {
      if not(defined oldThrust) {
        global oldThrust is ship:availablethrust.
      }
      if ship:availablethrust < (oldThrust - 10) {
        until false {
          doSafeStage(). wait 1.
          if ship:availableThrust > 0 {
            break.
          }
        }
        global oldThrust is ship:availablethrust.
      }
    }

    function doShutdown {
      lock throttle to 0.
      lock steering to prograde.
    }

    function doSafeStage {
      wait until stage:ready.
      stage.
    }
    export(self).
}
