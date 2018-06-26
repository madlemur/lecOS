@LAZYGLOBAL OFF.
pout("LEC MANEUVER v%VERSION_NUMBER%").
{
    local self is lexicon(
        "stagingCheck", stagingCheck@
    ).

    local engineModules is list("ModuleEngine", "ModuleEngineFX").
    local stagingConsumed is uniqueset("SolidFuel", "LiquidFuel", "Oxidizer", "Karbonite").

    // list of fuels for empty-tank identification (for dual-fuel tanks use only one of the fuels)
    // note: SolidFuel is in list for booster+tank combo, both need to be empty to stage
    local stagingTankFuels is uniqueset("SolidFuel", "LiquidFuel", "Karbonite"). //Oxidizer intentionally not included (would need extra logic)

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

    	if not stage:READY
            return.
    	set stagingNumber to stage:number.
    	if stagingResetMax and stagingMaxStage >= stagingNumber
    		set stagingMaxStage to 0.
    	stagingEngines:clear().
    	stagingTanks:clear().

    	// prepare list of tanks that are to be decoupled and have some fuel
    	list parts in parts.
    	for p in parts {
    		local amount is 0.
    		for r in p:resources if stagingTankFuels:contains(r:name)
    			set amount to amount + r:amount.
    		if amount > 0.01 and stagingDecoupledIn(p) = stage:number-1
    			stagingTanks:add(p).
    	}

    	// prepare list of engines that are to be decoupled by staging
    	// and average ISP for stageDeltaV()
    	list engines in engines.
    	local thrust is 0.
        local flow is 0.
    	for e in engines if e:ignition and e:isp > 0
    	{
    		if stagingDecoupledIn(e) = stage:number-1
    			stagingEngines:add(e).

    		local t is e:availableThrust.
    		set thrust to thrust + t.
    		set flow to flow + t / e:isp. // thrust=isp*g0*dm/dt => flow = sum of thrust/isp
    	}
    	set stageAvgIsp to 0.
        if flow > 0 set stageAvgIsp to thrust/flow.
    	set stageStdIsp to stageAvgIsp * isp_g0.

    	// prepare dry mass for stageDeltaV()
        local fuelMass is 0.
        for r in stage:resources if stagingConsumed:contains(r:name)
    		set fuelMass to fuelMass + r:amount*r:density.
    	set stageDryMass to ship:mass-fuelMass.
    }

    // to be called repeatedly
    function stagingCheck {
    	if (not stage:ready)
        or (stage:number <> stagingNumber and not stagingPrepare())
    	or (stage:number <= stagingMaxStage)
    		return false.

    	// check staging conditions and return true if staged, false otherwise
    	if availableThrust = 0 or checkEngines() or checkTanks() {
    		return true.
    	}
    	return false.
    }
    // need to stage because all engines are without fuel?
    function checkEngines {
        if stagingEngines:empty return false.
        for e in stagingEngines if not e:flameout
            return false.
        return true.
    }

    // need to stage because all tanks are empty?
    function checkTanks {
        if stagingTanks:empty return false.
        for t in stagingTanks {
            local amount is 0.
            for r in t:resources if stagingTankFuels:contains(r:name)
                set amount to amount + r:amount.
            if amount > 0.01 return false.
        }
        return true.
    }

    export(self).
}
