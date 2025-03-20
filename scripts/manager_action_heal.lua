-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	ActionsManager.registerModHandler("heal", modHeal);
	ActionsManager.registerResultHandler("heal", onHeal);
end

function getRoll(rActor, sSkillName, nSkillMod, sSkillStat, nStatMod)
	local rRoll = {};
	rRoll.sType = "heal";
	rRoll.aDice = { "d6", "d6" };
	rRoll.nMod = nSkillMod or 0;
	rRoll.sSkillStat = sSkillStat
	rRoll.nSkillMod = nSkillMod
	rRoll.nStatMod = nStatMod
	rRoll.sDesc = "[HEAL] " .. StringManager.capitalizeAll(sSkillName);
	
	if rRoll.nMod ~= 0 then
        if rRoll.nMod > 0 then
            rRoll.sDesc = rRoll.sDesc .. " (" .. "2D+".. rRoll.nMod .. ")";
        else
            rRoll.sDesc = rRoll.sDesc .. " (" .. "2D".. rRoll.nMod .. ")";
        end
    else
        rRoll.sDesc = rRoll.sDesc .. " (" .. "2D)";
	end
	
	if sExtra then
		rRoll.sDesc = rRoll.sDesc .. " " .. sExtra;
	end

	-- -- Handle self-targeting
	-- if rAction.sTargeting == "self" then
	-- 	rRoll.bSelfTarget = true;
	-- end

	ActionsManager2.encodeAdvantage(rRoll);	

	return rRoll;
end

-- function getRoll(rActor, rAction)
-- 	local rRoll = {};
-- 	rRoll.sType = "heal";
-- 	rRoll.aDice = {};
-- 	rRoll.nMod = 0;
	
-- 	-- Build description
-- 	rRoll.sDesc = "[HEAL";
-- 	if rAction.order and rAction.order > 1 then
-- 		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
-- 	end
-- 	rRoll.sDesc = rRoll.sDesc .. "] " .. StringManager.capitalizeAll(rAction.label);

-- 	-- Save the heal clauses in the roll structure
-- 	rRoll.clauses = rAction.clauses;
	
-- 	-- Add the dice and modifiers, and encode ability scores used
-- 	for _,vClause in pairs(rRoll.clauses) do
-- 		for _,vDie in ipairs(vClause.dice) do
-- 			table.insert(rRoll.aDice, vDie);
-- 		end
-- 		rRoll.nMod = rRoll.nMod + vClause.modifier;
-- 		local sAbility = DataCommon.ability_ltos[vClause.stat];
-- 		if sAbility then
-- 			rRoll.sDesc = rRoll.sDesc .. string.format(" [MOD: %s (%s)]", sAbility, vClause.statmult or 1);
-- 		end
-- 	end
	
-- 	-- Encode the damage types
-- 	encodeHealClauses(rRoll);

-- 	-- Handle temporary hit points
-- 	if rAction.subtype == "temp" then
-- 		rRoll.sDesc = rRoll.sDesc .. " [TEMP]";
-- 	end

-- 	-- Handle self-targeting
-- 	if rAction.sTargeting == "self" then
-- 		rRoll.bSelfTarget = true;
-- 	end

-- 	return rRoll;
-- end

