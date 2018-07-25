@LAZYGLOBAL OFF.
PRINT("LEC TANGENT TRANSFERS v%VERSION_NUMBER%").
{
    local self is lex(
      "findTransferManeuvers", findTransferManeuvers@
    ).
    local tgt is false.



    function buildCandidateTable {
        PARAMETER maxSeparation=0.01. // In degrees of True Anomaly
        PARAMETER maxorb=10.
        local currOrbit is 0.
        local currTA is SHIP:ORBIT:TRUEANOMALY.
        local currEcc is SHIP:ORBIT:ECCENTRICITY.
        if currEcc > 0.01 {
            pout("Current orbit too eccentric, circularize first.").
            return false.
        }
        if SHIP:ORBIT:APOAPSIS > TGT:ORBIT:PERIAPSIS {
            pout("Current orbit must be wholly within the target orbit, lower the orbital altitude.").
            return false.
        }
        local currEA is 2 * arctan( sqrt((1-currEcc)/(1+currEcc)) * tan(currTA/2)).
        local currRAD is SQRT(SHIP:ORBIT:SEMIMAJORAXIS * SHIP:ORBIT:SEMIMINORAXIS).

        local tgtTA is TGT:ORBIT:TRUEANOMALY.
        local tgtEcc is TGT:ORBIT:ECCENTRICITY.
        if tgtEcc < 0.1 {
            pout("Target orbit too circular, use a Hohmann transfer.").
            return false.
        }
        local tgtSM is TGT:ORBIT:SEMIMAJORAXIS.
        local tgtEA is 2 * arctan( sqrt((1-tgtEcc)/(1+tgtEcc)) * tan(tgtTA/2)).
        local alpha is { parameter k. return arccos(((2 - 2*tgtEcc^2)/(k*(2-k)))-1). }.
        local beta is { parameter k. return arccos(tgtEcc/k - 1/k*tgtEcc + 1/tgtEcc). }.
        local intSM is { parameter k. local a is alpha(k). return ((tgtSM^2 * k^2 * cos(a) + tgtSM^2 * k^2 - 2 * currRAD^2)/(2*tgtSM*k*cos(a) + 2*tgtSM*k - 4*currRAD)). }.
        local theta is { parameter k. local ism is intSM(k). return arccos((ism * currSM * k - 2 * currSM * currRAD + currRAD^2)/(ism * currSM * k - ism * k * currRAD)). }.
        local intLongPeri is { parameter k. parameter prePeri is false. if prePeri {return return beta(k) - theta(k). } else { return -(beta(k) -theta(k)). } }.
        local intEcc is { parameter k. return 1 - currRAD/intSM(k). }.
        local intEA is { parameter k. parameter prePeri is false. local ecc is intEcc(k). local f is 0. if prePeri { set f to 180 + theta(k). } else { set f to 180 - theta(k). } return arccos((ecc + cos(f))/(1+ecc*cos(f))). }.
        local arrival is { parameter k. parameter prePeri is false. return (((intSM(k)^(3/2)) * ( (intEA(k, prePeri) - intEcc(k) * sin(intEA(k, prePeri)))/180)). }.
        local departure is { parameter k. parameter prePeri is false. return (((__["mAngle"](intLongPeri(k, prePeri) - currTA)/360) + currOrbit) * SHIP:ORBIT:PERIOD). }.
        local intV is { parameter k. return sqrt( BODY:MU * ((2/(k*tgtSM)) - 1/intSM(k))). }.
        local intVi is { parameter k. return sqrt(BODY:MU/currRAD). }.
        local tgtV is { parameter k. return sqrt( BODY:MU * ((2/(k*tgtSM)) - 1/tgtSM)). }.
        local intDv is { parameter k. return intVi(k) - 360 * sqrt( 1/currRAD ). }.
        local tgtTAint is {
            parameter k.
            parameter prePeri is false.
            local t is arrival(k, prePeri) + departure(k, prePeri) + SHIP:ORBIT:PERIOD * currOrbit.
            local b is sqrt(body:mu/tgtSM^3) * t.
            local c is 6 - 6 * tgtEcc.
            local d is -6 * b.
            local delta_root is sqrt(d^2 + (4*c^3)/27).
            local x is ((-d -delta_root)/2)^(1/3) + ((-d + delta_root)/2)^(1/3).

            local p is a/6.
            local q1 is (tgtEcc*x)/2.
            local s is -x * (tgtEcc + 1).
            local v_in1 is (-(b^3)/(27*a^3))+((b*c)/(6*a^2))-(d/(2*a)).
            local v_in2 is v_in1^2 + ((c/(3*a)) - (b^2/9*a^2))^3.
            return (v_in1 + sqrt(v_in2))^(1/3) + (v_in1 - sqrt(v_in2))^(1/3) - b/(3*a).
        }

        local solutions is list().
        FROM { local k is 0.0. } UNTIL k = 360.0 STEP { SET k TO k + 1.0. } {
            solutions:insert(k, list(k, departure(k, false), arrival(k, false), intDv(k), mod(abs(theta(k) - tgtTAint(k, false)), 360))).
            if k > 0 { solutions:insert(-k, list(k, departure(k, true), arrival(k, true), intDv(k), mod(abs(360 - theta(k) - tgtTAint(k, true)), 360))). }
        }







        local fitness is {
            parameter k.
            parameter prePeri is false.
            local intA is theta(k).
            local tgtA is tgtTAint(k, prePeri).
            return ABS(intA - tgtA).
        }

        function hillclimb {
            parameter k.
            parameter increment.
            parameter fitVal is 2^64.
            local bestFit is k.
            local checkVal is 2^64.
            local prePeri is false.
            if k < 0 {
                set k to -k.
                set prePeri to true.
            }
            if fitVal = 2^64 {
                set fitVal to fitness(k, prePeri).
            }
            local farInc is 5 * increment.
            function test {
                parameter checkFit.
                parameter prePeri.
                if checkFit >= lowerB AND checkfit <= upperB {
                    local checkVal is fitness(checkFit, prePeri).
                    if checkVal < fitVal {
                        return list(checkVal, checkFit).
                    }
                }
                return list(fitVal, bestFit).
            }
            local oldVal is fitVal.
            until false {
                local checkRes is test(k - farInc, prePeri).
                set fitVal to checkRes[0].
                set bestFit to checkRes[1].
                set checkRes to test(k - increment, prePeri).
                set fitVal to checkRes[0].
                set bestFit to checkRes[1].
                set checkRes is test(k + farInc, prePeri).
                set fitVal to checkRes[0].
                set bestFit to checkRes[1].
                set checkRes to test(k + increment, prePeri).
                set fitVal to checkRes[0].
                set bestFit to checkRes[1].
                if oldVal <= fitVal {
                    return list(bestFit, fitVal).
                }
                set oldVal to fitVal.
        }

        local upperB is 1 + tgtEcc.
        local lowerB is 1 - tgtEcc.
        local minDeparture is 60.
        local currentIncrement is tgtEcc / 180.
        local solutions is list().
        local testFit is 0.
        from { local k is 1 - tgtEcc. } until k >= 1 + tgtEcc step { set k to k + currentIncrement } {
            if k > 1e-8 {
                set testFit to fitness(k, false).
                if testFit < maxSeparation {
                    solutions:add(list(currOrbit, k, false, testFit)).
                }
                set testFit to fitness(k, true).
                if testFit < maxSeparation {
                    solutions:add(list(currOrbit, k, true, testFit)).
                }
            }
        }



        local climbresults is hillclimb(0, currentIncrement).
        local oldresults is climbresults:copy.
        until climbresults[1] < maxSeparation OR oldresults[0] = climbresults[0] OR oldresults[1] <= climbresults[1] OR currentIncrement < 1e-16 {
            set currentIncrement to currentIncrement * 0.5.
            set climbresults to hillclimb(climbresults[0], currentIncrement * 0.5).
        }
        if climbresults[1] < maxSeparation {
            solutions:add(currOrbit, climbresults[0]).
        }
        // compute next transfer maneuver to target orbit
        return list(10,0,0,0).
    }

    export(self).
}
