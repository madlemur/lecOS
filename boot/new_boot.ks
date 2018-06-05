@LAZYGLOBAL OFF.
{
    LOCAL TIMES IS LEXICON().
    LOCAL L_F IS "". // Log File
    LOCAL IMT IS -1. // INIT_MET_TS
    LOCAL IM IS "". //INIT_MET
    LOCAL V_N IS LIST(). // Volume Names
    LOCAL s is stack().
    LOCAL d is lexicon().

    GLOBAL __ IS LEXICON(
        "padRep", pr@,
        "formatTS", ft@,
        "formatMET", fm@,
        "logOn", lo@,
        "doLog", dl@,
        "pOut", po@,
        "hudMsg", hm@,
        "setTime", st@,
        "diffTime", dt@,
        "stageTime", dt@:BIND("STAGE"),
        "doStage", ds@,
        "mAngle", ma@,
        "killWarp", kw@,
        "doWarp", dw@,
        "findPath", fp@,
        "loadScript", ls@,
        "delScript", des@,
        "runScript", rs@,
        "store", s_@,
        "append", a_@
    ).

    po("kOS BOOTLOADER v$$VER_NUM$$.$$REL_NUM$$.$$PAT_NUM$$ $$BLD_NUM$$").
    po("Property of Lemurian Exploratory Corps (LEC).").
    po("Unlicensed usage is forbidden and not covered by any insurance, anywhere.").
    po("Waiting for system stabilization...").
    WAIT 5.
    lv().
    ls("ops_loader.ks").
    rs("ops_loader.ks").


    // UI and I/O functions for consistient formatting and display
    FUNCTION pr
    {
      PARAMETER l, s, t.
      RETURN (""+t):PADLEFT(l):REPLACE(" ",s).
    }

    FUNCTION ft
    {
      PARAMETER u_time1, u_time2 IS TIME:SECONDS.
      LOCAL ts IS (TIME - TIME:SECONDS) + ABS(u_time1 - u_time2).
      RETURN "[T+" + pr(2,"0",ts:YEAR - 1) + " " + pr(3,"0",ts:DAY - 1) + " " + ts:CLOCK + "]".
    }

    FUNCTION fm
    {
      LOCAL m IS ROUND(MISSIONTIME).
      IF m > IMT {
        SET IMT TO m.
        SET IM TO ft(TIME:SECONDS - m).
      }
      RETURN IM.
    }

    FUNCTION lo
    {
      PARAMETER lf IS "0:/log/" + pr(0,"_",SHIP:NAME) + ".txt".
      SET L_F TO lf.
      dl(SHIP:NAME).
      IF lf <> "" { po("Log file: " + L_F). }
    }

    FUNCTION dl
    {
      PARAMETER t.
      IF L_F <> "" { LOG t TO L_F. }
    }

    FUNCTION po
    {
      PARAMETER t, wt IS TRUE.
      IF wt { SET t TO fm() + " " + t. }
      PRINT t.
      dl(t).
    }

    FUNCTION hm
    {
      PARAMETER t, c IS YELLOW, s IS 40.
      HUDTEXT(t, 3, 2, s, c, FALSE).
      po("HUD: " + t).
    }

    FUNCTION st
    {
      PARAMETER n, t IS TIME:SECONDS.
      SET TIMES[n] TO t.
    }

    FUNCTION dt
    {
      PARAMETER n.
      RETURN TIME:SECONDS - TIMES[n].
    }

    FUNCTION ds
    {
      po("Staging.").
      st("STAGE").
      STAGE.
    }

    FUNCTION ma
    {
      PARAMETER a.
      UNTIL a >= 0 { SET a TO a + 360. }
      RETURN MOD(a,360).
    }

    FUNCTION kw
    {
      KUNIVERSE:TIMEWARP:CANCELWARP().
      WAIT UNTIL SHIP:UNPACKED.
    }

    FUNCTION dw
    {
      PARAMETER wt, s_f IS { RETURN FALSE. }.
      po("Engaging time warp.").
      WARPTO(wt).
      WAIT UNTIL s_f() OR wt < TIME:SECONDS.
      kw().
      po("Time warp over.").
    }
    // Enumerate and manage kOS volumes
    FUNCTION sv
    {
      PARAMETER vnl.
      SET V_N TO vnl.
      pv().
    }

    FUNCTION lv
    {
      IF CORE:CURRENTVOLUME:NAME = "" { SET CORE:CURRENTVOLUME:NAME TO "Disk0". }
      LOCAL cvn IS CORE:CURRENTVOLUME:NAME.
      SET V_N TO LIST(cvn).

      LOCAL d_n IS 1.
      LOCAL pl IS LIST().
      LIST PROCESSORS IN pl.
      FOR p IN pl {
        LOCAL LOCK vn TO p:VOLUME:NAME.
        IF p:MODE = "READY" AND p:BOOTFILENAME = "None" AND vn <> cvn {
          IF vn = "" {
            SET p:VOLUME:NAME TO ("Disk" + d_n).
            SET d_n TO d_n + 1.
          }
          V_N:ADD(vn).
        }
      }
    }

    FUNCTION pv
    {
      FOR vn IN V_N { po("Volume(" + vn + ") has " + VOLUME(vn):FREESPACE + " bytes."). }
    }

    // Manage files and free space
    FUNCTION fp
    {
      PARAMETER fn.
      FOR vn IN V_N {
        LOCAL lfp IS vn + ":/" + fn.
        IF EXISTS(lfp) { RETURN lfp. }
      }
      RETURN "".
    }

    FUNCTION fs
    {
      PARAMETER fn, mfs.
      FOR vn IN V_N { IF VOLUME(vn):FREESPACE > mfs { RETURN vn + ":/" + fn. } }
      po("ERROR: no room!").
      pv().
      RETURN "".
    }

    FUNCTION ls
    {
      PARAMETER fn, loud IS TRUE, ko is TRUE.
      LOCAL lfp IS fp(fn).
      LOCAL afp IS "0:/" + fn.

      IF lfp <> "" {
          IF NOT ko and EXISTS(afp) {
              DELETEPATH(afp).
          }
          RETURN lfp.
      }

      IF HOMECONNECTION:ISCONNECTED AND EXISTS(afp) {
        LOCAL afs IS VOLUME(0):OPEN(fn):SIZE.
        SET lfp TO fs(fn, afs).
        IF lfp <> "" {
          IF loud { po("Copying from: " + afp + " (" + afs + " bytes)"). }
          COPYPATH(afp,lfp).
          IF loud { po("Copied to: " + lfp). }
          IF NOT ko { DELETEPATH(afp). }
          RETURN lfp.
        } ELSE {
          po("Insufficient space to copy " + afp + "(" + afs + " bytes)").
          RETURN "".
        }
      } ELSE {
        po("Unable to find " + afp).
        RETURN "".
      }
    }

    FUNCTION des
    {
      PARAMETER fn.
      LOCAL lfp IS fp(fn).
      IF lfp <> "" { DELETEPATH(lfp). }
    }

    FUNCTION s_
    {
      PARAMETER t, fn, mfs IS 150.
      des(fn).
      LOG t TO fs(fn,mfs).
    }

    FUNCTION a_
    {
      PARAMETER t, fn.
      LOG t TO fp(fn).
    }

    FUNCTION rs
    {
      PARAMETER fn.
      LOCAL lfp IS fp(fn).
      IF lfp <> "" { RUNPATH(lfp). }
    }

    // Library management, required by all LEC libraries
    global import is {
      parameter n.
      if d:haskey(n) {
          return d[n].
      }
      s:push(n).
      local p is ls(n).
      if p = "" {
          po("Unable to import " + n).
          s:pop().
          return "".
      }
      runpathonce(p).
      return d[n].
    }.

    global export is {
      parameter v.
      set d[s:pop()] to v.
    }.

    // Reference frame normalizers
    global chFrame is {
        parameter oldVec, oldSP, newSP is SolarPrimeVector.
        return vdot(oldVec, oldSP)*newSP + (oldVec:z * oldSP:x - oldVec:x * oldSP:z)*V(-newSP:z, 0, newSP:x) + V(0, oldVec:y, 0).
    }.

    global toIRF is {
      // changes to inertial right-handed coordinate system where ix = SPV, iy = vcrs(SPV, V(0, 1, 0)), iz = V(0, 1, 0)
      parameter oldVec, SPV is SolarPrimeVector.
      return V( oldVec:x * SPV:x + oldVec:z * SPV:z, oldVec:z * SPV:x - oldVec:x * SPV:z, oldVec:y).
    }.

    global fromIRF is {
      // changes from inertial right-handed coordinate system where ix = SPV, iy = vcrs(SPV, V(0, 1, 0)), iz = V(0, 1, 0)
      parameter irfVec, SPV is SolarPrimeVector.
      return V( irfVec:x * SPV:x - irfVec:y * SPV:z, irfVec:z, irfVec:x * SPV:z + irfVec:y * SPV:x ).
    }.
}
