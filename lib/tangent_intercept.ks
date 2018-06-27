@LAZYGLOBAL OFF.
// Based on "Finding Low delta V paths to NEOs"
// http://clowder.net/hop/railroad/TangentEllipses.pdf
pout("LEC TANGENT INTERCEPTS v%VERSION_NUMBER%").
{
    local self is lex().

    local tgt is SHIP.
    local transfer_burn is node().
    local intercept_burn is node().

    function getAlpha {
        parameter k, ecc.
        if k < 1 - ecc or k > 1 + ecc or ecc = 0 {
            return -1.
        }
        local val is ((2 - 2 * ecc^2)/(k*(2-k)))-1.
        set val to arccos(val).
        return(val).
    }

    function getBeta {
        parameter k, ecc.
        if k < 1 - ecc or k > 1 + ecc or ecc = 0 {
            return -1.
        }
        local val is (k + ecc^2 - 1)/(k * ecc).
        set val to arccos(val).
        return(val).
    }

    function getInterceptMajor {
        parameter k, a, alpha, per.
        local val is k^2 * a^2 * cos(alpha) + k^2 * a^2 - 2 * per.
        set val to val / (2*k*a*cos(alpha) + 2*k*a - 4*per).
        return(val).
    }

    function getTheta {
        parameter k, a, b, per.
        local val is a^2 + a*b*k - 2*a*per - b^2 + per^2.
        set val to val/(a*b*k - a*k*per).
        set val to arccos(val).
        return(val).
    }

    function getOmega {
        parameter beta, theta, afterApo is false.
        local val is beta-theta.
        if afterApo {
            return(val).
        } else {
            return(-val).
        }
    }
}
