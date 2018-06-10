@LAZYGLOBAL OFF.
__["pOut"]("LEC STEERING v%VERSION_NUMBER%").
{
    local steer is lex(
        "isSteerOn", iso@,
        "steerOff", so@,
        "steerTo", st@,
        "steerSurf", ss@,
        "steerOrbit", sb@,
        "steerNormal", sn@,
        "steerSun", su@,
        "steerAV", sv@,
        "steerOk", sk@,
        "dampSteering", ds@
    ).
    LOCAL S_O is FALSE.

    FUNCTION iso
    {
        return S_O.
    }

    function so
    {
        IF S_O { __["pOut"]("Steering disengaged."). }
        SET S_O TO FALSE.
        UNLOCK STEERING.
    }

    FUNCTION st
    {
        PARAMETER fore IS { RETURN FACING:VECTOR. }, top IS { RETURN FACING:TOPVECTOR. }.
        IF NOT S_O { __["pOut"]("Steering engaged."). }
        SET S_O TO TRUE.
        LOCK STEERING TO LOOKDIRUP(fore(),top()).
        __["setTime"]("STEER").
    }

    FUNCTION ss
    {
        PARAMETER pro IS TRUE.
        IF pro { st({ RETURN SRFPROGRADE:VECTOR. }). }
        ELSE { st({ RETURN SRFRETROGRADE:VECTOR. }). }
    }

    FUNCTION sb
    {
        PARAMETER pro IS TRUE.
        IF pro { st({ RETURN PROGRADE:VECTOR. }). }
        ELSE { st({ RETURN RETROGRADE:VECTOR. }). }
    }

    FUNCTION sn
    {
        st({ RETURN VCRS(VELOCITY:ORBIT,-BODY:POSITION). }, { RETURN SUN:POSITION. }).
    }

    FUNCTION su
    {
        st({ RETURN SUN:POSITION. }).
    }

    FUNCTION sv
    {
        IF LIST("LANDED","SPLASHED"):CONTAINS(STATUS) { RETURN (2 * CONSTANT:PI / BODY:ROTATIONPERIOD). }
        RETURN VANG(VELOCITYAT(SHIP,TIME:SECONDS):ORBIT,VELOCITYAT(SHIP,TIME:SECONDS+1):ORBIT) * CONSTANT:DEGTORAD.
    }

    FUNCTION sk
    {
        PARAMETER aoa IS 1, p IS 4, t IS 60.
        IF  __["diffTime"]("STEER") <= 0.1 { RETURN FALSE. }
        IF NOT STEERINGMANAGER:ENABLED { __["hudMsg"]("ERROR: Steering Manager not enabled!"). }

        IF VANG(STEERINGMANAGER:TARGET:VECTOR,FACING:VECTOR) < aoa AND
         SHIP:ANGULARVEL:MAG * p / 10 < MAX(sv(), 0.0005) {
            __["pOut"]("Steering aligned.").
            RETURN TRUE.
        }
        IF __["diffTime"]("STEER") > t {
            __["pOut"]("Steering alignment timed out.").
            RETURN TRUE.
        }
        RETURN FALSE.
    }

    FUNCTION ds
    {
        __["pOut"]("Damping steering.").
        LOCAL cur_f IS FACING:VECTOR.
        st({ RETURN cur_f. }).
        WAIT UNTIL sk().
        so().
    }
    export(steer).
}
