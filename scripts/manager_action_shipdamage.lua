--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

OOB_MSGTYPE_APPLYSHIPDMG = "applyshipdmg";
OOB_MSGTYPE_APPLYSHIPDMGSTATE = "applyshipdmgstate";

function onInit()
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSHIPDMG, handleApplyDamage);
	OOBManager.registerOOBMsgHandler(OOB_MSGTYPE_APPLYSHIPDMGSTATE, handleApplyDamageState);

	ActionsManager.registerModHandler("shipdamage", modDamage);
	ActionsManager.registerResultHandler("shipdamage", onDamage);
	ActionsManager.registerTargetingHandler("shipdamage", onTargeting);
end

function handleApplyDamage(msgOOB)
	local rSource = ActorManager.resolveActor(msgOOB.sSourceNode);
	local rTarget = ActorManager.resolveActor(msgOOB.sTargetNode);
	if rTarget then
		rTarget.nOrder = msgOOB.nTargetOrder;
	end

	local nTotal = tonumber(msgOOB.nTotal) or 0;
	applyPendingDamage(rSource, rTarget, (tonumber(msgOOB.nSecret) == 1), msgOOB.sDamage, nTotal);
end

function notifyApplyDamage(rSource, rTarget, bSecret, sDesc, nTotal, rRoll)
	if not rTarget then
		return;
	end

	local msgOOB = {};
	msgOOB.type = OOB_MSGTYPE_APPLYSHIPDMG;

	if bSecret then
		msgOOB.nSecret = 1;
	else
		msgOOB.nSecret = 0;
	end
	msgOOB.nTotal = nTotal;
	msgOOB.sDamage = sDesc;
	msgOOB.sTargetType = sTargetType;
	msgOOB.sTargetNode = sTargetNode;
	msgOOB.nTargetOrder = rTarget.nOrder;

	msgOOB.sSourceNode = ActorManager.getCreatureNodeName(rSource);
	msgOOB.sTargetNode = ActorManager.getCreatureNodeName(rTarget);

	Comm.deliverOOBMessage(msgOOB, "");
end

function getRoll(rActor, rAction)
	local rRoll = {};
	rRoll.sType = "shipdamage";
	rRoll.aDice = {};
	rRoll.nMod = rAction.nMod;

	rRoll.sDesc = "[SHIP DAMAGE";
	if rAction.order and rAction.order > 1 then
		rRoll.sDesc = rRoll.sDesc .. " #" .. rAction.order;
	end
	rRoll.sDesc = rRoll.sDesc .. "] " .. StringManager.capitalizeAll(rAction.label);

	-- Save the damage properties in the roll structure
	rRoll.clauses = rAction.clauses;

	local bDestructiveDamage = false;

	-- Add the dice and modifiers
	for _,vClause in ipairs(rRoll.clauses) do
		for _,vDie in ipairs(vClause.dice) do
			table.insert(rRoll.aDice, vDie);
		end
		rRoll.nMulti = vClause.nMulti;
		rRoll.nMod = rRoll.nMod + vClause.modifier;
		if string.match(vClause.sDamage:upper(), "DD") then
			bDestructiveDamage = true;
		end
	end

	if bDestructiveDamage == true then
		rRoll.bDestructive = true;
		rRoll.sDesc = rRoll.sDesc .. " [DESTRUCTIVE]";
		nDamageModifier = 0;  -- no effect damage can be added
	else
		rRoll.bDestructive = false;
	end

	-- Any additional desktop damage
	if rRoll.nMod ~= 0 and rRoll.nMod ~= nil then
		if rRoll.nMod < 0 then
			rRoll.sDesc = rRoll.sDesc .. " [".. rRoll.nMod .. " DMG]";
		else
			rRoll.sDesc = rRoll.sDesc .. " [+".. rRoll.nMod .. " DMG]";
		end
	end

	-- Check for Traits
	local tTraitAddDesc = {};
	local nAttackDice = #rRoll.aDice;
	local sDescLower = rRoll.sDesc:lower();
	local sTraitsLower = (rAction.sTraits or ""):lower();
	if sDescLower:find("sandcaster") then
		if sTraitsLower:find("quad turret") then
			table.insert(tTraitAddDesc, " [QUAD TURRET +3]");
			rRoll.nMod = rRoll.nMod + 3;
		end
		if sTraitsLower:find("triple turret") then
			table.insert(tTraitAddDesc, " [TRIPLE TURRET +2]");
			rRoll.nMod = rRoll.nMod + 2;
		end
		if sTraitsLower:find("double turret") then
			table.insert(tTraitAddDesc, " [DOUBLE TURRET +1]");
			rRoll.nMod = rRoll.nMod + 1;
		end
	elseif not sDescLower:find("missile") then
		if sTraitsLower:find("quad turret") then
			table.insert(tTraitAddDesc, " [QUAD TURRET +" .. (nAttackDice * 3) .. "]");
			rRoll.nMod = rRoll.nMod + (nAttackDice * 3);
		end
		if sTraitsLower:find("triple turret") then
			table.insert(tTraitAddDesc, " [TRIPLE TURRET +" .. (nAttackDice * 2) .. "]");
			rRoll.nMod = rRoll.nMod + (nAttackDice * 2);
		end
		if sTraitsLower:find("double turret") then
			table.insert(tTraitAddDesc, " [DOUBLE TURRET +" .. nAttackDice .. "]");
			rRoll.nMod = rRoll.nMod + nAttackDice;
		end
	end
	if sTraitsLower:find("very high yield") then
		table.insert(tTraitAddDesc, "[VERY HIGH YIELD]");
	elseif sTraitsLower:find("high yield") then
		table.insert(tTraitAddDesc, "[HIGH YIELD]");
	end
	if #tTraitAddDesc > 0 then
		rRoll.sDesc = string.format("%s %s", rRoll.sDesc, table.concat(tTraitAddDesc, " "));
	end

	-- Encode the damage types
	encodeDamageTypes(rRoll);

	return rRoll;
