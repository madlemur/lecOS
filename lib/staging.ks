@LAZYGLOBAL OFF.
pout("LEC STAGING v%VERSION_NUMBER%").
{
    local self is lexicon(
        "stagingCheck", stagingCheck@,
        "stageDeltaV", stageDeltaV@,
        "burnTimeForDv", burnTimeForDv@,
        "thrustToWeight", thrustToWeight@
    ).

    local engineModules is list("ModuleEngine", "ModuleEngineFX").
    local stagingConsumed is uniqueset("SolidFuel", "LiquidFuel", "Oxidizer", "Karbonite", "Monopropellant").

    // list of fuels for empty-tank identification (for dual-fuel tanks use only one of the fuels)
    // note: SolidFuel is in list for booster+tank combo, both need to be empty to stage
    local stagingTankFuels is uniqueset("SolidFuel", "LiquidFuel", "Karbonite", "Monopropellant"). //Oxidizer intentionally not included (would need extra logic)

    // list of modules that identify decoupler
    local stagingDecouplerModules is list("ModuleDecouple", "ModuleAnchoredDecoupler").
    // Standard gravity for ISP
    // https://en.wikipedia.org/wiki/Specific_impulse
    // https://en.wikipedia.org/wiki/Standard_gravity
    local isp_g0 is body:mu/body:radius^2. // exactly 9.81 in KSP 1.3.1, 9.80665 for Earth
    // note that constant:G*kerbin:mass/kerbin:radius^2 yields 9.80964723..., correct value could be 9.82

    // work variables for staging logic
    local stagingNumber 	is -1.		// stage:number when last calling stagingPrepare()
    local stagingMaxStage	is 0.		// stop staging if stage:number is lower or same as this
    local stagingResetMax	is true.	// reset stagingMaxStage to 0 if we passed it (search for next "noauto")
    local stagingEngines	is list().	// list of engines that all need to flameout to stage
    local stagingTanks		is list().	// list of tanks that all need to be empty to stage
    // info for and from stageDeltaV
    local stageAvgIsp		is 0.		// average ISP in seconds
    local stageStdIsp		is 0.		// average ISP in N*s/kg (stageAvgIsp*isp_g0)
    local stageDryMass		is 0.		// dry mass just before staging
    local stageBurnTime	    is 0.		// updated in stageDeltaV()

    function partIsDecoupler {
        parameter part.
        for m in stagingDecouplerModules if part:modules:contains(m) {
            if part:tag:matchesPattern("\bnoauto\b") and part:stage+1 >= stagingMaxStage
                set stagingMaxStage to part:stage+1.
            return true.
        }
        return false.
    }

    // return stage number where the part is decoupled (probably Part.separationIndex in KSP API)
    function stagingDecoupledIn {
    	parameter part.

    	until partIsDecoupler(part) {
    		if not part:hasParent return -1.
    		set part to part:parent.
    	}
    	return part:stage.
    }
    // to be called whenever current stage changes to prepare data for quicker test and other functions
    function stagingPrepare {
      local l_parts is 0.
      local l_engines is 0.
    	if not stage:READY
            return.
      local thisStageConsumes is UniqueSet().
    	set stagingNumber to stage:number.
    	if stagingResetMax and stagingMaxStage >= stagingNumber
    		set stagingMaxStage to 0.
    	stagingEngines:clear().
    	stagingTanks:clear().

    	// prepare list of tanks that are to be decoupled and have some fuel
    	list parts in l_parts.
    	for p in l_parts {
    		local amount is 0.
        local res is 0.
    		for res in p:resources {
          if stagingTankFuels:contains(res:name)
    			   set amount to amount + res:amount.
        }
        if amount > 0.01 and stagingDecoupledIn(p) = stage:number-1
           stagingTanks:add(p).
    	}

    	// prepare list of engines that are to be decoupled by staging
    	// and average ISP for stageDeltaV()
    	list engines in l_engines.
    	local thrust is 0.
        local flow is 0.
        local eng is 0.
    	for eng in l_engines if eng:ignition and eng:isp > 0
    	{
    		if stagingDecoupledIn(eng) = stage:number-1 {
    			stagingEngines:add(eng).
        }
    		local t is eng:availableThrust.
    		set thrust to thrust + t.
    		set flow to flow + t / eng:isp. // thrust=isp*g0*dm/dt => flow = sum of thrust/isp

    	}
    	set stageAvgIsp to 0.
        if flow > 0 set stageAvgIsp to thrust/flow.
    	set stageStdIsp to stageAvgIsp * isp_g0.

    	// prepare dry mass for stageDeltaV()
        local fuelMass is 0.
        for res in stage:resources {
          if stagingConsumed:contains(res:name)
    		    set fuelMass to fuelMass + res:amount*res:density.
        }
    	  set stageDryMass to ship:mass-fuelMass.
    }

    // to be called repeatedly
    function stagingCheck {
    	if (not stage:ready)
        or (stage:number <> stagingNumber and not stagingPrepare())
    	  or (stage:number <= stagingMaxStage)
    		return false.

    	// check staging conditions and return true if staged, false otherwise
    	if availableThrust < 0.001 or checkEngines() or checkTanks() {
    		return true.
    	}
    	return false.
    }
    // need to stage because all engines are without fuel?
    function checkEngines {
        if stagingEngines:empty return false.
        local eng is 0.
        for eng in stagingEngines if not eng:flameout
            return false.
        return true.
    }

    // need to stage because all tanks are empty?
    function checkTanks {
        if stagingTanks:empty return false.
        for t in stagingTanks {
            local amount is 0.
            local res is 0.
            for res in t:resources if stagingTankFuels:contains(res:name)
                set amount to amount + res:amount.
            if amount > 0.01 return false.
        }
        return true.
    }
    // delta-V remaining for current stage
    // + stageBurnTime updated with burn time at full throttle
    function stageDeltaV {
    	if stageAvgIsp < 0.01 or availableThrust < 0.01 or stageStdIsp < 0.01 {
    		set stageBurnTime to 0.
    		return 0.
    	}

    	set stageBurnTime to stageStdIsp*(ship:mass-stageDryMass)/availableThrust.
    	return stageStdIsp*ln(ship:mass / stageDryMass).
    }

    // calculate burn time for maneuver needing provided deltaV
    function burnTimeForDv {
    	parameter dv.
      if (availableThrust < 0.01 or stageStdIsp < 0.01) { return 2^32. }
    	return stageStdIsp*ship:mass*(1-constant:e^(-dv/stageStdIsp))/availableThrust.
    }

    // current thrust to weght ratio
    function thrustToWeight {
    	return availableThrust/(ship:mass*body:mu)*(body:radius+altitude)^2.
    }

    export(self).
}
