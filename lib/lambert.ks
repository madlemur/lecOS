@LAZYGLOBAL OFF.
pout("LEC LAMBERT v%VERSION_NUMBER%").
{
    local self is lexicon (
        "lambert_problem", lambert_problem@,
        "lambert_solution", lambert_solution@
    ).
    local m_r1 is 0.
    local m_r2 is 0.
    local m_tof is 0.
    local m_mu is BODY:MU.
    local m_v1 is list(V(0,0,0)).
    local m_v2 is list(V(0,0,0)).
    local m_iters is list().
    local m_x is list().
    local m_s is 0.
    local m_c is 0.
    local m_lambda is 0.
    local m_Nmax is 0.
    local m_has_converged is true.
    local m_multi_revs is 0.

    function lambert_solution {
        return LIST(m_v1, m_v2, m_x, m_iters).
    }

    function lambert_problem {
        parameter r1, r2. // Two cartesian coordinates, origin at SOI body
        parameter tof. // Time of flight
        parameter mu is BODY:mu. // mu of SOI
        parameter max_r is 5. // maximum revolutions
        parameter cw is false. // true for retrograde orbit

        set m_r1 to r1.
        set m_r2 to r2.
        set m_tof to tof.
        set m_mu to mu.
        set m_has_converged to true.
        set m_multi_revs to max_r.

        if (tof <= 0) {
            pout("Time of flight is negative!").
            return false.
        }
        if (mu <= 0) {
            pout("Gravity parameter is zero or negative!").
            return false.
        }
        set m_c to sqrt((r2:x - r1:x) * (r2:x - r1:x) + (r2:y - r1:y) * (r2:y - r1:y)
                   + (r2:z - r1:z) * (r2:z - r1:z)).
        local R1 is m_r1:mag.
        local R2 is m_r2:mag.
        set m_s to (m_c + R1 + R2) / 2.0;
        local ir1 is V(0,0,0).
        local ir2 is V(0,0,0).
        local ih is V(0,0,0).
        local it1 is V(0,0,0).
        local it2 is V(0,0,0).
        local m_x is list().
        local m_iters is list().
        set ir1 to r1:normalized.
        set ir2 to r2:normalized.
        set ih to vcrs(ir1, ir2):normalized.

        if (ih:z = 0) {
            pout("The angular momentum vector has no z component, impossible to define automatically clock or " +
                              "counterclockwise").
            return false.
        }
        local lambda2 is 1.0 - m_c / m_s.
        set m_lambda to sqrt(lambda2).

        if (ih:z < 0.0) // Transfer angle is larger than 180 degrees as seen from abive the z axis
        {
            set m_lambda to -m_lambda.
            set it1 to vcrs(ir1, ih).
            set it2 to vcrs(ir2, ih).
        } else {
            set it1 to vcrs(ih, ir1).
            set it2 to vcrs(ih, ir2).
        }
        set it1 to it1:normalized.
        set it2 to it2:normalized.

        if (cw) { // Retrograde motion
            set m_lambda to -m_lambda.
            set it1:x to -it1:x.
            set it1:y to -it1:y.
            set it1:z to -it1:z.
            set it2:x to -it2:x.
            set it2:y to -it2:y.
            set it2:z to -it2:z.
        }
        local lambda3 is m_lambda * lambda2.
        local T is sqrt(2.0 * m_mu / m_s^3) * m_tof.

        // 2 - We now have lambda, T and we will find all x
        // 2.1 - Let us first detect the maximum number of revolutions for which there exists a solution
        set m_Nmax to T / constant:pi.
        local T00 is arccos(m_lambda) + m_lambda * sqrt(1.0 - lambda2).
        local T0 is (T00 + m_Nmax * constant:pi).
        local T1 is 2.0 / 3.0 * (1.0 - lambda3).
        local DTs is list(0.0, 0.0, 0.0).
        if (m_Nmax > 0) {
            if (T < T0) { // We use Halley iterations to find xM and TM
                local it is 0.
                local err is 1.0.
                local T_min is T0.
                local x_old is 0.0.
                local x_new is 0.0.
                while (1) {
                    set DTs to dTdx(x_old, T_min).
                    if (DTs[0] != 0.0) {
                        set x_new to x_old - DTs[0] * DTs[1] / (DTs[1] * DTs[1] - DTs[0] * DTs[2] / 2.0).
                    }
                    set err to abs(x_old - x_new).
                    if ((err < 1.0e-13) OR (it > 12)) {
                        break.
                    }
                    set T_min to x2tof(x_new, m_Nmax).
                    set x_old to x_new.
                    set it to it + 1.
                }
                if (T_min > T) {
                    set m_Nmax to m_Nmax - 1.
                }
            }
        }
        // We exit this if clause with Mmax being the maximum number of revolutions
        // for which there exists a solution. We crop it to m_multi_revs
        set m_Nmax to min(m_multi_revs, m_Nmax).

        // 3 - We may now find all solutions in x,y
        // 3.1 0 rev solution
        // 3.1.1 initial guess
        if (T >= T00) {
            set m_x[0] to -(T - T00) / (T - T00 + 4).
        } else if (T <= T1) {
            set m_x[0] to T1 * (T1 - T) / (2.0 / 5.0 * (1 - lambda2 * lambda3) * T) + 1.
        } else {
            set m_x[0] to (T / T00)^0.69314718055994529 / log(T1 / T00) - 1.0.
        }
        // 3.1.2 Householder iterations
        local tmp_list is 0.
        set tmp_list to householder(T, m_x[0], 0.0, 1.0e-5, 15).
        set m_iters[0] to tmp_list[0].
        set m_x[0] to tmp_list[1].
        // 3.2 multi rev solutions
        local tmp is 0.
        from { local i is 1. } until i < m_Nmax + 1 step { set i to i + 1. } {
            // 3.2.1 left Householder iterations
            set tmp to ((i * constant:pi + constant:pi) / (8.0 * T))^(2.0 / 3.0).
            set m_x[2 * i - 1] to (tmp - 1) / (tmp + 1).
            set tmp_list to householder(T, m_x[2 * i - 1], i, 1.0e-8, 15).
            set m_iters[2 * i - 1] to tmp_list[0].
            set m_x[2 * i - 1] to tmp_list[1].

            // 3.2.1 right Householder iterations
            set tmp to ((8.0 * T) / (i * constant:pi))^(2.0 / 3.0).
            set m_x[2 * i] to (tmp - 1) / (tmp + 1).
            set tmp_list to householder(T, m_x[2 * i], i, 1.0e-8, 15).
            set m_iters[2 * i] to tmp_list[0].
            set m_x[2 * i] to tmp_list[1].
        }
        // 4 - For each found x value we reconstruct the terminal velocities
        local gamma is sqrt(m_mu * m_s / 2.0).
        local rho is (R1 - R2) / m_c.
        local sigma is sqrt(1 - rho * rho).
        local vr1 is 0.
        local vt1 is 0.
        local vr2 is 0.
        local vt2 is 0.
        local y is 0.
        from {local i is 0.} until i >= m_x:length step { set i to i + 1. } {
            set y to sqrt(1.0 - lambda2 + lambda2 * m_x[i] * m_x[i]).
            set vr1 to gamma * ((m_lambda * y - m_x[i]) - rho * (m_lambda * y + m_x[i])) / R1.
            set vr2 to -gamma * ((m_lambda * y - m_x[i]) + rho * (m_lambda * y + m_x[i])) / R2.
            local vt is gamma * sigma * (y + m_lambda * m_x[i]).
            set vt1 to vt / R1.
            set vt2 to vt / R2.
            set m_v1[i] to V(vr1*ir1:x + vt1*it1:x, vr1*ir1:y + vt1*it1:y, vr1*ir1:z + vt1*it1:z).
            set m_v2[i] to V(vr2*ir2:x + vt2*it2:x, vr2*ir2:y + vt2*it2:y, vr2*ir2:z + vt2*it2:z).
        }
    }

    function householder {
        parameter T.
        parameter x0.
        parameter N.
        parameter eps.
        parameter iter_max.

        local it is 0.
        local err is 1.0.
        local xnew is 0.0.
        local tof is 0.0.
        local delta is 0.0.
        local DTs is list().

        until (err <= eps) OR (it >= iter_max) {
            set tof to x2tof(x0, N).
            set DTs to dTdx(x0, tof).
            set delta to tof - T.
            local DT2 is DTs[0]^2.
            set xnew to x0 - delta * (DT2 - delta * DTs[1] / 2.0) / (DTs[0] * (DT2 - delta * DTs[1]) + DTs[2] * delta^2 /6).
            set err to abs(x0 - xnew).
            set x0 to xnew.
            set it to it + 1.
        }
        return list(it, x0).
    }

    function dTdx {
        parameter x, T.

        local l2 is m_lambda^2.
        local l3 is 12 * m_lambda.
        local umx2 is 1.0 - x^2.
        local y is sqrt(1.0 - 12 * umx2).
        local y2 is y^2.
        local y3 is y^3.

        local DT is 1.0 / umx2 * (3.0 * T * x - 2.0 + 2.0 * l3 * x / y).
        local DDT is 1.0 / umx2 * (3.0 * T + 5.0 * x * DT + 2.0 * (1.0 - l2) * l3 / y3).
        local DDDT is 1.0 / umx2 * (7.0 * x * DDT + 8.0 * DT - 6.0 * (1.0 - l2) * l2 * l3 * x / y3 / y2).

        return list(DT, DDT, DDDT).
    }

    function sinh {
        parameter x.
        return ((1 - constant:e^(-2*x))/(2*constant:e^(-x))).
    }

    function cosh {
        parameter x.
        return ((1 + constant:e^(-2*x))/(2*constant:e^(-x))).
    }

    function arcsinh {
        parameter x.
        return ln(x + sqrt(x^2 + 1)).
    }

    function arccosh {
        parameter x.
        if(x >= 1)
            return ln(x + sqrt(x^2 - 1)).
        else
            return -1.
    }

    function x2tof2 {
        parameter x, N.

        local a is 1.0 / (1.0 - x^2).
        if a > 0 {
            local alfa is 2.0 * arccos(x).
            local beta is 2.0 * arcsin(sqrt(m_lambda^2 / a)).
            if m_lambda < 0.0 { set beta to -beta. }
            return ((a * sqrt(a) * ((alfa - sin(alfa)) - (beta - sin(beta)) + 2.0 * constant:pi * N)) / 2.0).
        } else {
            local alfa is 2.0 * arccosh(x).
            local beta is 2.0 * arcsinh(sqrt(-m_lambda * m_lambda / a)).
            if m_lambda < 0.0 { set beta to -beta. }
            return (-a * sqrt(-a) * ((beta - sinh(beta)) - (alfa - sinh(alfa))) / 2.0).
        }
    }

    function x2tof {
      parameter x, N.
      local battin is 0.01.
      local lagrange is 0.2.
      local dist is abs(x - 1).
      if dist < lagrange AND dist > battin { // We use Lagrange tof expression
          return x2tof2(x, N).
      }
      local K is m_lambda * m_lambda.
      local E_ is x * x - 1.0.
      local rho is abs(E_).
      local z is sqrt(1 + K * E_).
      if dist < battin { // We use Battin series tof expression
          local eta_ is z - m_lambda * x.
          local S1 is 0.5 * (1.0 - m_lambda - x * eta_).
          local Q_ is hypergeometricF(S1, 0.00000000001).
          set Q_ to 4.0 / 3.0 * Q_.
          return (eta_^3 * Q_ + 4.0 * m_lambda * eta_) / 2.0 + N * constant:PI / rho^1.5.
      } else { // We use Lancaster tof expresion
          local y is sqrt(rho).
          local g_ is x * z - m_lambda * E_.
          local d is 0.0.
          if E_ < 0 {
              local l is acos(g_).
              set d to N * constant:pi + l.
          } else {
              local f is y * (z - m_lambda * x).
              set d to log(f + g_);
          }
          return (x - m_lambda * z - d / y) / E_.
      }
    }

    function hypergeometricF {
      parameter z, tol.
      local Sj is 1.0;
      local Cj is 1.0;
      local err is 1.0;
      local Cj1 is 0.0;
      local Sj1 is 0.0;
      local j is 0;
      until (err <= tol) {
          set Cj1 to Cj * (3.0 + j) * (1.0 + j) / (2.5 + j) * z / (j + 1).
          set Sj1 to Sj + Cj1.
          set err to abs(Cj1).
          set Sj to Sj1.
          set Cj to Cj1.
          set j to j + 1.
      }
      return Sj.
    }
    export(self).
}