end

function performRoll(draginfo, rActor, rAction)
	local rRoll = getRoll(rActor, rAction);
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function modDamage(rSource, rTarget, rRoll)
	decodeDamageTypes(rRoll);

	-- Set up
	local tAddDesc = {};
	local _,nEffectModifier = ActionShipAttack.isCrit(rSource);
	if nEffectModifier and nEffectModifier > 0 then
		table.insert(tAddDesc, string.format("[%+d DMG]", nEffectModifier));
		rRoll.nMod = rRoll.nMod + nEffectModifier
	end
	if #tAddDesc > 0 then
		rRoll.sDesc = string.format("%s %s", rRoll.sDesc, table.concat(tAddDesc, " "));
	end

	ActionsManager2.encodeDesktopMods(rRoll, true);
end

function onDamage(rSource, rTarget, rRoll)
	decodeDamageTypes(rRoll, true);

	-- Do we have a critical hit?
	-- But did we do any damage....
	local isCritHit, nExtraDamage = ActionShipAttack.isCrit(rSource, true);

	-- Handle max damage or other types of special damage
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	rMessage.text = rMessage.text:gsub(" %[MOD:[^]]*%]", "");

	-- Check traits
	local bHighYield = false;
	local bVeryHighYield = false;
	if rRoll.sDesc:match("%[VERY HIGH YIELD%]") then
		bVeryHighYield = true;
	elseif rRoll.sDesc:match("%[HIGH YIELD%]") then
		bHighYield = true;
	end

	if bVeryHighYield or bHighYield then
		for _,v in ipairs(rRoll.aDice) do
			if bVeryHighYield and (v.result == 1 or v.result == 2) then
				v.type = "b6"
				v.value = 3;
				v.result = 3;
			elseif bHighYield and v.result == 1 then
				v.type = "b6"
				v.value = 2;
				v.result = 2;
			end
		end
	end

	if isCritHit and nExtraDamage >= 6 then -- We hold the extra damage as a critical, so need to only apply if it's 6 or more
		rMessage.text = rMessage.text .. " [CRITICAL]"
	end

	-- Apply damage to the PC or CT entry referenced
	local nTotal = ActionsManager.total(rRoll);
	local nFinalTotal;
	if tonumber(rRoll.nMulti) == 0 or rRoll.nMulti == nil then
		nFinalTotal = nTotal;
	elseif tonumber(rRoll.nMulti) > 0 then
		nFinalTotal = nTotal * tonumber(rRoll.nMulti);
		rMessage.text = rMessage.text .. "[MULTI " .. rRoll.nMulti .. "]"
	end

	-- Send the chat message
	local bShowMsg = true;
	if rTarget and rTarget.nOrder and rTarget.nOrder ~= 1 then
		bShowMsg = false;
	end
	if bShowMsg then
		Comm.deliverChatMessage(rMessage);
	end

	notifyApplyDamage(rSource, rTarget, rRoll.bTower, rMessage.text, nFinalTotal, rRoll);
end

