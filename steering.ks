{
    local steer is lex(
        "isSteerOn", isSteerOn@,
        "steerOff", steerOff@,
        "steerTo", steerTo@,
        "steerSurf", steerSurf@,
        "steerOrbit", steerOrbit@,
        "steerNormal", steerNormal@,
        "steerSun", steerSun@,
        "steerAV", steerAV@,
        "steerOk", steerOk@,
        "dampSteering", dampSteering@
    ).
    LOCAL STEER_ON is FALSE.

    FUNCTION isSteerOn
    {
        return STEER_ON.
    }

    function steerOff
    {
        IF STEER_ON { __["pOut"]("Steering disengaged."). }
        SET STEER_ON TO FALSE.
        UNLOCK STEERING.
    }

    FUNCTION steerTo
    {
        PARAMETER mission, fore IS { RETURN FACING:VECTOR. }, top IS { RETURN FACING:TOPVECTOR. }.
        IF NOT STEER_ON { __["pOut"]("Steering engaged."). }
        SET STEER_ON TO TRUE.
        LOCK STEERING TO LOOKDIRUP(fore(),top()).
        mission["setTime"]("STEER").
    }

    FUNCTION steerSurf
    {
        PARAMETER mission, pro IS TRUE.
        IF pro { steerTo(mission, { RETURN SRFPROGRADE:VECTOR. }). }
        ELSE { steerTo(mission, { RETURN SRFRETROGRADE:VECTOR. }). }
    }

    FUNCTION steerOrbit
    {
        PARAMETER mission, pro IS TRUE.
        IF pro { steerTo(mission, { RETURN PROGRADE:VECTOR. }). }
        ELSE { steerTo(mission, { RETURN RETROGRADE:VECTOR. }). }
    }

    FUNCTION steerNormal
    {
        PARAMETER mission.
        steerTo(mission, { RETURN VCRS(VELOCITY:ORBIT,-BODY:POSITION). }, { RETURN SUN:POSITION. }).
    }

    FUNCTION steerSun
    {
        PARAMETER mission.
        steerTo(mission, { RETURN SUN:POSITION. }).
    }

    FUNCTION steerAV
    {
        IF LIST("LANDED","SPLASHED"):CONTAINS(STATUS) { RETURN (2 * CONSTANT:PI / BODY:ROTATIONPERIOD). }
        RETURN VANG(VELOCITYAT(SHIP,TIME:SECONDS):ORBIT,VELOCITYAT(SHIP,TIME:SECONDS+1):ORBIT) * CONSTANT:DEGTORAD.
    }

    FUNCTION steerOk
    {
        PARAMETER mission, aoa IS 1, precision IS 4, timeout_secs IS 60.
        IF  mission["diffTime"]("STEER") <= 0.1 { RETURN FALSE. }
        IF NOT STEERINGMANAGER:ENABLED { __["hudMsg"]("ERROR: Steering Manager not enabled!"). }

        IF VANG(STEERINGMANAGER:TARGET:VECTOR,FACING:VECTOR) < aoa AND
         SHIP:ANGULARVEL:MAG * precision / 10 < MAX(steerAV(), 0.0005) {
            __["pOut"]("Steering aligned.").
            RETURN TRUE.
        }
        IF mission["diffTime"]("STEER") > timeout_secs {
            pOut("Steering alignment timed out.").
            RETURN TRUE.
        }
        RETURN FALSE.
    }

    FUNCTION dampSteering
    {
        PARAMETER mission.
        __["pOut"]("Damping steering.").
        LOCAL cur_f IS FACING:VECTOR.
        steerTo(mission, { RETURN cur_f. }).
        WAIT UNTIL steerOk(mission).
        steerOff().
    }
    export(steer).
}
