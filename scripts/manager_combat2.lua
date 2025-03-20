--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

function onInit()
	CombatManager.setCustomSort(CombatManager.sortfuncDnD);

	CombatManager.setCustomRoundStart(onRoundStart);
	CombatManager.setCustomTurnStart(onTurnStart);
	CombatManager.setCustomCombatReset(resetInit);

	if Session.IsHost then
		CombatRecordManager.setRecordTypePostAddCallback("npc", onNPCPostAdd);
	end
end

--
-- TURN FUNCTIONS
--

function onTurnStart(nodeEntry)
	if not nodeEntry then
		return;
	end

	local rTarget = ActorManager.resolveActor(nodeEntry);
	local bHasEffect = false;
	local sDamageType;

	-- Need to find out if they have any effects
	if EffectManagerTraveller.hasEffect(rTarget, "Fire") then
		sDamageType = "fire";
		bHasEffect = true;
		-- Get damage dice for this effect
		aDamageDetails = EffectManagerTraveller.getDamageDetails(rTarget, "Fire");
	end

	-- Do we have an effect?
	if bHasEffect then
		local rAction = {};
		local sDamage;
		rAction.label = "Ongoing damage";
		rAction.clauses = {};
		rAction.sTraits = '';
		rAction.range = 'O';

		local aClause = {};

		aClause.dice = aDamageDetails.dice;
		aClause.modifier = aDamageDetails.mod;
		aClause.dmgtype = aDamageDetails.type;
		aClause.sDamage = aDamageDetails.sDamage;

		table.insert(rAction.clauses, aClause);

		local rRoll = ActionDamage.getRoll(rTarget, rAction);
		if EffectManager.isGMEffect(nodeActor, nodeEffect) then
			rRoll.bSecret = true;
		end
		-- rRoll.bIgnoreArmour = true;

		ActionsManager.actionDirect(nil, "damage", { rRoll }, { { rTarget } });
	end
end

--
-- ROUND FUNCTIONS
--

function onRoundStart(nCurrent)
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(v, "init_mod", "number", 0);
	end
end

--
-- ADD FUNCTIONS
--

function onNPCPostAdd(tCustom)
	local sNPCType = DB.getValue(tCustom.nodeCT, 'type', 'humanoid'):lower();
	if sNPCType == "animal" or sNPCType == "robot" or sNPCType == "drone" then
		-- Nothing to do - at the moment
		DB.setValue(tCustom.nodeCT, "woundtrack.hits", "number", DB.getValue(tCustom.nodeCT, "hits", 0));
	else
		DB.setValue(tCustom.nodeCT, 'woundtrack.dex', 'number', DB.getValue(tCustom.nodeCT, 'attributes.dexterity', 0));
		DB.setValue(tCustom.nodeCT, 'woundtrack.str', 'number', DB.getValue(tCustom.nodeCT, 'attributes.strength', 0));
		DB.setValue(tCustom.nodeCT, 'woundtrack.end', 'number', DB.getValue(tCustom.nodeCT, 'attributes.endurance', 0));
	end
end

--
-- RESET FUNCTIONS
--

function resetInit()
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(v, "initresult", "number", 0);
		DB.setValue(v, "initresult_saved", "number", 0);
		DB.setValue(v, "init_mod", "number", 0);
	end
end

function rollRandomInit(nInitDM, nInitBonus)
	if not nInitBonus then
		nInitBonus = 0;
	end

	local nInitResult = 0;

	for i=1,2 do
		nInitResult = nInitResult + math.random(6);
	end
	-- Now get effect for this roll
	local nEffect = (nInitResult + nInitDM + nInitBonus) -8

	nInitResult = nEffect;

	return nInitResult;
end