function applyPendingDamage(rSource, rTarget, bSecret, sDamage, nTotal)
	-- Adding pendingattack damage
	if rTarget then
		local nodeTarget = ActorManager.getCTNode(rTarget);
		local nodePendingResult = DB.createChild(DB.createChild(nodeTarget, "pendingattacks"))

		local sWeapon = sDamage:match("%[%a+%s%a+%]%s+(.*)%s%[.*%]");
		if sWeapon and sWeapon:match("(.*)%s(%[.*%])") then
			sWeapon = sWeapon:match("(.*)%s(%[.*%])");
		end
		if sDamage:match("%[CRITICAL%]") then
			sWeapon = sWeapon .. " [CRITICAL]"
		end

		local sDamageType = StringManager.trim(sDamage:match("%[TYPE:(.*)%s.*%]"));

		if rSource then
			DB.setValue(nodePendingResult, "attackdescription", "string", rSource.sName .. ": " .. sWeapon);
		else
			DB.setValue(nodePendingResult, "attackdescription", "string", sWeapon);
		end

		DB.setValue(nodePendingResult, "damage", "number", nTotal);
		DB.setValue(nodePendingResult, "damagetype", "string", sDamageType);
	end
end

--
-- UTILITY FUNCTIONS
--

function encodeDamageTypes(rRoll)
	for _,vClause in ipairs(rRoll.clauses) do
		if vClause.dmgtype and vClause.dmgtype ~= "" then
			local sDice = StringManager.convertDiceToString(vClause.dice, vClause.modifier);
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s)]", vClause.dmgtype, sDice);
		end
	end
end

function decodeDamageTypes(rRoll, bFinal)
	-- Process each type clause in the damage description (INITIAL ROLL)
	local nMainDieIndex = 0;

	if rRoll.sDesc:find('%[DESTRUCTIVE%]') then
		rRoll.bDestructive = true;
	end

	rRoll.clauses = {};
	for sDamageType, sDamageDice in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([^)]*)%)%]") do
		local rClause = {};
		rClause.dmgtype = StringManager.trim(sDamageType);
		rClause.dice, rClause.modifier = StringManager.convertStringToDice(sDamageDice:lower());
		rClause.nTotal = rClause.modifier;

		for kDie,vDie in ipairs(rClause.dice) do
			nMainDieIndex = nMainDieIndex + 1;
			if rRoll.aDice[nMainDieIndex] then

				if rRoll.aDice[nMainDieIndex].result and (rRoll.bDestructive == true or rRoll.bDestructive == "true") then
					rRoll.aDice[nMainDieIndex].result = rRoll.aDice[nMainDieIndex].result * 10;
				end
				rClause.nTotal = rClause.nTotal + (rRoll.aDice[nMainDieIndex].result or 0);
			end
		end

		table.insert(rRoll.clauses, rClause);
	end

	-- Process each type clause in the damage description (DRAG ROLL RESULT)
	local nClauses = #(rRoll.clauses);
	for sDamageType, sDamageDice in string.gmatch(rRoll.sDesc, "%[TYPE: ([^(]*) %(([^)]*)%)]") do
		local sTotal = string.match(sDamageDice, "=(%d+)");
		if sTotal then
			local nTotal = tonumber(sTotal) or 0;

			local rClause = {};
			rClause.dmgtype = StringManager.trim(sDamageType);
			rClause.stat = "";
			rClause.dice = {};
			rClause.modifier = nTotal;
			rClause.nTotal = nTotal;

			table.insert(rRoll.clauses, rClause);
		end
	end

	if #(rRoll.clauses) == 0 then
		local rClause = {};
		rClause.dmgtype = "";
		rClause.stat = "";
		rClause.dice = {};
		rClause.modifier = rRoll.nMod;
		rClause.nTotal = rRoll.nMod;
		for _,vDie in ipairs(rRoll.aDice) do
			if type(vDie) == "table" then
				table.insert(rClause.dice, vDie.type);
				rClause.nTotal = rClause.nTotal + (vDie.result or 0);
			else
				table.insert(rClause.dice, vDie);
			end
		end

		table.insert(rRoll.clauses, rClause);
	end

	-- Handle drag results that are halved or doubled
	-- if #(rRoll.aDice) == 0 then
	-- 	local nResultTotal = 0;
	-- 	for i = nClauses + 1, #(rRoll.clauses) do
	-- 		nResultTotal = rRoll.clauses[i].nTotal;
	-- 	end
	-- 	if nResultTotal > 0 and nResultTotal ~= rRoll.nMod then
	-- 		if math.floor(nResultTotal / 2) == rRoll.nMod then
	-- 			for _,vClause in ipairs(rRoll.clauses) do
	-- 				vClause.modifier = math.floor(vClause.modifier / 2);
	-- 				vClause.nTotal = math.floor(vClause.nTotal / 2);
	-- 			end
	-- 		elseif nResultTotal * 2 == rRoll.nMod then
	-- 			for _,vClause in ipairs(rRoll.clauses) do
	-- 				vClause.modifier = 2 * vClause.modifier;
	-- 				vClause.nTotal = 2 * vClause.nTotal;
	-- 			end
	-- 		end
	-- 	end
	-- end

	if bFinal then
		-- Remove damage type information from roll description
		rRoll.sDesc = string.gsub(rRoll.sDesc, " %[TYPE:[^]]*%]", "");
		local nFinalTotal = ActionsManager.total(rRoll);

		-- Handle minimum damage
		if nFinalTotal < 0 and rRoll.aDice and #rRoll.aDice > 0 then
			-- rRoll.sDesc = rRoll.sDesc .. " [MIN DAMAGE 1]";
			rRoll.nMod = rRoll.nMod - nFinalTotal;
			nFinalTotal = 0;
		end

		-- Capture any manual modifiers and adjust damage types accordingly
		-- NOTE: Positive values are added to first damage clause, Negative values reduce damage clauses until none remain
		local nClausesTotal = 0;
		for _,vClause in ipairs(rRoll.clauses) do
			nClausesTotal = nClausesTotal + vClause.nTotal;
		end
		if nFinalTotal ~= nClausesTotal then
			local nRemainder = nFinalTotal - nClausesTotal;
			if nRemainder > 0 then
				if #(rRoll.clauses) == 0 then
					table.insert(rRoll.clauses, { dmgtype = "", stat = "", dice = {}, modifier = nRemainder, nTotal = nRemainder})
				else
					rRoll.clauses[1].modifier = rRoll.clauses[1].modifier + nRemainder;
					rRoll.clauses[1].nTotal = rRoll.clauses[1].nTotal + nRemainder;
				end
			else
				for _,vClause in ipairs(rRoll.clauses) do
					if vClause.nTotal >= -nRemainder then
						vClause.modifier = vClause.modifier + nRemainder;
						vClause.nTotal = vClause.nTotal + nRemainder;
						break;
					else
						vClause.modifier = vClause.modifier - vClause.nTotal;
						nRemainder = nRemainder + vClause.nTotal;
						vClause.nTotal = 0;
					end
				end
			end
		end

		-- Collapse damage clauses into smallest set, then add to roll description as text
		local aDamage = getDamageStrings(rRoll.clauses);
		for _, rDamage in ipairs(aDamage) do
			local sDice = StringManager.convertDiceToString(rDamage.aDice, rDamage.nMod);
			local sDmgTypeOutput = rDamage.sType:lower();
			if sDmgTypeOutput == "" then
				sDmgTypeOutput = "laser";
			end
			rRoll.sDesc = rRoll.sDesc .. string.format(" [TYPE: %s (%s=%d)]", sDmgTypeOutput, sDice, rDamage.nTotal);
		end
	end
