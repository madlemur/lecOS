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
        PARAMETER m, fore IS { RETURN FACING:VECTOR. }, top IS { RETURN FACING:TOPVECTOR. }.
        IF NOT S_O { __["pOut"]("Steering engaged."). }
        SET S_O TO TRUE.
        LOCK STEERING TO LOOKDIRUP(fore(),top()).
        m["setTime"]("STEER").
    }

    FUNCTION ss
    {
        PARAMETER m, pro IS TRUE.
        IF pro { st(m, { RETURN SRFPROGRADE:VECTOR. }). }
        ELSE { st(m, { RETURN SRFRETROGRADE:VECTOR. }). }
    }

    FUNCTION sb
    {
        PARAMETER m, pro IS TRUE.
        IF pro { st(m, { RETURN PROGRADE:VECTOR. }). }
        ELSE { st(m, { RETURN RETROGRADE:VECTOR. }). }
    }

    FUNCTION sn
    {
        PARAMETER m.
        st(m, { RETURN VCRS(VELOCITY:ORBIT,-BODY:POSITION). }, { RETURN SUN:POSITION. }).
    }

    FUNCTION su
    {
        PARAMETER m.
        st(m, { RETURN SUN:POSITION. }).
    }

    FUNCTION sv
    {
        IF LIST("LANDED","SPLASHED"):CONTAINS(STATUS) { RETURN (2 * CONSTANT:PI / BODY:ROTATIONPERIOD). }
        RETURN VANG(VELOCITYAT(SHIP,TIME:SECONDS):ORBIT,VELOCITYAT(SHIP,TIME:SECONDS+1):ORBIT) * CONSTANT:DEGTORAD.
    }

    FUNCTION sk
    {
        PARAMETER m, aoa IS 1, p IS 4, t IS 60.
        IF  m["diffTime"]("STEER") <= 0.1 { RETURN FALSE. }
        IF NOT STEERINGMANAGER:ENABLED { __["hudMsg"]("ERROR: Steering Manager not enabled!"). }

        IF VANG(STEERINGMANAGER:TARGET:VECTOR,FACING:VECTOR) < aoa AND
         SHIP:ANGULARVEL:MAG * p / 10 < MAX(sv(), 0.0005) {
            __["pOut"]("Steering aligned.").
            RETURN TRUE.
        }
        IF m["diffTime"]("STEER") > t {
            __["pOut"]("Steering alignment timed out.").
            RETURN TRUE.
        }
        RETURN FALSE.
    }

    FUNCTION ds
    {
        PARAMETER m.
        __["pOut"]("Damping steering.").
        LOCAL cur_f IS FACING:VECTOR.
        st(m, { RETURN cur_f. }).
        WAIT UNTIL sk(m).
        so().
    }
    export(steer).
}
