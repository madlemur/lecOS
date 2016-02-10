function warp{

	PARAMETER duration.

	set SAFETY_MARGIN to 1.2.

	set start to TIME:SECONDS.
	set end to TIME:SECONDS + duration.
	lock remaining to end - TIME:SECONDS.

	print " ".
	print "Warping for " + duration + "s.".

	set WARPMODE to "RAILS".

	//
	// MODE:                MEANING:                MINIMUM DURATION:
	// 0                    1x                              -
	// 1                    5x                              10s
	// 2                    10x                             20s
	// 3                    50x                             100s
	// 4                    100x                    200s
	// 5                    1,000x                  2,000s
	// 6                    10,000x                 20,000s
	// 7                    100,000x                200,000s
	//

	set MINIMUM to list(0, 10, 100, 1000, 10000, 100000, 1000000, 6000000).
	set MULTIPLICATOR to list(1, 10, 100, 1000, 10000, 100000, 1000000, 6000000).

	set done to 0.
	until (remaining <= 3 or done = 1) {

			print "Remaining: " + Round(remaining) + "s".

			// Determine which warp speed to use.
			set warpLevel to 0.
			until warpLevel >= MINIMUM:Length - 1 or SAFETY_MARGIN * MULTIPLICATOR[warpLevel + 1] > remaining {
					set warpLevel to warpLevel + 1.
			}
			print "Using " + MULTIPLICATOR[warpLevel] + "x acceleration...".

			// Initiate time warp.
			set margin to SAFETY_MARGIN * MULTIPLICATOR[warpLevel].


			set WARP to warpLevel.

			until (remaining < margin) {
					wait 0.01.
			}
	}

	set WARP to 0.

	print "Finished warping. Waiting for remaining " + ROUND(remaining,1) + "s...".
	wait remaining.
	print "Done.".
}