function rollEntryInit(nodeEntry)
	if not nodeEntry then
		return;
	end

	-- Start with the base initiative bonus
	local nInit = DB.getValue(nodeEntry, "init", 0);
	local nInitMod = 0;

	-- Get any effect modifiers
	local rActor = ActorManager.resolveActor(nodeEntry);

	-- For PCs, we always roll unique initiative
	local sClass, sRecord = DB.getValue(nodeEntry, "link", "", "");
	if sClass == "charsheet" then

		local _,sCharLink = DB.getValue(nodeEntry, "link", "");
		local nInitBonus = DB.getValue(DB.findNode(sCharLink), "initiative", 0);

		local nDexDM = DB.getValue(nodeEntry, "attributes.dex_mod", 0);
		local nIntDM = DB.getValue(nodeEntry, "attributes.int_mod", 0);

		local nInitMod = nDexDM;
		if nIntDM > nInitMod then
			nInitMod = nIntDM;
		end
		local nInitResult = rollRandomInit(nInitMod, nInitBonus);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		DB.setValue(nodeEntry, "initresult_saved", "number", nInitResult - nInitMod);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
		return;
	end

	-- For NPCs, if NPC init option is not group, then roll unique initiative
	local sOptINIT = OptionsManager.getOption("INIT");
	if sOptINIT ~= "group" then

		local sType = DB.getValue(nodeEntry, "type", "unknown");
		nInitMod = getInitMod(nodeEntry, sType);

		local nInitResult = rollRandomInit(nInitMod);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		DB.setValue(nodeEntry, "initresult_saved", "number", nInitResult - nInitMod);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
		return;
	end

	-- For NPCs with group option enabled

	-- Get the entry's database node name and creature name
	local sStripName = CombatManager.stripCreatureNumber(DB.getValue(nodeEntry, "name", ""));
	if sStripName == "" then

		local sType = DB.getValue(nodeEntry, "type", "unknown");

		nInitMod = getInitMod(nodeEntry, sType);

		local nInitResult = rollRandomInit(nInitMod);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		DB.setValue(nodeEntry, "initresult_saved", "number", nInitResult - nInitMod);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
		return;
	end

	-- Iterate through list looking for other creature's with same name
	local nLastInit = nil;
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		if DB.getName(v) ~= DB.getName(nodeEntry) then
			local sTemp = CombatManager.stripCreatureNumber(DB.getValue(v, "name", ""));
			if sTemp == sStripName then
				local nChildInit = DB.getValue(v, "initresult", 0);
				if nChildInit ~= -10000 then
					nLastInit = nChildInit;
				end
			end
		end
	end

	-- If we found similar creatures, then match the initiative of the last one found
	if nLastInit then
		DB.setValue(nodeEntry, "initresult", "number", nLastInit);
		DB.setValue(nodeEntry, "initsaved", "number", nLastInit);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
	else
		local sType = DB.getValue(nodeEntry, "type", "unknown");

		nInitMod = getInitMod(nodeEntry, sType);

		local nInitResult = rollRandomInit(nInitMod);
		DB.setValue(nodeEntry, "initresult", "number", nInitResult);
		DB.setValue(nodeEntry, "initresult_saved", "number", nInitResult - nInitMod);
		DB.setValue(nodeEntry, "init_mod", "number", 0);
	end
end

function rollInit(sType)
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local bRoll = true;
		if sType then
			local sClass,_ = DB.getValue(v, "link", "", "");
			if sType == "npc" and sClass == "charsheet" then
				bRoll = false;
			elseif sType == "pc" and sClass ~= "charsheet" then
				bRoll = false;
			end
		end

		if bRoll then
			DB.setValue(v, "initresult", "number", -10000);
			DB.setValue(v, "initresult_saved", "number", -10000);
			DB.setValue(v, "init_mod", "number", 0);
		end
	end

	for _,v in pairs(CombatManager.getCombatantNodes()) do
		local bRoll = true;
		if sType then
			local sClass,_ = DB.getValue(v, "link", "", "");
			if sType == "npc" and sClass == "charsheet" then
				bRoll = false;
			elseif sType == "pc" and sClass ~= "charsheet" then
				bRoll = false;
			end
		end

		if bRoll then
			rollEntryInit(v);
		end
	end
end

function getInitMod(nodeEntry, sType)
	local nInitMod = 0;

	if sType == "Humanoid" then
		local nDexDM = DB.getValue(nodeEntry, "attributes.dex_mod", 0);
		local nIntDM = DB.getValue(nodeEntry, "attributes.int_mod", 0);
		local nInitMod = nDexDM;
		if nIntDM > nInitMod then
			nInitMod = nIntDM;
		end
	else
		nInitMod = 0;

		local sTraits = DB.getValue(nodeEntry, "traits", "fred");
		local aTraits = StringManager.split(sTraits, ",", true);

		for i = 1, #aTraits do

			sTrait = aTraits[i]:lower();

			if string.find(sTrait, "metabolism%s*(.%d*)") then
				nInitMod = tonumber(string.match(sTrait, "([%+%-]?%d+)/?"));
			end
		end

	end

	return nInitMod;
end

--
--	COMBAT ACTION FUNCTIONS
--

function addRightClickDiceToClauses(rRoll)
	if #rRoll.clauses > 0 then
		local nOrigDamageDice = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nOrigDamageDice = nOrigDamageDice + #vClause.dice;
		end
		if #rRoll.aDice > nOrigDamageDice then
			local v = rRoll.clauses[#rRoll.clauses].dice;
			for i = nOrigDamageDice + 1,#rRoll.aDice do
				table.insert(rRoll.clauses[1].dice, rRoll.aDice[i]);
			end
		end
	end
end