function performRoll(draginfo, rActor, sSkillName, nSkillMod, sSkillStat, nStatMod, bPSIRoll)
	local rRoll = getRoll(rActor, sSkillName, nSkillMod, sSkillStat, nStatMod, bPSIRoll);

	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modHeal(rSource, rTarget, rRoll)
	decodeHealClauses(rRoll);
	CombatManager2.addRightClickDiceToClauses(rRoll);
	
	local aAddDesc = {};
	local aAddDice = {};
	local nAddMod = 0;
	
	-- Track how many heal clauses before effects applied
	local nPreEffectClauses = #(rRoll.clauses);
	
	if rSource then
		local bEffects = false;

		-- -- Apply general heal modifiers
		-- local nEffectCount;
		-- aAddDice, nAddMod, nEffectCount = EffectManager5E.getEffectsBonus(rSource, {"HEAL"});
		-- if (nEffectCount > 0) then
		-- 	bEffects = true;
		-- end
		
		-- Apply ability modifiers
		-- for sAbility, sAbilityMult in rRoll.sDesc:gmatch("%[MOD: (%w+) %((%w+)%)%]") do
		-- 	local nBonusStat, nBonusEffects = ActorManagerTraveller.getAbilityEffectsBonus(rSource, DataCommon.ability_stol[sAbility]);
		-- 	if nBonusEffects > 0 then
		-- 		bEffects = true;
		-- 		local nMult = tonumber(sAbilityMult) or 1;
		-- 		if nBonusStat > 0 and nMult ~= 1 then
		-- 			nBonusStat = math.floor(nMult * nBonusStat);
		-- 		end
		-- 		nAddMod = nAddMod + nBonusStat;
		-- 	end
		-- end
		
		-- If effects happened, then add note
		-- if bEffects then
		-- 	local sMod = StringManager.convertDiceToString(aAddDice, nAddMod, true);
		-- 	table.insert(aAddDesc, EffectManager.buildEffectOutput(sMod));
		-- end
	end
	
	if #aAddDesc > 0 then
		rRoll.sDesc = rRoll.sDesc .. " " .. table.concat(aAddDesc, " ");
	end
	ActionsManager2.encodeDesktopMods(rRoll);
	for _,vDie in ipairs(aAddDice) do
		if vDie:sub(1,1) == "-" then
			table.insert(rRoll.aDice, "-p" .. vDie:sub(3));
		else
			table.insert(rRoll.aDice, "p" .. vDie:sub(2));
		end
	end
	rRoll.nMod = rRoll.nMod + nAddMod;

	-- Handle fixed damage option
	if not ActorManager.isPC(rSource) and OptionsManager.isOption("NPCD", "fixed") then
		local aFixedClauses = {};
		local aFixedDice = {};
		local nFixedPositiveCount = 0;
		local nFixedNegativeCount = 0;
		local nFixedMod = 0;

		for kClause,vClause in ipairs(rRoll.clauses) do
			if kClause <= nPreEffectClauses then
				local nClauseFixedMod = 0;
				for kDie,vDie in ipairs(vClause.dice) do
					if vDie:sub(1,1) == "-" then
						nFixedNegativeCount = nFixedNegativeCount + 1;
						nClauseFixedMod = nClauseFixedMod - math.floor(math.ceil(tonumber(vDie:sub(3)) or 0) / 2);
						if nFixedNegativeCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod - 1;
						end
					else
						nFixedPositiveCount = nFixedPositiveCount + 1;
						nClauseFixedMod = nClauseFixedMod + math.floor(math.ceil(tonumber(vDie:sub(2)) or 0) / 2);
						if nFixedPositiveCount % 2 == 0 then
							nClauseFixedMod = nClauseFixedMod + 1;
						end
					end
					vClause.dice = {};
					vClause.modifier = vClause.modifier + nClauseFixedMod;
				end
				nFixedMod = nFixedMod + nClauseFixedMod;
			else
				for kDie,vDie in ipairs(vClause.dice) do
					table.insert(aFixedDice, vDie);
				end
			end
			
			table.insert(aFixedClauses, vClause);
		end
		
		rRoll.clauses = aFixedClauses;
		rRoll.aDice = aFixedDice;
		rRoll.nMod = rRoll.nMod + nFixedMod;
	end
end

function onHeal(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = string.gsub(rMessage.text, " %[MOD:[^]]*%]", "");
	
	local nTotal = ActionsManager.total(rRoll);
	-- we can work out the heal efft here
	calculateHealEffect(rRoll, nTotal, rMessage)

	Comm.deliverChatMessage(rMessage);
	-- Get effect 
	
	ActionDamage.notifyApplyDamage(rSource, rTarget, rMessage.secret, rMessage.text, nTotal);
end

--
-- UTILITY FUNCTIONS
--

function calculateHealEffect(rRoll, nTotal, rMessage)
	local nTotal = ActionsManager.total(rRoll);
	
	local nEffect = nTotal - 8
	
	if nEffect >= 0 then
		if nEffect == 0 then
			rMessage.text = rMessage.text .. "\n[0 Healing]";
		else
			rMessage.text = rMessage.text .. "\n[" .. nEffect .. " Healing]";
		end
	else
		rMessage.text = rMessage.text .. "\n[No Healing]";	
	end
end

function decodeHealClauses(rRoll)
	-- Process each type clause in the damage description
	rRoll.clauses = {};
	for sDice, sStat, sStatMult in string.gmatch(rRoll.sDesc, "%[CLAUSE: %(([^)]*)%) %(([^)]*)%) %(([^)]*)%)]") do
		local rClause = {};
		rClause.dice, rClause.modifier = StringManager.convertStringToDice(sDice:lower());
		rClause.stat = sStat;
		rClause.statmult = tonumber(sStatMult) or 1;
		
		table.insert(rRoll.clauses, rClause);
	end
	
	-- Remove heal clause information from roll description
	rRoll.sDesc = string.gsub(rRoll.sDesc, " %[CLAUSE:[^]]*%]", "");
end