end

-- Collapse damage clauses by damage type (in the original order, if possible)
function getDamageStrings(clauses)
	local aOrderedTypes = {};
	local aDmgTypes = {};
	for _,vClause in ipairs(clauses) do
		local rDmgType = aDmgTypes[vClause.dmgtype];
		if not rDmgType then
			rDmgType = {};
			rDmgType.aDice = {};
			rDmgType.nMod = 0;
			rDmgType.nTotal = 0;
			rDmgType.sType = vClause.dmgtype;
			aDmgTypes[vClause.dmgtype] = rDmgType;
			table.insert(aOrderedTypes, rDmgType);
		end

		for _,vDie in ipairs(vClause.dice) do
			table.insert(rDmgType.aDice, vDie);
		end
		rDmgType.nMod = rDmgType.nMod + vClause.modifier;
		rDmgType.nTotal = rDmgType.nTotal + (vClause.nTotal or 0);
	end

	return aOrderedTypes;
end

function getDamageTypesFromString(sDamageTypes)
	local sLower = string.lower(sDamageTypes);
	local aSplit = StringManager.split(sLower, ",", true);

	local aDamageTypes = {};
	for _,v in ipairs(aSplit) do
		if StringManager.contains(DataCommon.shipdmgtypes, v) then
			table.insert(aDamageTypes, v);
		end
	end

	return aDamageTypes;
end

function onTargeting(rSource, aTargeting, rRolls)
	if #aTargeting == 0 or (#aTargeting == 1 and #aTargeting[1] == 0) then
		return TargetingManager.getFullTargets(rSource);
	end
	return aTargeting;
end